package com.student.manager.dto;

import lombok.Data;

/**
 * 教师详情返回对象，用于编辑页回显。
 */
@Data
public class TeacherDetailVO {
    private Integer id;
    private String teacherNo;
    private Integer majorId;
}
