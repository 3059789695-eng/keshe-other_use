package com.student.manager.dto;

import lombok.Data;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

/**
 * 教师分页查询参数。
 */
@Data
public class TeacherPageQuery {
    @Min(value = 1, message = "pageNum 不能小于 1")
    private Integer pageNum = 1;

    @Min(value = 1, message = "pageSize 不能小于 1")
    @Max(value = 100, message = "pageSize 不能大于 100")
    private Integer pageSize = 10;

    /** 教师编号模糊查询 */
    private String teacherNo;

    /** 姓名模糊查询 */
    private String name;
}
