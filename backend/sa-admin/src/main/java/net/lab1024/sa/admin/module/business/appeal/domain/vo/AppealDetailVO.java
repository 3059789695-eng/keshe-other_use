package net.lab1024.sa.admin.module.business.appeal.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import com.fasterxml.jackson.annotation.JsonFormat;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 成绩复议详情。
 */
@Data
public class AppealDetailVO {
    @Schema(description = "复议申请 ID")
    private Long appealId;
    @Schema(description = "答题记录 ID")
    private Long answerId;
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
    @Schema(description = "题目内容")
    private String questionContent;
    @Schema(description = "学生答案")
    private String studentAnswer;
    @Schema(description = "第三方评分结果")
    private BigDecimal aiScore;
    @Schema(description = "第三方评分说明")
    private String aiComment;
    @Schema(description = "最终得分")
    private BigDecimal finalScore;
    @Schema(description = "题目满分")
    private BigDecimal maxScore;
    @Schema(description = "考试总分")
    private BigDecimal examTotalScore;
    @Schema(description = "复议理由")
    private String appealReason;
    @Schema(description = "复议状态 [0:待处理,1:已通过,2:已驳回]")
    private Integer appealStatus;
    @Schema(description = "复议状态名称")
    private String appealStatusName;
    @Schema(description = "复议调整后的题目得分")
    private BigDecimal adjustedScore;
    @Schema(description = "教师处理意见")
    private String teacherOpinion;
    @Schema(description = "申请时间")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime applicationTime;
    @Schema(description = "处理时间")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime reviewTime;
}
