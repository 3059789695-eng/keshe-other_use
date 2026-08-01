/*
 * 文件：ResponseDTO.java
 * 包路径：com.student.manager.common
 */
package com.student.manager.common;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 统一响应结果。
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ResponseDTO<T> {

    private int code;
    private String message;
    private T data;

    public static <T> ResponseDTO<T> ok() {
        return new ResponseDTO<>(200, "操作成功", null);
    }

    public static <T> ResponseDTO<T> ok(T data) {
        return new ResponseDTO<>(200, "操作成功", data);
    }

    public static <T> ResponseDTO<T> userErrorParam(String message) {
        return new ResponseDTO<>(400, message, null);
    }

    public static <T> ResponseDTO<T> error(String message) {
        return new ResponseDTO<>(500, message, null);
    }
}
