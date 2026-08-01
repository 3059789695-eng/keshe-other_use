/*
 * 文件：TeacherController.java
 * 包路径：com.student.manager.controller
 */
package com.student.manager.controller;

import com.student.manager.common.PageResult;
import com.student.manager.common.ResponseDTO;
import com.student.manager.dto.ExcelImportResult;
import com.student.manager.dto.TeacherAddRequest;
import com.student.manager.dto.TeacherDetailVO;
import com.student.manager.dto.TeacherPageQuery;
import com.student.manager.dto.TeacherPageVO;
import com.student.manager.dto.TeacherUpdateRequest;
import com.student.manager.service.TeacherService;
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
 * 教师管理接口，对应 A-02。
 */
@RestController
@RequestMapping("/api/teacher")
public class TeacherController {

    @Resource
    private TeacherService teacherService;

    @GetMapping("/page")
    public ResponseDTO<PageResult<TeacherPageVO>> page(@Valid TeacherPageQuery query) {
        return teacherService.pageQuery(query);
    }

    @PostMapping("/add")
    public ResponseDTO<Void> add(@Valid @RequestBody TeacherAddRequest request) {
        return teacherService.addTeacher(request);
    }

    @GetMapping("/{id}")
    public ResponseDTO<TeacherDetailVO> getById(@PathVariable Integer id) {
        return teacherService.getTeacherById(id);
    }

    @PutMapping("/update")
    public ResponseDTO<Void> update(@Valid @RequestBody TeacherUpdateRequest request) {
        return teacherService.updateTeacher(request);
    }

    @DeleteMapping("/{id}")
    public ResponseDTO<Void> delete(@PathVariable Integer id) {
        return teacherService.deleteTeacher(id);
    }

    @GetMapping("/template")
    public void downloadTemplate(HttpServletResponse response) throws IOException {
        teacherService.downloadTemplate(response);
    }

    @PostMapping("/import")
    public ResponseDTO<ExcelImportResult> importExcel(@RequestParam("file") MultipartFile file) throws IOException {
        return teacherService.importExcel(file);
    }
}
