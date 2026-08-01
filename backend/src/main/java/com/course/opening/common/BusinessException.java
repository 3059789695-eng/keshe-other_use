/*
 * 文件：BusinessException.java
 * 包路径：com.course.opening.common
 */
package com.course.opening.common;

/**
 * 业务异常，用于主动返回可读错误信息。
 */
public class BusinessException extends RuntimeException {

    public BusinessException(String message) {
        super(message);
    }
}
