package com.student.manager.dto;
import lombok.AllArgsConstructor;
import lombok.Data;
@Data
@AllArgsConstructor
public class ExcelImportError {
    private Integer rowNum;
    private String reason;
}
