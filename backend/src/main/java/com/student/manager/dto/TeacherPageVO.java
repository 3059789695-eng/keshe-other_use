package com.student.manager.dto;

import lombok.Data;

/**
 * 教师分页列表返回对象。
 */
@Data
public class TeacherPageVO {
    private Integer id;
    private String teacherNo;
    private String name;
    private Integer majorId;
    private String majorName;
}
