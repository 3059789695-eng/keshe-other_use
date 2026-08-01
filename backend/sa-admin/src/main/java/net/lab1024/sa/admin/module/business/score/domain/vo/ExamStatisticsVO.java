package net.lab1024.sa.admin.module.business.score.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;

import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

/**
 * 考试成绩统计结果。
 */
@Data
public class ExamStatisticsVO {
    @Schema(description = "考试 ID")
    private Long examId;
    @Schema(description = "考试名称")
    private String examName;
    @Schema(description = "总分")
    private BigDecimal totalScore;
    @Schema(description = "及格分")
    private BigDecimal passScore;
    @Schema(description = "应考人数")
    private Long assignedCount;
    @Schema(description = "实际参加人数")
    private Long participantCount;
    @Schema(description = "平均分")
    private BigDecimal averageScore;
    @Schema(description = "最高分")
    private BigDecimal highestScore;
    @Schema(description = "最低分")
    private BigDecimal lowestScore;
    @Schema(description = "及格率")
    private BigDecimal passRate;
    @Schema(description = "分数段分布")
    private List<ScoreRangeVO> scoreDistribution;
}
