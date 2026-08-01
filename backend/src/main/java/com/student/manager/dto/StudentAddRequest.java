package com.student.manager.dto;
import lombok.Data;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
@Data
public class StudentAddRequest {
    @NotNull(message = "student id required")
    private Integer id;
    @NotBlank(message = "studentNo required")
    private String studentNo;
    private Integer classId;
}
