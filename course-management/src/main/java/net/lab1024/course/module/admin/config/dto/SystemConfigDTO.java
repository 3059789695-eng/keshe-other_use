package net.lab1024.course.module.admin.config.dto;

import lombok.Data;

/**
 * 系统配置 DTO
 */
@Data
public class SystemConfigDTO {

    /** 配置键 */
    private String configKey;

    /** 配置值（学期ID 或 课程ID） */
    private String configValue;
}
