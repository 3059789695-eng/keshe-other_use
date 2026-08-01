package com.student.manager.dto;

import com.alibaba.excel.annotation.ExcelProperty;
import lombok.Data;

/**
 * 教师 Excel 导入行。
 */
@Data
public class TeacherImportRow {
    @ExcelProperty("教师编号")
    private String teacherNo;

    @ExcelProperty("姓名")
    private String name;

    @ExcelProperty("学院名称")
    private String majorName;
}
