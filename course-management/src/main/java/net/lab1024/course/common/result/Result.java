package net.lab1024.course.common.result;

import lombok.Data;

/**
 * 统一返回结果类
 * 所有接口统一使用此格式返回
 */
@Data
public class Result<T> {

    /** 状态码：200=成功，500=失败 */
    private int code;

    /** 提示信息 */
    private String msg;

    /** 返回数据 */
    private T data;

    private Result(int code, String msg, T data) {
        this.code = code;
        this.msg = msg;
        this.data = data;
    }

    /**
     * 操作成功（带数据）
     */
    public static <T> Result<T> success(T data) {
        return new Result<>(200, "操作成功", data);
    }

    /**
     * 操作成功（无数据）
     */
    public static <T> Result<T> success() {
        return new Result<>(200, "操作成功", null);
    }

    /**
     * 操作成功（自定义消息）
     */
    public static <T> Result<T> success(String msg, T data) {
        return new Result<>(200, msg, data);
    }

    /**
     * 操作失败
     */
    public static <T> Result<T> error(String msg) {
        return new Result<>(500, msg, null);
    }

    /**
     * 操作失败（自定义状态码）
     */
    public static <T> Result<T> error(int code, String msg) {
        return new Result<>(code, msg, null);
    }

    /**
     * 无权限
     */
    public static <T> Result<T> forbidden(String msg) {
        return new Result<>(403, msg, null);
    }
}
