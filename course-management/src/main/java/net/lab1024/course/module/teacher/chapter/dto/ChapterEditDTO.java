package net.lab1024.course.module.teacher.chapter.dto;

import lombok.Data;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

/**
 * 编辑章节 DTO
 */
@Data
public class ChapterEditDTO {

    /** 章节ID */
    @NotNull(message = "章节ID不能为空")
    private Long id;

    /** 新的章节名称 */
    @NotBlank(message = "章节名称不能为空")
    private String chapterName;
}
