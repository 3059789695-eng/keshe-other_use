package net.lab1024.sa.admin.module.business.appeal.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import net.lab1024.sa.base.common.domain.PageParam;

/**
 * 复议记录查询表单
 */
@EqualsAndHashCode(callSuper = true)
@Data
public class AppealQueryForm extends PageParam {

    @Schema(description = "学生 ID（不传则查当前登录用户）")
    private Long studentId;

    @Schema(description = "考试 ID")
    private Long examId;

    @Schema(description = "状态 [1:待审核,2:已通过,3:已驳回]")
    private Integer status;

    @Schema(description = "搜索关键词（匹配题目内容或复议理由）")
    private String keyword;
}
