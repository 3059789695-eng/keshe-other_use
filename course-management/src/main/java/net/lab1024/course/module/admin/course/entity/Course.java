package net.lab1024.course.module.admin.course.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 课程实体类
 */
@Data
@TableName("course")
public class Course {

    /** 课程ID（主键，自增） */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 课程名称 */
    private String courseName;

    /** 课程编码 */
    private String courseCode;

    /** 学分 */
    private Integer credit;

    /** 关联学期ID */
    private Long semesterId;

    /** 逻辑删除：0=正常（启用），1=删除（禁用） */
    @TableLogic
    private Integer isDeleted;

    /** 创建时间（自动填充） */
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    /** 更新时间（自动填充） */
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;
}
