/*
 * 文件：CourseOpeningPageQuery.java
 * 包路径：com.course.opening.dto
 */
package com.course.opening.dto;

import lombok.Data;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

/**
 * 开课分页查询参数。
 */
@Data
public class CourseOpeningPageQuery {

    @Min(value = 1, message = "pageNum 必须大于 0")
    private Integer pageNum = 1;

    @Min(value = 1, message = "pageSize 必须大于 0")
    @Max(value = 100, message = "pageSize 不能超过 100")
    private Integer pageSize = 10;

    private String courseName;

    private Integer semesterId;

    private String semesterName;

    private String teacherName;
}
