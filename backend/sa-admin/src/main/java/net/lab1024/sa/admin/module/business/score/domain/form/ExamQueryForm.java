package net.lab1024.sa.admin.module.business.score.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;
import lombok.EqualsAndHashCode;
import net.lab1024.sa.base.common.domain.PageParam;
import org.hibernate.validator.constraints.Length;

/**
 * 教师端考试分页查询表单。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class ExamQueryForm extends PageParam {

    @Schema(description = "学期ID")
    private Long semesterId;

    @Schema(description = "课程ID")
    private Long courseId;

    @Schema(description = "考试名称")
    @Length(max = 100, message = "考试名称最多100字符")
    private String examName;

    @Schema(description = "考试状态：0未开始，1进行中，2已结束")
    @Min(value = 0, message = "考试状态错误")
    @Max(value = 2, message = "考试状态错误")
    private Integer examStatus;
}
