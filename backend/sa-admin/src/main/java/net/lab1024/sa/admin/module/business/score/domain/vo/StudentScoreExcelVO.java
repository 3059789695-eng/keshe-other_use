package net.lab1024.sa.admin.module.business.score.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import com.fasterxml.jackson.annotation.JsonFormat;

import cn.idev.excel.annotation.ExcelProperty;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 全部学生成绩导出行。
 */
@Data
public class StudentScoreExcelVO {
    @ExcelProperty("学号")
    @Schema(description = "学号")
    private String studentNo;
    @ExcelProperty("姓名")
    @Schema(description = "学生姓名")
    private String studentName;
    @ExcelProperty("完成状态")
    @Schema(description = "完成状态名称")
    private String completionStatusName;
    @ExcelProperty("提交时间")
    @Schema(description = "提交时间")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime submitTime;
    @ExcelProperty("总分")
    @Schema(description = "总分")
    private BigDecimal totalScore;
}
