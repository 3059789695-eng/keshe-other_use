package net.lab1024.sa.admin.module.business.score.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;

import lombok.Data;

/**
 * 成绩分数段统计。
 */
@Data
public class ScoreRangeVO {
    @Schema(description = "分数段")
    private String scoreRange;
    @Schema(description = "学生人数")
    private Long studentCount;
}
