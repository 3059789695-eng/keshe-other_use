/*
 * 文件：Semester.java
 * 包路径：com.course.opening.entity
 */
package com.course.opening.entity;

import lombok.Data;

/**
 * 学期表实体，对应现有 semesters 表结构。
 */
@Data
public class Semester {
    private Integer id;
    private String name;
}
