package com.student.manager.dto;
import lombok.Data;
import java.util.ArrayList;
import java.util.List;
@Data
public class ExcelImportResult {
    private int successCount;
    private int failCount;
    private List<ExcelImportError> errors = new ArrayList<>();
}
