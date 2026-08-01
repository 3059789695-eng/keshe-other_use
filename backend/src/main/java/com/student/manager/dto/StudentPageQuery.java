package com.student.manager.dto;
import lombok.Data;
@Data
public class StudentPageQuery {
    private Integer pageNum = 1;
    private Integer pageSize = 10;
    private String studentNo;
    private String name;
    private Integer classId;
}
