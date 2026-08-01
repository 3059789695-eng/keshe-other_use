/*
 * 文件：CourseOpeningAddRequest.java
 * 包路径：com.course.opening.dto
 */
package com.course.opening.dto;

import lombok.Data;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

/**
 * 新增开课入参。
 */
@Data
public class CourseOpeningAddRequest {

    @NotNull(message = "课程 ID 不能为空")
    @Positive(message = "课程 ID 必须为正整数")
    private Integer courseId;

    @NotNull(message = "学期 ID 不能为空")
    @Positive(message = "学期 ID 必须为正整数")
    private Integer semesterId;

    @NotNull(message = "教师 ID 不能为空")
    @Positive(message = "教师 ID 必须为正整数")
    private Integer teacherId;

    @NotNull(message = "最大选课人数不能为空")
    @Positive(message = "最大选课人数必须大于 0")
    private Integer maxStudents;
}
