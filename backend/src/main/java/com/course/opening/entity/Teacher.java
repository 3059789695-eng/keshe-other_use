/*
 * 文件：Teacher.java
 * 包路径：com.course.opening.entity
 */
package com.course.opening.entity;

import lombok.Data;

/**
 * 教师表实体，id 同时关联 users 表主键。
 */
@Data
public class Teacher {
    private Integer id;
    private String teacherNo;
}
