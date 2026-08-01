package net.lab1024.sa.admin.module.business.appeal.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import com.fasterxml.jackson.annotation.JsonFormat;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 成绩复议列表项。
 */
@Data
public class AppealVO {
    @Schema(description = "复议申请 ID")
    private Long appealId;
    @Schema(description = "考试 ID")
    private Long examId;
    @Schema(description = "考试名称")
    private String examName;
    @Schema(description = "学号")
    private String studentNo;
    @Schema(description = "学生姓名")
    private String studentName;
    @Schema(description = "题目内容")
    private String questionContent;
    @Schema(description = "复议状态 [0:待处理,1:已通过,2:已驳回]")
    private Integer appealStatus;
    @Schema(description = "复议状态名称")
    private String appealStatusName;
    @Schema(description = "申请时间")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime applicationTime;
    @Schema(description = "处理时间")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime reviewTime;
}
