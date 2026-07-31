package net.lab1024.sa.admin.module.business.score.manager;

import lombok.extern.slf4j.Slf4j;
import net.lab1024.sa.admin.module.business.score.domain.vo.ScoreAiFeedbackVO;
import net.lab1024.sa.admin.module.business.score.domain.vo.ScoreQuestionVO;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

/**
 * AI 评分数据管理器
 *
 * <h3>两种工作模式</h3>
 * <ul>
 *   <li><b>Mock 模式（当前）</b>：本类中的方法返回模拟数据，用于前端联调和开发测试。</li>
 *   <li><b>Python AI 模式（生产）</b>：由外部 Python AI 服务通过以下接口接管：
 *     <ul>
 *       <li>{@code POST /api/external/ai/pending-answers} — 拉取待批改答案</li>
 *       <li>{@code POST /api/external/ai/submit-grade} — 提交单题评分（含三维度）</li>
 *       <li>{@code POST /api/external/ai/submit-feedback} — 提交整体学习建议</li>
 *     </ul>
 *     Python 提交的评分数据以 JSON 格式存储在 t_answer_detail.grade_remark 字段中，
 *     本类在读取时会自动解析 JSON，优先使用 Python AI 的真实数据，解析失败时回退到 Mock。
 *   </li>
 * </ul>
 *
 * <h3>切换方式</h3>
 * 无需修改代码。Python AI 通过外部接口写入真实评分数据后，
 * 前端查询时 {@link net.lab1024.sa.admin.module.business.score.service.ScoreQueryService}
 * 会优先读取数据库中的真实评分。没有真实评分时，本类的 Mock 方法作为兜底。
 *
 * <h3>数据存储格式</h3>
 * Python 提交的 grade_remark 为 JSON：
 * <pre>{@code
 * {
 *   "remark": "评分理由（30-80字）",
 *   "relevance": { "score": 4.5, "comment": "相关性评语" },
 *   "coverage":  { "score": 4.0, "comment": "覆盖度评语" },
 *   "logic":     { "score": 3.5, "comment": "逻辑性评语" }
 * }
 * }</pre>
 *
 * @see net.lab1024.sa.admin.module.business.ai.external.controller.AiExternalController
 * @see net.lab1024.sa.admin.module.business.ai.external.service.AiExternalService
 */
@Slf4j
@Component
public class ScoreAiManager {

    /**
     * 计算加权分：原始分 × 难度系数
     */
    public BigDecimal calculateWeightedScore(BigDecimal rawScore, BigDecimal difficultyValue) {
        if (rawScore == null || difficultyValue == null) {
            return BigDecimal.ZERO;
        }
        return rawScore.multiply(difficultyValue).setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * 生成单题三维度评分（Mock 实现）
     * 后续替换为调用 AI 服务
     */
    public void fillDimensionScores(ScoreQuestionVO vo) {
        // Mock 数据：根据得分率模拟三维度分数
        BigDecimal score = vo.getScore() != null ? vo.getScore() : BigDecimal.ZERO;
        BigDecimal maxScore = vo.getMaxScore() != null ? vo.getMaxScore() : BigDecimal.ONE;
        double rate = score.divide(maxScore, 2, RoundingMode.HALF_UP).doubleValue();

        // 模拟三维度打分（0-5分）
        BigDecimal relevance = BigDecimal.valueOf(Math.min(5.0, Math.max(1.0, rate * 5)));
        BigDecimal coverage = BigDecimal.valueOf(Math.min(5.0, Math.max(1.0, (rate - 0.1) * 5)));
        BigDecimal logic = BigDecimal.valueOf(Math.min(5.0, Math.max(1.0, (rate + 0.1) * 5)));

        vo.setRelevanceScore(relevance);
        vo.setRelevanceComment(generateRelevanceComment(rate));
        vo.setCoverageScore(coverage);
        vo.setCoverageComment(generateCoverageComment(rate));
        vo.setLogicScore(logic);
        vo.setLogicComment(generateLogicComment(rate));
    }

    /**
     * 生成 AI 整体学习建议（Mock 实现）
     * 后续替换为调用 AI 服务
     */
    public ScoreAiFeedbackVO generateFeedback(List<ScoreQuestionVO> questions, BigDecimal totalScore) {
        ScoreAiFeedbackVO feedback = new ScoreAiFeedbackVO();

        if (questions == null || questions.isEmpty()) {
            feedback.setOverallComment("暂无数据，无法生成学习建议。");
            return feedback;
        }

        double avgRate = questions.stream()
                .filter(q -> q.getMaxScore() != null && q.getMaxScore().compareTo(BigDecimal.ZERO) > 0)
                .mapToDouble(q -> q.getScore().divide(q.getMaxScore(), 2, RoundingMode.HALF_UP).doubleValue())
                .average()
                .orElse(0.7);

        // 整体评价
        if (avgRate >= 0.85) {
            feedback.setOverallComment("整体表现优秀，知识掌握扎实，展现了良好的理解与分析能力。建议继续保持并尝试挑战更高难度题目。");
        } else if (avgRate >= 0.7) {
            feedback.setOverallComment("整体表现良好，基础知识点掌握较牢固，但在部分题目的深入分析上还有提升空间。");
        } else {
            feedback.setOverallComment("基础知识需要加强，建议重点复习课程核心概念并结合练习题巩固，后续考试会有明显提升。");
        }

        // 亮点
        feedback.setHighlights("对核心概念的把握较为准确，答题结构清晰、逻辑链条完整，能够应用于具体场景分析。");

        // 薄弱点
        feedback.setWeaknesses("部分论述题的展开不够深入，知识点之间的关联性分析偏弱，个别概念的理解停留在表面层次。");

        // 改进建议
        feedback.setImprovementSuggestions("1. 建议课后对照教材和课件逐章梳理知识点，构建知识图谱；2. 每周完成2-3道论述题练习，重点训练多角度分析问题的能力；3. 与同学互相批改答案，查漏补缺。");

        // 三维度总评
        ScoreAiFeedbackVO.DimensionSummary summary = new ScoreAiFeedbackVO.DimensionSummary();
        summary.setRelevanceAvg(questions.stream().filter(q -> q.getRelevanceScore() != null)
                .mapToDouble(q -> q.getRelevanceScore().doubleValue()).average().orElse(3.5));
        summary.setCoverageAvg(questions.stream().filter(q -> q.getCoverageScore() != null)
                .mapToDouble(q -> q.getCoverageScore().doubleValue()).average().orElse(3.5));
        summary.setLogicAvg(questions.stream().filter(q -> q.getLogicScore() != null)
                .mapToDouble(q -> q.getLogicScore().doubleValue()).average().orElse(3.5));
        feedback.setDimensionSummary(summary);

        return feedback;
    }

    // ========== 三维度评语生成（Mock） ==========

    private String generateRelevanceComment(double rate) {
        if (rate >= 0.85) return "答案与题目要求高度相关，精准把握问题核心，回答针对性强";
        else if (rate >= 0.7) return "答案基本切题，主要观点与题目相关，但部分内容可进一步聚焦";
        else return "答案与题目要求部分相关，存在偏离主题的内容，需加强审题能力";
    }

    private String generateCoverageComment(double rate) {
        if (rate >= 0.85) return "知识点覆盖全面，涵盖主要考点，展现了完整的知识体系";
        else if (rate >= 0.7) return "主要知识点已覆盖，个别次要考点遗漏，知识体系基本完整";
        else return "知识点覆盖不足，多处重要考点未涉及，需加强基础知识学习";
    }

    private String generateLogicComment(double rate) {
        if (rate >= 0.85) return "逻辑结构清晰，论证过程严密，层次分明，表达流畅易懂";
        else if (rate >= 0.7) return "逻辑基本通顺，总体结构合理，部分段落过渡可优化";
        else return "逻辑表达有待加强，论述层次不够清晰，建议学习优秀范文的谋篇布局";
    }
}
