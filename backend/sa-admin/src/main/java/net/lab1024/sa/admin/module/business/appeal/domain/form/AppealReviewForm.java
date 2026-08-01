package net.lab1024.sa.admin.module.business.appeal.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import org.hibernate.validator.constraints.Length;

import java.math.BigDecimal;

/**
 * 教师端成绩复议处理表单。
 */
@Data
public class AppealReviewForm {

    @Schema(description = "复议申请 ID")
    @NotNull(message = "复议ID不能为空")
    private Long appealId;

    @Schema(description = "处理结果：1通过，2驳回")
    @NotNull(message = "处理结果不能为空")
    @Min(value = 1, message = "处理结果错误")
    @Max(value = 2, message = "处理结果错误")
    private Integer reviewResult;

    @Schema(description = "通过复议后的题目得分")
    private BigDecimal adjustedScore;

    @Schema(description = "教师处理意见")
    @NotBlank(message = "处理意见不能为空")
    @Length(max = 500, message = "处理意见最多500字符")
    private String teacherOpinion;
}
