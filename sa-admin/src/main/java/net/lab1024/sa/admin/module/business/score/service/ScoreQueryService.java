package net.lab1024.sa.admin.module.business.score.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import net.lab1024.sa.admin.module.business.appeal.constant.AppealStatusEnum;
import net.lab1024.sa.admin.module.business.appeal.dao.AppealDao;
import net.lab1024.sa.admin.module.business.appeal.domain.entity.AppealEntity;
import net.lab1024.sa.admin.module.business.score.constant.PassStatusEnum;
import net.lab1024.sa.admin.module.business.score.dao.AnswerDetailDao;
import net.lab1024.sa.admin.module.business.score.dao.ScoreDao;
import net.lab1024.sa.admin.module.business.score.dao.StudentAnswerDao;
import net.lab1024.sa.admin.module.business.score.domain.entity.AnswerDetailEntity;
import net.lab1024.sa.admin.module.business.score.domain.entity.ScoreEntity;
import net.lab1024.sa.admin.module.business.score.domain.entity.StudentAnswerEntity;
import net.lab1024.sa.admin.module.business.score.domain.form.ScoreQueryForm;
import net.lab1024.sa.admin.module.business.score.domain.vo.ScoreAiFeedbackVO;
import net.lab1024.sa.admin.module.business.score.domain.vo.ScoreDetailVO;
import net.lab1024.sa.admin.module.business.score.domain.vo.ScoreHistoryVO;
import net.lab1024.sa.admin.module.business.score.domain.vo.ScoreQuestionVO;
import net.lab1024.sa.admin.module.business.score.manager.ScoreAiManager;
import net.lab1024.sa.admin.util.AdminRequestUtil;
import net.lab1024.sa.base.common.code.UserErrorCode;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import net.lab1024.sa.base.common.util.SmartBeanUtil;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 成绩管理 - 读操作
 */
@Slf4j
@Service
public class ScoreQueryService {

    @Resource
    private ScoreDao scoreDao;

    @Resource
    private StudentAnswerDao studentAnswerDao;

    @Resource
    private AnswerDetailDao answerDetailDao;

    @Resource
    private ScoreAiManager scoreAiManager;

    @Resource
    private AppealDao appealDao;

    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    /**
     * 查看成绩详情（S-07：查看本次成绩与反馈）
     *
     * 返回：总分、每题得分（含原始分×难度系数=加权分）、评分理由、
     * 三维度评分明细（相关性/知识点覆盖度/逻辑表达性）、AI 学习建议
     */
    public ResponseDTO<ScoreDetailVO> getDetail(ScoreQueryForm form) {
        // 1. 确定学生 ID
        Long studentId = form.getStudentId();
        if (studentId == null) {
            studentId = AdminRequestUtil.getRequestUserId();
        }

        // 2. 查询成绩记录
        ScoreEntity scoreEntity = scoreDao.selectByExamIdAndStudent(form.getExamId(), studentId);
        if (scoreEntity == null) {
            return ResponseDTO.error(UserErrorCode.DATA_NOT_EXIST);
        }

        // 3. 查询作答记录
        StudentAnswerEntity answerEntity = studentAnswerDao.selectByExamIdAndStudent(form.getExamId(), studentId);
        if (answerEntity == null) {
            return ResponseDTO.error(UserErrorCode.DATA_NOT_EXIST);
        }

        // 4. 查询答案详情（每题得分）
        List<AnswerDetailEntity> detailList = answerDetailDao.selectByAnswerId(answerEntity.getAnswerId());
        if (detailList.isEmpty()) {
            return ResponseDTO.error(UserErrorCode.DATA_NOT_EXIST);
        }

        // 5. 组装 VO
        ScoreDetailVO vo = SmartBeanUtil.copy(scoreEntity, ScoreDetailVO.class);
        vo.setPassStatusText(PassStatusEnum.getDescByValue(scoreEntity.getPassStatus()));
        // TODO: 以下字段需要关联查询其他模块（考试、课程、学期、员工），
        // 当前框架未提供这些模块的接口，暂时留空由调用方填充
        // vo.setExamTitle(...);
        // vo.setCourseName(...);
        // vo.setSemesterName(...);
        // vo.setStudentName(...);

        // 6. 组装每题得分（含三维度评分 + 加权分）
        BigDecimal examDifficulty = BigDecimal.ONE; // TODO: 从考试表获取难度系数
        List<ScoreQuestionVO> questions = new ArrayList<>();
        for (int i = 0; i < detailList.size(); i++) {
            AnswerDetailEntity detail = detailList.get(i);
            ScoreQuestionVO questionVO = new ScoreQuestionVO();
            questionVO.setAnswerDetailId(detail.getId());
            questionVO.setSortOrder(i + 1);
            questionVO.setQuestionId(detail.getQuestionId());
            questionVO.setUserAnswer(detail.getUserAnswer());
            questionVO.setScore(detail.getScore());
            questionVO.setMaxScore(BigDecimal.ONE); // TODO: 从试卷-题目关联表获取
            questionVO.setDifficultyValue(examDifficulty);
            questionVO.setWeightedScore(
                    scoreAiManager.calculateWeightedScore(detail.getScore(), examDifficulty));
            questionVO.setGradeRemark(detail.getGradeRemark());

            // 三维度 AI 评分：优先读取 Python AI 写入的真实数据，没有则回退到 Mock
            if (!tryFillDimensionFromJson(questionVO, detail.getGradeRemark())) {
                scoreAiManager.fillDimensionScores(questionVO);
            }

            // 复议状态——查询 t_appeal 表
            fillAppealStatus(questionVO, detail.getId());

            questions.add(questionVO);
        }
        vo.setQuestions(questions);

        // 7. 生成 AI 整体学习建议：优先读取 Python AI 写入的真实数据，没有则回退到 Mock
        if (!questions.isEmpty()) {
            ScoreAiFeedbackVO feedback = tryParseFeedbackFromJson(scoreEntity.getRemark());
            if (feedback == null) {
                feedback = scoreAiManager.generateFeedback(questions, scoreEntity.getTotalScore());
            }
            vo.setAiFeedback(feedback);
        }

        return ResponseDTO.ok(vo);
    }

    // ==================== JSON 解析辅助方法 ====================

    /**
     * 尝试从 grade_remark JSON 中解析三维度评分数据并填充到 VO
     *
     * @return true 表示解析成功并已填充，false 表示需要回退到 Mock
     */
    private boolean tryFillDimensionFromJson(ScoreQuestionVO vo, String gradeRemark) {
        if (gradeRemark == null || gradeRemark.isBlank() || !gradeRemark.startsWith("{")) {
            return false;
        }
        try {
            Map<String, Object> json = OBJECT_MAPPER.readValue(
                    gradeRemark, new TypeReference<Map<String, Object>>() {});

            // 解析评分理由
            Object remark = json.get("remark");
            if (remark != null) {
                vo.setGradeRemark(remark.toString());
            }

            // 解析三维度
            fillDimensionFromJson(vo, json, "relevance");
            fillDimensionFromJson(vo, json, "coverage");
            fillDimensionFromJson(vo, json, "logic");

            return vo.getRelevanceScore() != null
                    || vo.getCoverageScore() != null
                    || vo.getLogicScore() != null;
        } catch (Exception e) {
            return false;
        }
    }

    @SuppressWarnings("unchecked")
    private void fillDimensionFromJson(ScoreQuestionVO vo, Map<String, Object> json, String key) {
        Object dim = json.get(key);
        if (!(dim instanceof Map)) {
            return;
        }
        Map<String, Object> dimMap = (Map<String, Object>) dim;
        try {
            BigDecimal score = toBigDecimal(dimMap.get("score"));
            String comment = dimMap.get("comment") != null ? dimMap.get("comment").toString() : null;

            switch (key) {
                case "relevance":
                    vo.setRelevanceScore(score);
                    vo.setRelevanceComment(comment);
                    break;
                case "coverage":
                    vo.setCoverageScore(score);
                    vo.setCoverageComment(comment);
                    break;
                case "logic":
                    vo.setLogicScore(score);
                    vo.setLogicComment(comment);
                    break;
            }
        } catch (Exception ignored) {
            // 单个维度解析失败不影响其他维度
        }
    }

    /**
     * 尝试从 t_score.remark JSON 中解析 AI 学习建议
     *
     * @return ScoreAiFeedbackVO 解析成功时返回，null 表示需要回退到 Mock
     */
    private ScoreAiFeedbackVO tryParseFeedbackFromJson(String remark) {
        if (remark == null || remark.isBlank() || !remark.startsWith("{")) {
            return null;
        }
        try {
            Map<String, Object> json = OBJECT_MAPPER.readValue(
                    remark, new TypeReference<Map<String, Object>>() {});

            // 检查是否为 AI 反馈类型
            Object type = json.get("type");
            if (!"ai_feedback".equals(type)) {
                return null;
            }

            ScoreAiFeedbackVO feedback = new ScoreAiFeedbackVO();
            feedback.setOverallComment(getString(json, "overallComment"));
            feedback.setHighlights(getString(json, "highlights"));
            feedback.setWeaknesses(getString(json, "weaknesses"));
            feedback.setImprovementSuggestions(getString(json, "improvementSuggestions"));
            return feedback;
        } catch (Exception e) {
            return null;
        }
    }

    private String getString(Map<String, Object> json, String key) {
        Object val = json.get(key);
        return val != null ? val.toString() : null;
    }

    private BigDecimal toBigDecimal(Object val) {
        if (val == null) return null;
        if (val instanceof BigDecimal) return (BigDecimal) val;
        try {
            return new BigDecimal(val.toString());
        } catch (Exception e) {
            return null;
        }
    }

    // ==================== 复议状态关联 ====================

    /**
     * 查询 t_appeal 表，填充题目复议状态
     */
    private void fillAppealStatus(ScoreQuestionVO vo, Long answerDetailId) {
        try {
            AppealEntity appeal = appealDao.selectLatestByAnswerDetailId(answerDetailId);
            if (appeal != null) {
                vo.setAppealed(true);
                vo.setAppealStatus(appeal.getStatus());
                vo.setAppealStatusText(AppealStatusEnum.getDescByValue(appeal.getStatus()));
            } else {
                vo.setAppealed(false);
            }
        } catch (Exception e) {
            vo.setAppealed(false);
        }
    }

    // ==================== 历史成绩查询 ====================

    /**
     * 学生查询历史成绩列表
     *
     * 返回该学生的所有考试成绩，按交卷时间倒序。
     * 同时查询每场考试是否有复议记录（hasAppeal）。
     */
    public ResponseDTO<List<ScoreHistoryVO>> getHistory(Long studentId) {
        // 1. 确定学生 ID
        if (studentId == null) {
            try {
                studentId = AdminRequestUtil.getRequestUserId();
            } catch (Exception e) {
                return ResponseDTO.userErrorParam("请提供学生 ID");
            }
        }

        // 2. 查询该学生所有成绩，按交卷时间倒序
        List<ScoreEntity> scoreList = scoreDao.selectByStudentId(studentId);
        if (scoreList.isEmpty()) {
            return ResponseDTO.ok(Collections.emptyList());
        }

        // 3. 收集所有 examId，批量查询复议记录
        List<Long> examIds = scoreList.stream()
                .map(ScoreEntity::getExamId)
                .distinct()
                .collect(Collectors.toList());

        List<AppealEntity> appeals = appealDao.selectByExamIdsAndStudent(examIds, studentId);

        Set<Long> appealedExamIds = appeals.stream()
                .map(AppealEntity::getExamId)
                .collect(Collectors.toSet());

        // 4. 组装 VO
        List<ScoreHistoryVO> result = scoreList.stream().map(entity -> {
            ScoreHistoryVO vo = SmartBeanUtil.copy(entity, ScoreHistoryVO.class);
            vo.setPassStatusText(PassStatusEnum.getDescByValue(entity.getPassStatus()));
            vo.setHasAppeal(appealedExamIds.contains(entity.getExamId()));
            // TODO: 以下字段需要关联查询考试/课程/学期表
            // vo.setExamTitle(...);
            // vo.setCourseName(...);
            // vo.setSemesterName(...);
            return vo;
        }).collect(Collectors.toList());

        return ResponseDTO.ok(result);
    }
}
