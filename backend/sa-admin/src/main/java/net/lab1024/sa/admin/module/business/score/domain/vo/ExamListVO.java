package net.lab1024.sa.admin.module.business.score.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import com.fasterxml.jackson.annotation.JsonFormat;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 教师端考试列表项。
 */
@Data
public class ExamListVO {
    @Schema(description = "考试 ID")
    private Long examId;
    @Schema(description = "学期 ID")
    private Long semesterId;
    @Schema(description = "课程 ID")
    private Long courseId;
    @Schema(description = "考试名称")
    private String examName;
    @Schema(description = "考试时间")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime examDate;
    @Schema(description = "总分")
    private BigDecimal totalScore;
    @Schema(description = "考试状态 [0:未开始,1:进行中,2:已结束]")
    private Integer examStatus;
    @Schema(description = "应考人数")
    private Long assignedCount;
    @Schema(description = "已完成人数")
    private Long completedCount;
}
