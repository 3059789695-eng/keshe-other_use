/*
 * 文件：TeacherOptionVO.java
 * 包路径：com.course.opening.vo
 */
package com.course.opening.vo;

import lombok.Data;

/**
 * 教师下拉选项，teacherNo 对应 teachers.teacher_no，name 对应 users.name。
 */
@Data
public class TeacherOptionVO {

    private Integer id;
    private String teacherNo;
    private String name;
}
