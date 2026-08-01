package com.student.manager.service;

import com.student.manager.common.PageResult;
import com.student.manager.common.ResponseDTO;
import com.student.manager.dto.*;
import org.springframework.web.multipart.MultipartFile;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

public interface StudentService {
    ResponseDTO<PageResult<StudentPageVO>> pageQuery(StudentPageQuery query);
    ResponseDTO<Void> addStudent(StudentAddRequest request);
    ResponseDTO<StudentDetailVO> getStudentById(Integer id);
    ResponseDTO<Void> updateStudent(StudentUpdateRequest request);
    ResponseDTO<Void> deleteStudent(Integer id);
    void downloadTemplate(HttpServletResponse response) throws IOException;
    ResponseDTO<ExcelImportResult> importExcel(MultipartFile file) throws IOException;
}
