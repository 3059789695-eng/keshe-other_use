package net.lab1024.sa.admin.module.business.score.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * AI 整体学习建议 VO
 */
@Data
public class ScoreAiFeedbackVO {

    @Schema(description = "总体评价（30-80字）")
    private String overallComment;

    @Schema(description = "亮点（知识掌握好的方面）")
    private String highlights;

    @Schema(description = "薄弱点（知识掌握不足的方面）")
    private String weaknesses;

    @Schema(description = "改进建议（具体可操作的学习指导）")
    private String improvementSuggestions;

    @Schema(description = "三维度总评")
    private DimensionSummary dimensionSummary;

    @Data
    public static class DimensionSummary {

        @Schema(description = "相关性平均分")
        private Double relevanceAvg;

        @Schema(description = "知识点覆盖度平均分")
        private Double coverageAvg;

        @Schema(description = "逻辑表达性平均分")
        private Double logicAvg;
    }
}
