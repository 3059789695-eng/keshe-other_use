package net.lab1024.course.module.teacher.chapter.dto;

import lombok.Data;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

/**
 * 添加章节 DTO（既可添加顶级章节，也可添加子章节）
 */
@Data
public class ChapterAddDTO {

    /** 课程ID（添加顶级章节时必填） */
    private Long courseId;

    /** 父章节ID（添加子章节时必填，顶级章节为 0） */
    @NotNull(message = "父章节ID不能为空，顶级章节请传 0")
    private Long parentId;

    /** 章节名称 */
    @NotBlank(message = "章节名称不能为空")
    private String chapterName;
}
