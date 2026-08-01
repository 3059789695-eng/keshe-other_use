package net.lab1024.course.module.admin.course.vo;

import lombok.Data;
import java.time.LocalDateTime;

/**
 * 课程返回 VO
 */
@Data
public class CourseVO {

    /** 课程ID */
    private Long id;

    /** 课程名称 */
    private String courseName;

    /** 课程编码 */
    private String courseCode;

    /** 学分 */
    private Integer credit;

    /** 关联学期ID */
    private Long semesterId;

    /** 学期名称（冗余展示） */
    private String semesterName;

    /** 是否启用（0=禁用/已删除，1=启用） */
    private Integer isDeleted;

    /** 创建时间 */
    private LocalDateTime createTime;
}
