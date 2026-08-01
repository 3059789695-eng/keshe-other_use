package net.lab1024.course.module.teacher.chapter.vo;

import lombok.Data;

/**
 * 章节返回 VO（用于树形展示）
 */
@Data
public class ChapterVO {

    /** 章节ID */
    private Long id;

    /** 父章节ID */
    private Long parentId;

    /** 课程ID */
    private Long courseId;

    /** 章节名称 */
    private String chapterName;

    /** 排序号 */
    private Integer sort;

    /** 是否有子章节 */
    private Boolean hasChildren;

    /** 子章节数量 */
    private Integer childrenCount;
}
