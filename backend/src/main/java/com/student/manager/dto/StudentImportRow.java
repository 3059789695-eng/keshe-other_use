package com.student.manager.dto;
import com.alibaba.excel.annotation.ExcelProperty;
import lombok.Data;
@Data
public class StudentImportRow {
    @ExcelProperty("studentNo") private String studentNo;
    @ExcelProperty("name") private String name;
    @ExcelProperty("className") private String className;
}
