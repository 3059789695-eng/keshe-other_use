/*
 * 文件：CourseOpeningUpdateRequest.java
 * 包路径：com.course.opening.dto
 */
package com.course.opening.dto;

import lombok.Data;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

/**
 * 编辑开课入参，仅允许修改教师、班级和最大选课人数。
 */
@Data
public class CourseOpeningUpdateRequest {

    @NotNull(message = "教师 ID 不能为空")
    @Positive(message = "教师 ID 必须为正整数")
    private Integer teacherId;

    @NotNull(message = "最大选课人数不能为空")
    @Positive(message = "最大选课人数必须大于 0")
    private Integer maxStudents;
}
