/*
 * 文件：Course.java
 * 包路径：com.course.opening.entity
 */
package com.course.opening.entity;

import lombok.Data;

import java.math.BigDecimal;

/**
 * 课程表实体，对应现有 courses 表结构。
 */
@Data
public class Course {
    private Integer id;
    private String title;
    private BigDecimal credits;
}
