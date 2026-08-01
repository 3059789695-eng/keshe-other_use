package net.lab1024.course.common.handler;

import net.lab1024.course.common.result.Result;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * 全局异常处理器
 * 统一捕获并返回友好错误信息
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    /**
     * 捕获参数校验异常
     */
    @ExceptionHandler(IllegalArgumentException.class)
    public Result<Void> handleIllegalArgument(IllegalArgumentException e) {
        return Result.error("参数错误: " + e.getMessage());
    }

    /**
     * 捕获运行时异常
     */
    @ExceptionHandler(RuntimeException.class)
    public Result<Void> handleRuntimeException(RuntimeException e) {
        e.printStackTrace();
        return Result.error("系统异常: " + e.getMessage());
    }

    /**
     * 捕获通用异常
     */
    @ExceptionHandler(Exception.class)
    public Result<Void> handleException(Exception e) {
        e.printStackTrace();
        return Result.error("服务器内部错误");
    }
}
