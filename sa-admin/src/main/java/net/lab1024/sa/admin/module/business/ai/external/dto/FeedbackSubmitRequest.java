package net.lab1024.sa.admin.module.business.ai.external.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * Python AI 提交整体学习建议
 */
@Data
public class FeedbackSubmitRequest {

    @Schema(description = "考试 ID", example = "10")
    @NotNull(message = "考试 ID 不能为空")
    private Long examId;

    @Schema(description = "学生 ID", example = "2001")
    @NotNull(message = "学生 ID 不能为空")
    private Long studentId;

    @Schema(description = "总体评价（30-80字）", example = "整体表现良好，基础知识点掌握较牢固")
    @NotBlank(message = "总体评价不能为空")
    private String overallComment;

    @Schema(description = "亮点（知识掌握好的方面）", example = "对核心概念的把握较为准确，答题结构清晰")
    private String highlights;

    @Schema(description = "薄弱点（知识掌握不足的方面）", example = "部分论述题的展开不够深入")
    private String weaknesses;

    @Schema(description = "改进建议（具体可操作的学习指导）", example = "1. 逐章梳理知识点，构建知识图谱；2. 每周完成2-3道论述题练习")
    private String improvementSuggestions;
}
