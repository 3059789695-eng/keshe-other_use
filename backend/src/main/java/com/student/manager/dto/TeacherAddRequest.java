package com.student.manager.dto;

import lombok.Data;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * 新增教师请求参数。
 */
@Data
public class TeacherAddRequest {
    @NotNull(message = "教师 id 不能为空")
    private Integer id;

    @NotBlank(message = "教师编号不能为空")
    private String teacherNo;

    @NotNull(message = "学院/专业 id 不能为空")
    private Integer majorId;
}
