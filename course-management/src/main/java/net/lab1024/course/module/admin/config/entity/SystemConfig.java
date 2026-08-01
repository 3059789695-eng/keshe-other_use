package net.lab1024.course.module.admin.config.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 系统配置实体类
 * 存储当前生效学期和当前生效课程
 */
@Data
@TableName("system_config")
public class SystemConfig {

    /** 主键ID（自增） */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 配置键 */
    private String configKey;

    /** 配置值 */
    private String configValue;

    /** 配置描述 */
    private String configDesc;

    /** 创建时间（自动填充） */
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    /** 更新时间（自动填充） */
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;
}
