package net.lab1024.sa.admin.module.business.score.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import com.fasterxml.jackson.annotation.JsonFormat;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 学生完整答卷。
 */
@Data
public class StudentAnswerDetailVO {
    @Schema(description = "考试记录 ID")
    private Long examRecordId;
    @Schema(description = "考试 ID")
    private Long examId;
    @Schema(description = "考试名称")
    private String examName;
    @Schema(description = "学生 ID")
    private Long studentId;
    @Schema(description = "学号")
    private String studentNo;
    @Schema(description = "学生姓名")
    private String studentName;
    @Schema(description = "提交时间")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime submitTime;
    @Schema(description = "总分")
    private BigDecimal totalScore;
    @Schema(description = "答题明细")
    private List<AnswerItemVO> answerList;
}
