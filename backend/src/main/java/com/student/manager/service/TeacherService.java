package com.student.manager.service;

import com.student.manager.common.PageResult;
import com.student.manager.common.ResponseDTO;
import com.student.manager.dto.ExcelImportResult;
import com.student.manager.dto.TeacherAddRequest;
import com.student.manager.dto.TeacherDetailVO;
import com.student.manager.dto.TeacherPageQuery;
import com.student.manager.dto.TeacherPageVO;
import com.student.manager.dto.TeacherUpdateRequest;
import org.springframework.web.multipart.MultipartFile;

import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * 教师信息维护服务接口。
 */
public interface TeacherService {

    ResponseDTO<PageResult<TeacherPageVO>> pageQuery(TeacherPageQuery query);

    ResponseDTO<Void> addTeacher(TeacherAddRequest request);

    ResponseDTO<TeacherDetailVO> getTeacherById(Integer id);

    ResponseDTO<Void> updateTeacher(TeacherUpdateRequest request);

    ResponseDTO<Void> deleteTeacher(Integer id);

    void downloadTemplate(HttpServletResponse response) throws IOException;

    ResponseDTO<ExcelImportResult> importExcel(MultipartFile file) throws IOException;
}
