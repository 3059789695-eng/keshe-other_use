package net.lab1024.sa.admin.module.business.ai.external.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import net.lab1024.sa.admin.module.business.ai.external.dto.FeedbackSubmitRequest;
import net.lab1024.sa.admin.module.business.ai.external.dto.GradingSubmitRequest;
import net.lab1024.sa.admin.module.business.ai.external.dto.PendingAnswerResponse;
import net.lab1024.sa.admin.module.business.score.dao.AnswerDetailDao;
import net.lab1024.sa.admin.module.business.score.dao.ScoreDao;
import net.lab1024.sa.admin.module.business.score.dao.StudentAnswerDao;
import net.lab1024.sa.admin.module.business.score.domain.entity.AnswerDetailEntity;
import net.lab1024.sa.admin.module.business.score.domain.entity.ScoreEntity;
import net.lab1024.sa.admin.module.business.score.domain.entity.StudentAnswerEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * AI 外部接口 Service
 *
 * 为 Python AI 服务提供数据查询和结果回写能力。
 * Python 通过 AiExternalController 调用本 Service。
 */
@Slf4j
@Service
public class AiExternalService {

    @Resource
    private AnswerDetailDao answerDetailDao;

    @Resource
    private StudentAnswerDao studentAnswerDao;

    @Resource
    private ScoreDao scoreDao;

    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    // ==================== ① 查询待批改答案 ====================

    /**
     * 查询所有待批改的外部服务答案
     *
     * 条件：grade_type = 2（外部服务）且 score IS NULL（未批改）
     * 仅返回作答状态为"已提交"(4)或"已批改"(5)的答案
     */
    public List<PendingAnswerResponse> queryPendingAnswers() {
        // 1. 查询所有标记为外部服务且未批改的答案详情
        List<AnswerDetailEntity> details = answerDetailDao.selectList(
                new LambdaQueryWrapper<AnswerDetailEntity>()
                        .isNull(AnswerDetailEntity::getScore)
                        .eq(AnswerDetailEntity::getGradeType, 2));

        if (details.isEmpty()) {
            return Collections.emptyList();
        }

        // 2. 收集所有 answerId
        Set<Long> answerIds = details.stream()
                .map(AnswerDetailEntity::getAnswerId)
                .collect(Collectors.toSet());

        // 3. 批量查询作答记录（获取 examId、studentId、status）
        List<StudentAnswerEntity> studentAnswers = studentAnswerDao.selectList(
                new LambdaQueryWrapper<StudentAnswerEntity>()
                        .in(StudentAnswerEntity::getAnswerId, answerIds));

        Map<Long, StudentAnswerEntity> answerMap = studentAnswers.stream()
                .collect(Collectors.toMap(
                        StudentAnswerEntity::getAnswerId,
                        Function.identity(),
                        (a, b) -> a));

        // 4. 组装返回，过滤掉状态不是"已提交"或"已批改"的
        List<PendingAnswerResponse> result = new ArrayList<>();
        for (AnswerDetailEntity detail : details) {
            StudentAnswerEntity sa = answerMap.get(detail.getAnswerId());
            if (sa == null) {
                continue;
            }
            // 仅返回状态为 4(已提交) 或 5(已批改) 的答案
            if (sa.getStatus() != 4 && sa.getStatus() != 5) {
                continue;
            }

            PendingAnswerResponse resp = new PendingAnswerResponse();
            resp.setAnswerDetailId(detail.getId());
            resp.setExamId(sa.getExamId());
            resp.setStudentId(sa.getStudentId());
            resp.setQuestionId(detail.getQuestionId());
            resp.setUserAnswer(detail.getUserAnswer());
            resp.setVoiceRecordUrl(detail.getVoiceRecordUrl());
            resp.setGradeType(detail.getGradeType());
            // 以下字段需要题目表支持，当前数据库未建表，暂时留空
            // resp.setQuestionContent(...);
            // resp.setQuestionType(...);
            // resp.setMaxScore(...);
            result.add(resp);
        }

        log.info("查询待批改答案：共 {} 条", result.size());
        return result;
    }

    // ==================== ② 提交单题评分 ====================

    /**
     * Python AI 提交单题评分
     *
     * 将三维度评分明细与评语以 JSON 格式存入 grade_remark 字段，
     * 同时更新 score 字段。提交后重算总分。
     */
    @Transactional(rollbackFor = Exception.class)
    public void submitGrade(GradingSubmitRequest request) {
        // 1. 查询答案详情
        AnswerDetailEntity detail = answerDetailDao.selectById(request.getAnswerDetailId());
        if (detail == null) {
            log.warn("提交评分失败：答案详情不存在，answerDetailId={}", request.getAnswerDetailId());
            return;
        }

        // 2. 构建评语 JSON（含三维度评分明细）
        String gradeRemarkJson = buildGradeRemarkJson(request);

        // 3. 更新得分和评语
        detail.setScore(request.getScore());
        detail.setGradeRemark(gradeRemarkJson);
        detail.setUpdateTime(LocalDateTime.now());
        answerDetailDao.updateById(detail);

        log.info("评分已提交：answerDetailId={}, score={}", request.getAnswerDetailId(), request.getScore());

        // 4. 重算总分
        recalculateTotalScore(detail.getAnswerId());
    }

    /**
     * 将评分请求中的三维度信息构建为 JSON 字符串
     */
    private String buildGradeRemarkJson(GradingSubmitRequest request) {
        try {
            Map<String, Object> json = new LinkedHashMap<>();
            json.put("remark", request.getGradeRemark());

            if (request.getRelevanceScore() != null || request.getRelevanceComment() != null) {
                Map<String, Object> relevance = new LinkedHashMap<>();
                relevance.put("score", request.getRelevanceScore());
                relevance.put("comment", request.getRelevanceComment());
                json.put("relevance", relevance);
            }
            if (request.getCoverageScore() != null || request.getCoverageComment() != null) {
                Map<String, Object> coverage = new LinkedHashMap<>();
                coverage.put("score", request.getCoverageScore());
                coverage.put("comment", request.getCoverageComment());
                json.put("coverage", coverage);
            }
            if (request.getLogicScore() != null || request.getLogicComment() != null) {
                Map<String, Object> logic = new LinkedHashMap<>();
                logic.put("score", request.getLogicScore());
                logic.put("comment", request.getLogicComment());
                json.put("logic", logic);
            }

            return OBJECT_MAPPER.writeValueAsString(json);
        } catch (JsonProcessingException e) {
            log.error("构建评语 JSON 失败", e);
            return request.getGradeRemark(); // 降级为纯文本
        }
    }

    // ==================== ③ 提交学习建议 ====================

    /**
     * Python AI 提交整体学习建议
     *
     * 将学习建议以 JSON 格式存入 t_score.remark 字段。
     * 如果成绩记录不存在则跳过（需要等待批改完成后成绩记录才会生成）。
     */
    @Transactional(rollbackFor = Exception.class)
    public void submitFeedback(FeedbackSubmitRequest request) {
        // 1. 查询成绩记录
        ScoreEntity scoreEntity = scoreDao.selectOne(
                new LambdaQueryWrapper<ScoreEntity>()
                        .eq(ScoreEntity::getExamId, request.getExamId())
                        .eq(ScoreEntity::getStudentId, request.getStudentId()));

        if (scoreEntity == null) {
            log.warn("提交学习建议失败：成绩记录不存在，examId={}, studentId={}",
                    request.getExamId(), request.getStudentId());
            return;
        }

        // 2. 构建反馈 JSON
        String feedbackJson = buildFeedbackJson(request);

        // 3. 写入 remark 字段
        scoreEntity.setRemark(feedbackJson);
        scoreEntity.setUpdateTime(LocalDateTime.now());
        scoreDao.updateById(scoreEntity);

        log.info("学习建议已提交：examId={}, studentId={}", request.getExamId(), request.getStudentId());
    }

    /**
     * 将学习建议构建为 JSON 字符串
     */
    private String buildFeedbackJson(FeedbackSubmitRequest request) {
        try {
            Map<String, Object> json = new LinkedHashMap<>();
            json.put("type", "ai_feedback");
            json.put("overallComment", request.getOverallComment());
            json.put("highlights", request.getHighlights());
            json.put("weaknesses", request.getWeaknesses());
            json.put("improvementSuggestions", request.getImprovementSuggestions());
            return OBJECT_MAPPER.writeValueAsString(json);
        } catch (JsonProcessingException e) {
            log.error("构建反馈 JSON 失败", e);
            return request.getOverallComment(); // 降级为纯文本
        }
    }

    // ==================== 重算总分 ====================

    /**
     * 根据答案详情重算该作答记录对应考试的总分
     *
     * 汇总 t_answer_detail 中该 answerId 下所有题目的得分，
     * 更新 t_score 表的 total_score 和 pass_status。
     */
    @Transactional(rollbackFor = Exception.class)
    public void recalculateTotalScore(Long answerId) {
        // 1. 查询作答记录
        StudentAnswerEntity studentAnswer = studentAnswerDao.selectById(answerId);
        if (studentAnswer == null) {
            log.warn("重算总分失败：作答记录不存在，answerId={}", answerId);
            return;
        }

        // 2. 查询该作答记录下所有答案详情的得分
        List<AnswerDetailEntity> details = answerDetailDao.selectList(
                new LambdaQueryWrapper<AnswerDetailEntity>()
                        .eq(AnswerDetailEntity::getAnswerId, answerId));

        // 如果有题目还未批改，不重算
        boolean hasUngraded = details.stream().anyMatch(d -> d.getScore() == null);
        if (hasUngraded) {
            log.info("存在未批改题目，暂不重算总分：answerId={}", answerId);
            return;
        }

        // 3. 汇总总分
        BigDecimal totalScore = details.stream()
                .map(AnswerDetailEntity::getScore)
                .filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // 4. 查找或创建成绩记录
        ScoreEntity scoreEntity = scoreDao.selectOne(
                new LambdaQueryWrapper<ScoreEntity>()
                        .eq(ScoreEntity::getExamId, studentAnswer.getExamId())
                        .eq(ScoreEntity::getStudentId, studentAnswer.getStudentId()));

        if (scoreEntity == null) {
            // 首次批改，创建成绩记录
            scoreEntity = new ScoreEntity();
            scoreEntity.setExamId(studentAnswer.getExamId());
            scoreEntity.setStudentId(studentAnswer.getStudentId());
            scoreEntity.setTotalScore(totalScore);
            scoreEntity.setPassStatus(totalScore.compareTo(new BigDecimal("60")) >= 0 ? 1 : 0);
            scoreEntity.setSubmitTime(studentAnswer.getSubmitTime());
            scoreEntity.setGradeTime(LocalDateTime.now());
            scoreEntity.setCreateTime(LocalDateTime.now());
            scoreEntity.setUpdateTime(LocalDateTime.now());
            scoreDao.insert(scoreEntity);
            log.info("创建成绩记录：examId={}, studentId={}, totalScore={}",
                    studentAnswer.getExamId(), studentAnswer.getStudentId(), totalScore);
        } else {
            // 更新已有成绩
            scoreEntity.setTotalScore(totalScore);
            scoreEntity.setPassStatus(totalScore.compareTo(new BigDecimal("60")) >= 0 ? 1 : 0);
            scoreEntity.setGradeTime(LocalDateTime.now());
            scoreEntity.setUpdateTime(LocalDateTime.now());
            scoreDao.updateById(scoreEntity);
            log.info("更新成绩记录：scoreId={}, totalScore={}", scoreEntity.getScoreId(), totalScore);
        }

        // 5. 更新作答记录状态为"已批改"
        if (studentAnswer.getStatus() != 5) {
            studentAnswer.setStatus(5); // 5:已批改
            studentAnswer.setUpdateTime(LocalDateTime.now());
            studentAnswerDao.updateById(studentAnswer);
        }
    }
}
