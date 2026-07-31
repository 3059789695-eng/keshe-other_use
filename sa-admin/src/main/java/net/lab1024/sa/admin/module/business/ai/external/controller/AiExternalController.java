package net.lab1024.sa.admin.module.business.ai.external.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import net.lab1024.sa.admin.module.business.ai.external.dto.AiExternalResultResponse;
import net.lab1024.sa.admin.module.business.ai.external.dto.FeedbackSubmitRequest;
import net.lab1024.sa.admin.module.business.ai.external.dto.GradingSubmitRequest;
import net.lab1024.sa.admin.module.business.ai.external.dto.PendingAnswerResponse;
import net.lab1024.sa.admin.module.business.ai.external.service.AiExternalService;
import net.lab1024.sa.base.common.annoation.NoNeedLogin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * AI 外部接口 — 供 Python AI 服务调用
 *
 * 本 Controller 的接口供外部 Python AI 服务访问，不需要登录鉴权。
 * 流程：
 * 1. Python 调用 /pending-answers 拉取待批改数据
 * 2. Python 用 AI 模型评分
 * 3. Python 调用 /submit-grade 逐题提交评分
 * 4. Python 调用 /submit-feedback 提交整体学习建议
 */
@RestController
@Tag(name = "AI 外部接口（供 Python 调用）")
public class AiExternalController {

    @Resource
    private AiExternalService aiExternalService;

    /**
     * ① 拉取待批改答案列表
     *
     * Python AI 服务定时或按需调用此接口，
     * 获取所有 gradeType=2（外部服务）且未批改（score IS NULL）的答案。
     * 返回的 answerDetailId 需在提交评分时原样回传。
     */
    @Operation(summary = "拉取待批改答案列表")
    @NoNeedLogin
    @PostMapping("/api/external/ai/pending-answers")
    public List<PendingAnswerResponse> getPendingAnswers() {
        return aiExternalService.queryPendingAnswers();
    }

    /**
     * ② 提交单题评分
     *
     * Python AI 对一道题完成评分后，调用此接口回写结果。
     * 包含：得分、评分理由、三维度评分明细（相关性/覆盖度/逻辑性）。
     * 提交后系统自动重算该学生本次考试的总分。
     */
    @Operation(summary = "提交单题评分")
    @NoNeedLogin
    @PostMapping("/api/external/ai/submit-grade")
    public AiExternalResultResponse submitGrade(@RequestBody @Valid GradingSubmitRequest request) {
        try {
            aiExternalService.submitGrade(request);
            return AiExternalResultResponse.ok("评分提交成功，answerDetailId=" + request.getAnswerDetailId());
        } catch (Exception e) {
            return AiExternalResultResponse.fail("评分提交失败：" + e.getMessage());
        }
    }

    /**
     * ③ 提交整体学习建议
     *
     * Python AI 在完成该学生全部题目的评分后，调用此接口提交整体学习建议。
     * 包含：总体评价、亮点、薄弱点、改进建议。
     * 注意：需在所有题目评分提交完毕后调用，否则成绩记录可能尚未生成。
     */
    @Operation(summary = "提交整体学习建议")
    @NoNeedLogin
    @PostMapping("/api/external/ai/submit-feedback")
    public AiExternalResultResponse submitFeedback(@RequestBody @Valid FeedbackSubmitRequest request) {
        try {
            aiExternalService.submitFeedback(request);
            return AiExternalResultResponse.ok(
                    "学习建议提交成功，examId=" + request.getExamId() + ", studentId=" + request.getStudentId());
        } catch (Exception e) {
            return AiExternalResultResponse.fail("学习建议提交失败：" + e.getMessage());
        }
    }
}
