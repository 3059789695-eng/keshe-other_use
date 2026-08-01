/*
 * 文件：Teacher.java
 * 包路径：com.student.manager.entity
 */
package com.student.manager.entity;

import lombok.Data;

/**
 * 教师扩展表实体，对应 teachers 表。
 */
@Data
public class Teacher {
    private Integer id;
    private String teacherNo;
    private Integer majorId;
}
