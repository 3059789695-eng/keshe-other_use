package net.lab1024.course.module.admin.course.dto;

import lombok.Data;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

/**
 * 新增课程 DTO
 */
@Data
public class CourseAddDTO {

    /** 课程名称 */
    @NotBlank(message = "课程名称不能为空")
    private String courseName;

    /** 课程编码 */
    @NotBlank(message = "课程编码不能为空")
    private String courseCode;

    /** 学分 */
    @NotNull(message = "学分不能为空")
    private Integer credit;

    /** 绑定学期ID */
    @NotNull(message = "学期ID不能为空")
    private Long semesterId;
}
