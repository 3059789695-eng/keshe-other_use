/*
 * 文件：CourseOpening.java
 * 包路径：com.course.opening.entity
 */
package com.course.opening.entity;

import lombok.Data;

/**
 * 开课表实体，对应现有 course_offerings 表结构。
 */
@Data
public class CourseOpening {
    private Integer id;
    private Integer courseId;
    private Integer semesterId;
    private Integer teacherId;
    private Integer maxStudents;
}
