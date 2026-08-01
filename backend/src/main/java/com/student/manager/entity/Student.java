/*
 * 文件：Student.java
 * 包路径：com.student.manager.entity
 */
package com.student.manager.entity;

import lombok.Data;

/**
 * 学生扩展表实体，对应 students 表。
 */
@Data
public class Student {
    private Integer id;
    private String studentNo;
    private Integer classId;
    private String name;
    private String className;
}
