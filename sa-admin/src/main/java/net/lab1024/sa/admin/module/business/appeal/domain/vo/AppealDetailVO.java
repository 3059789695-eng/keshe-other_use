package net.lab1024.sa.admin.module.business.appeal.domain.vo;

import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 复议详情 VO（查看复议详情弹窗）
 */
@Data
public class AppealDetailVO {

    @Schema(description = "复议 ID")
    private Long appealId;

    @Schema(description = "成绩 ID")
    private Long scoreId;

    @Schema(description = "考试 ID")
    private Long examId;

    @Schema(description = "考试标题")
    private String examTitle;

    @Schema(description = "考试时间")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime examStartTime;

    @Schema(description = "学生 ID")
    private Long studentId;

    @Schema(description = "学生姓名")
    private String studentName;

    // ===== 原题目及作答 =====

    @Schema(description = "题目内容")
    private String questionContent;

    @Schema(description = "题目满分")
    private BigDecimal questionMaxScore;

    @Schema(description = "学生答案")
    private String studentAnswer;

    // ===== 复议信息 =====

    @Schema(description = "复议理由")
    private String appealReason;

    @Schema(description = "证据截图 URL 列表")
    private List<String> evidenceUrls;

    // ===== 评分明细 =====

    @Schema(description = "评分要点")
    private String scorePoints;

    @Schema(description = "扣分依据")
    private String deductReason;

    @Schema(description = "对应分值")
    private String pointValue;

    @Schema(description = "原得分")
    private BigDecimal oldScore;

    @Schema(description = "复议后得分")
    private BigDecimal newScore;

    // ===== 处理信息 =====

    @Schema(description = "状态 [1:待审核,2:已通过,3:已驳回]")
    private Integer status;

    @Schema(description = "状态文本")
    private String statusText;

    @Schema(description = "教师处理意见")
    private String teacherRemark;

    @Schema(description = "处理教师姓名")
    private String teacherName;

    @Schema(description = "申请时间")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createTime;

    @Schema(description = "处理时间")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime handleTime;

    // ===== 底部状态栏信息 =====

    @Schema(description = "原考试成绩（总分）")
    private BigDecimal totalExamScore;

    @Schema(description = "当前题目成绩")
    private String currentQuestionScore;

    @Schema(description = "申请状态文字")
    private String appealStatus;
}
