package net.lab1024.sa.admin.module.business.ai.external.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 外部 AI 接口统一返回结果
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AiExternalResultResponse {

    @Schema(description = "是否成功", example = "true")
    private Boolean success;

    @Schema(description = "提示信息", example = "评分提交成功")
    private String message;

    @Schema(description = "附加数据（可选）")
    private Object data;

    public static AiExternalResultResponse ok(String message) {
        return new AiExternalResultResponse(true, message, null);
    }

    public static AiExternalResultResponse ok(String message, Object data) {
        return new AiExternalResultResponse(true, message, data);
    }

    public static AiExternalResultResponse fail(String message) {
        return new AiExternalResultResponse(false, message, null);
    }
}
