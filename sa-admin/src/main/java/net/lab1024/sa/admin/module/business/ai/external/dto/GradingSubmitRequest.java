package net.lab1024.sa.admin.module.business.ai.external.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

/**
 * Python AI 提交单题评分
 */
@Data
public class GradingSubmitRequest {

    @Schema(description = "答案详情 ID", example = "1001")
    @NotNull(message = "答案详情 ID 不能为空")
    private Long answerDetailId;

    @Schema(description = "本题得分", example = "8.50")
    @NotNull(message = "得分不能为空")
    @DecimalMin(value = "0", message = "得分不能小于0")
    private BigDecimal score;

    @Schema(description = "评分理由（30-80字）", example = "答案切题，知识点覆盖较全面，逻辑通顺，但部分论证不够深入")
    @NotBlank(message = "评语不能为空")
    private String gradeRemark;

    // ===== 三维度评分明细 =====

    @Schema(description = "相关性得分（0-5）", example = "4.5")
    @DecimalMin(value = "0")
    @DecimalMax(value = "5")
    private BigDecimal relevanceScore;

    @Schema(description = "相关性评语", example = "答案与题目要求高度相关，精准把握问题核心")
    private String relevanceComment;

    @Schema(description = "知识点覆盖度得分（0-5）", example = "4.0")
    @DecimalMin(value = "0")
    @DecimalMax(value = "5")
    private BigDecimal coverageScore;

    @Schema(description = "知识点覆盖度评语", example = "主要知识点已覆盖，个别次要考点遗漏")
    private String coverageComment;

    @Schema(description = "逻辑表达性得分（0-5）", example = "3.5")
    @DecimalMin(value = "0")
    @DecimalMax(value = "5")
    private BigDecimal logicScore;

    @Schema(description = "逻辑表达性评语", example = "逻辑基本通顺，部分段落过渡可优化")
    private String logicComment;
}
