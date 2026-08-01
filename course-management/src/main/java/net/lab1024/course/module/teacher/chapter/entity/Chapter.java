package net.lab1024.course.module.teacher.chapter.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 课程章节实体类
 * 支持无限层级树形结构（通过 parent_id 实现）
 */
@Data
@TableName("teacher_chapter")
public class Chapter {

    /** 章节ID（主键，自增） */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 父章节ID，顶级章节为 0 */
    private Long parentId;

    /** 所属课程ID */
    private Long courseId;

    /** 章节名称 */
    private String chapterName;

    /** 排序号，数值越大越靠后 */
    private Integer sort;

    /** 逻辑删除：0=正常，1=删除 */
    @TableLogic
    private Integer isDeleted;

    /** 创建时间（自动填充） */
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    /** 更新时间（自动填充） */
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;
}
