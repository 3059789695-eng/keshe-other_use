package net.lab1024.sa.admin.module.business.score.domain.vo;

import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 历史成绩 VO
 */
@Data
public class ScoreHistoryVO {

    @Schema(description = "成绩 ID")
    private Long scoreId;

    @Schema(description = "考试 ID")
    private Long examId;

    @Schema(description = "考试标题")
    private String examTitle;

    @Schema(description = "课程名称")
    private String courseName;

    @Schema(description = "学期名称")
    private String semesterName;

    @Schema(description = "总分")
    private BigDecimal totalScore;

    @Schema(description = "及格状态 [0:不及格,1:及格]")
    private Integer passStatus;

    @Schema(description = "及格状态文本")
    private String passStatusText;

    @Schema(description = "排名")
    private Integer rankPosition;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "交卷时间")
    private LocalDateTime submitTime;

    @Schema(description = "是否有复议记录")
    private Boolean hasAppeal;
}
