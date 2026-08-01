package net.lab1024.sa.admin.module.business.score.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import com.fasterxml.jackson.annotation.JsonFormat;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 学生完成情况与成绩列表项。
 */
@Data
public class StudentScoreVO {
    @Schema(description = "考试记录 ID")
    private Long examRecordId;
    @Schema(description = "学生 ID")
    private Long studentId;
    @Schema(description = "学号")
    private String studentNo;
    @Schema(description = "学生姓名")
    private String studentName;
    @Schema(description = "完成状态 [0:未开始,1:进行中,2:已提交]")
    private Integer completionStatus;
    @Schema(description = "完成状态名称")
    private String completionStatusName;
    @Schema(description = "最后活动时间")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime lastActiveTime;
    @Schema(description = "提交时间")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime submitTime;
    @Schema(description = "总分")
    private BigDecimal totalScore;
}
