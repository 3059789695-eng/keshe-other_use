package net.lab1024.sa.admin.module.business.score.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import net.lab1024.sa.base.common.domain.PageParam;

/**
 * 成绩查询表单
 */
@Data
public class ScoreQueryForm {

    @Schema(description = "考试 ID")
    @NotNull(message = "考试 ID 不能为空")
    private Long examId;

    @Schema(description = "学生 ID（不传则查当前登录用户）")
    private Long studentId;
}
