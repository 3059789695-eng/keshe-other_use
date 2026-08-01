package net.lab1024.course.module.admin.semester.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 学期实体类
 */
@Data
@TableName("semester")
public class Semester {

    /** 学期ID（主键，自增） */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 学期名称 */
    private String semesterName;

    /** 开始日期 */
    private LocalDate startDate;

    /** 结束日期 */
    private LocalDate endDate;

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
