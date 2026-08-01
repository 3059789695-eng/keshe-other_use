package net.lab1024.sa.admin.module.business.score.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import com.fasterxml.jackson.annotation.JsonFormat;

import cn.idev.excel.annotation.ExcelProperty;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 未完成学生导出行。
 */
@Data
public class UnfinishedStudentExcelVO {
    @ExcelProperty("学号")
    @Schema(description = "学号")
    private String studentNo;
    @ExcelProperty("姓名")
    @Schema(description = "学生姓名")
    private String studentName;
    @ExcelProperty("当前状态")
    @Schema(description = "完成状态名称")
    private String completionStatusName;
    @ExcelProperty("最后活动时间")
    @Schema(description = "最后活动时间")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime lastActiveTime;
}
