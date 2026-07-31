package net.lab1024.sa.admin.module.business.appeal.domain.vo;

import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 复议记录列表项 VO（B区：复议进度列表）
 */
@Data
public class AppealVO {

    @Schema(description = "复议 ID")
    private Long appealId;

    @Schema(description = "成绩 ID")
    private Long scoreId;

    @Schema(description = "答案详情 ID")
    private Long answerDetailId;

    @Schema(description = "考试 ID")
    private Long examId;

    @Schema(description = "考试标题")
    private String examTitle;

    @Schema(description = "学生 ID")
    private Long studentId;

    @Schema(description = "学生姓名")
    private String studentName;

    @Schema(description = "题目内容（截断显示）")
    private String questionContent;

    @Schema(description = "复议理由（截断显示）")
    private String appealReason;

    @Schema(description = "状态 [1:待审核,2:已通过,3:已驳回]")
    private Integer status;

    @Schema(description = "状态文本")
    private String statusText;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "申请时间")
    private LocalDateTime createTime;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "处理时间")
    private LocalDateTime handleTime;
}
