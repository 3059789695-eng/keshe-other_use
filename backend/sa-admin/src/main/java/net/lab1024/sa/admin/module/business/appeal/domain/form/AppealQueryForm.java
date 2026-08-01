package net.lab1024.sa.admin.module.business.appeal.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;
import lombok.EqualsAndHashCode;
import net.lab1024.sa.base.common.domain.PageParam;
import org.hibernate.validator.constraints.Length;

/**
 * 教师端成绩复议分页查询表单。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class AppealQueryForm extends PageParam {

    @Schema(description = "学期 ID")
    private Long semesterId;

    @Schema(description = "课程 ID")
    private Long courseId;

    @Schema(description = "考试 ID")
    private Long examId;

    @Schema(description = "学号或姓名")
    @Length(max = 50, message = "学生搜索内容最多50字符")
    private String studentKeyword;

    @Schema(description = "复议状态：0待处理，1已通过，2已驳回")
    @Min(value = 0, message = "复议状态错误")
    @Max(value = 2, message = "复议状态错误")
    private Integer appealStatus;
}
