/*
 * 文件：StudentController.java
 * 包路径：com.student.manager.controller
 */
package com.student.manager.controller;

import com.student.manager.common.PageResult;
import com.student.manager.common.ResponseDTO;
import com.student.manager.dto.ExcelImportResult;
import com.student.manager.dto.StudentAddRequest;
import com.student.manager.dto.StudentDetailVO;
import com.student.manager.dto.StudentPageQuery;
import com.student.manager.dto.StudentPageVO;
import com.student.manager.dto.StudentUpdateRequest;
import com.student.manager.service.StudentService;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

/**
 * 学生管理接口，对应 A-01。
 */
@RestController
@RequestMapping("/api/student")
public class StudentController {

    @Resource
    private StudentService studentService;

    @GetMapping("/page")
    public ResponseDTO<PageResult<StudentPageVO>> page(@Valid StudentPageQuery query) {
        return studentService.pageQuery(query);
    }

    @PostMapping("/add")
    public ResponseDTO<Void> add(@Valid @RequestBody StudentAddRequest request) {
        return studentService.addStudent(request);
    }

    @GetMapping("/{id}")
    public ResponseDTO<StudentDetailVO> getById(@PathVariable Integer id) {
        return studentService.getStudentById(id);
    }

    @PutMapping("/update")
    public ResponseDTO<Void> update(@Valid @RequestBody StudentUpdateRequest request) {
        return studentService.updateStudent(request);
    }

    @DeleteMapping("/{id}")
    public ResponseDTO<Void> delete(@PathVariable Integer id) {
        return studentService.deleteStudent(id);
    }

    @GetMapping("/template")
    public void downloadTemplate(HttpServletResponse response) throws IOException {
        studentService.downloadTemplate(response);
    }

    @PostMapping("/import")
    public ResponseDTO<ExcelImportResult> importExcel(@RequestParam("file") MultipartFile file) throws IOException {
        return studentService.importExcel(file);
    }
}
