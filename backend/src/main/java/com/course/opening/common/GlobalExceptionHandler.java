/*
 * 文件：GlobalExceptionHandler.java
 * 包路径：com.course.opening.common
 */
package com.course.opening.common;

import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

/**
 * 全局异常处理，统一转换为 ResponseDTO。
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public ResponseDTO<Void> handleBusinessException(BusinessException ex) {
        return ResponseDTO.userErrorParam(ex.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseDTO<Void> handleMethodArgumentNotValid(MethodArgumentNotValidException ex) {
        FieldError fieldError = ex.getBindingResult().getFieldError();
        String message = fieldError == null ? "参数校验失败" : fieldError.getDefaultMessage();
        return ResponseDTO.userErrorParam(message);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseDTO<Void> handleConstraintViolation(ConstraintViolationException ex) {
        String message = ex.getConstraintViolations().stream()
                .findFirst()
                .map(violation -> violation.getMessage())
                .orElse("参数校验失败");
        return ResponseDTO.userErrorParam(message);
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseDTO<Void> handleTypeMismatch(MethodArgumentTypeMismatchException ex) {
        return ResponseDTO.userErrorParam("参数 " + ex.getName() + " 类型错误");
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseDTO<Void> handleMissingParam(MissingServletRequestParameterException ex) {
        return ResponseDTO.userErrorParam("缺少参数 " + ex.getParameterName());
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseDTO<Void> handleHttpMessageNotReadable(HttpMessageNotReadableException ex) {
        return ResponseDTO.userErrorParam("请求体格式错误");
    }

    @ExceptionHandler(DuplicateKeyException.class)
    public ResponseDTO<Void> handleDuplicateKey(DuplicateKeyException ex) {
        return ResponseDTO.userErrorParam("该开课记录已存在，请勿重复添加");
    }

    @ExceptionHandler(Exception.class)
    public ResponseDTO<Void> handleException(Exception ex) {
        log.error("系统异常", ex);
        return ResponseDTO.error("系统异常，请稍后重试");
    }
}
