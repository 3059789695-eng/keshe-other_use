package net.lab1024.course.module.admin.config.vo;

import lombok.Data;

/**
 * 当前生效配置 VO
 */
@Data
public class SystemConfigVO {

    /** 生效学期ID */
    private Long semesterId;

    /** 生效学期名称 */
    private String semesterName;

    /** 生效课程ID */
    private Long courseId;

    /** 生效课程名称 */
    private String courseName;
}
