package net.lab1024.sa.admin.module.business.appeal.domain.form;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;

/**
 * 复议申请提交表单（S-09）
 */
@Data
public class AppealSubmitForm {

    @Schema(description = "成绩 ID")
    @NotNull(message = "成绩 ID 不能为空")
    private Long scoreId;

    @Schema(description = "答案详情 ID（定位到具体题目）")
    @NotNull(message = "答案详情 ID 不能为空")
    private Long answerDetailId;

    @Schema(description = "考试 ID")
    @NotNull(message = "考试 ID 不能为空")
    private Long examId;

    @Schema(description = "复议理由")
    @NotBlank(message = "复议理由不能为空")
    @Size(max = 500, message = "复议理由最多 500 字")
    private String appealReason;

    @Schema(description = "证据截图 URL（最多 3 张）")
    @Size(max = 3, message = "证明材料最多上传 3 张")
    private List<String> evidenceUrls;
}
