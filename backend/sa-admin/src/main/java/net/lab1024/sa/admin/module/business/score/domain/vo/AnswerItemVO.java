package net.lab1024.sa.admin.module.business.score.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;

import lombok.Data;

import java.math.BigDecimal;

/**
 * 学生单题作答信息。
 */
@Data
public class AnswerItemVO {
    @Schema(description = "答题记录 ID")
    private Long answerId;
    @Schema(description = "题目 ID")
    private Long questionId;
    @Schema(description = "题目内容")
    private String questionContent;
    @Schema(description = "学生答案")
    private String studentAnswer;
    @Schema(description = "第三方评分结果")
    private BigDecimal aiScore;
    @Schema(description = "最终得分")
    private BigDecimal finalScore;
    @Schema(description = "题目满分")
    private BigDecimal maxScore;
    @Schema(description = "第三方评分说明")
    private String aiComment;
}
