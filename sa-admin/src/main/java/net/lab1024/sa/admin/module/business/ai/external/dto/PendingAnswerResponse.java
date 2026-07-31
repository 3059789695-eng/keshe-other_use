package net.lab1024.sa.admin.module.business.ai.external.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 返回给 Python AI 的待批改答案
 */
@Data
public class PendingAnswerResponse {

    @Schema(description = "答案详情 ID（提交评分时原样回传）", example = "1001")
    private Long answerDetailId;

    @Schema(description = "考试 ID", example = "10")
    private Long examId;

    @Schema(description = "学生 ID", example = "2001")
    private Long studentId;

    @Schema(description = "题目 ID", example = "5001")
    private Long questionId;

    @Schema(description = "题目内容", example = "请论述人工智能在医疗领域的应用前景")
    private String questionContent;

    @Schema(description = "题型 [1:单选,2:多选,3:判断,4:简答,5:论述]", example = "5")
    private Integer questionType;

    @Schema(description = "题目满分", example = "10.00")
    private BigDecimal maxScore;

    @Schema(description = "学生答案文本", example = "人工智能在医疗领域有广泛的应用前景，主要包括...")
    private String userAnswer;

    @Schema(description = "语音答题录音 URL（如有）")
    private String voiceRecordUrl;

    @Schema(description = "批改方式 [1:规则自动,2:外部服务,3:人工]", example = "2")
    private Integer gradeType;
}
