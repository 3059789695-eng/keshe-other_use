/*
 * 文件：GlobalExceptionHandler.java
 * 包路径：com.student.manager.common
 */
package com.student.manager.common;

import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.util.stream.Collectors;

/**
 * 全局异常处理，统一转换为 ResponseDTO。
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseDTO<Void> handleValidation(MethodArgumentNotValidException e) {
        String msg = e.getBindingResult().getFieldErrors().stream()
                .map(FieldError::getDefaultMessage)
                .collect(Collectors.joining("; "));
        return ResponseDTO.userErrorParam(msg);
    }

    @ExceptionHandler(DuplicateKeyException.class)
    public ResponseDTO<Void> handleDuplicateKey(DuplicateKeyException e) {
        return ResponseDTO.userErrorParam("数据重复，请勿重复提交");
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseDTO<Void> handleIllegalArg(IllegalArgumentException e) {
        return ResponseDTO.userErrorParam(e.getMessage());
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseDTO<Void> handleTypeMismatch(MethodArgumentTypeMismatchException e) {
        return ResponseDTO.userErrorParam("参数 " + e.getName() + " 类型错误");
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseDTO<Void> handleMissingParam(MissingServletRequestParameterException e) {
        return ResponseDTO.userErrorParam("缺少参数 " + e.getParameterName());
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseDTO<Void> handleHttpMessageNotReadable(HttpMessageNotReadableException e) {
        return ResponseDTO.userErrorParam("请求体格式错误");
    }

    @ExceptionHandler(Exception.class)
    public ResponseDTO<Void> handleGeneric(Exception e) {
        e.printStackTrace();
        return ResponseDTO.error("系统异常，请稍后重试");
    }
}
