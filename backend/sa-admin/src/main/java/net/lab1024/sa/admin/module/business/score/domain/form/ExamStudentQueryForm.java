package net.lab1024.sa.admin.module.business.score.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import lombok.EqualsAndHashCode;
import net.lab1024.sa.base.common.domain.PageParam;
import org.hibernate.validator.constraints.Length;

/**
 * 教师端学生考试完成情况分页查询表单。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class ExamStudentQueryForm extends PageParam {

    @Schema(description = "考试 ID")
    @NotNull(message = "考试ID不能为空")
    private Long examId;

    @Schema(description = "完成状态：0未开始，1进行中，2已提交")
    @Min(value = 0, message = "完成状态错误")
    @Max(value = 2, message = "完成状态错误")
    private Integer completionStatus;

    @Schema(description = "学号或姓名")
    @Length(max = 50, message = "搜索内容最多50字符")
    private String studentKeyword;
}
