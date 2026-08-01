/*
 * 文件：StudentServiceImpl.java
 * 包路径：com.student.manager.service.impl
 */
package com.student.manager.service.impl;

import com.alibaba.excel.EasyExcel;
import com.alibaba.excel.context.AnalysisContext;
import com.alibaba.excel.read.listener.ReadListener;
import com.student.manager.common.PageResult;
import com.student.manager.common.ResponseDTO;
import com.student.manager.dto.ExcelImportError;
import com.student.manager.dto.ExcelImportResult;
import com.student.manager.dto.StudentAddRequest;
import com.student.manager.dto.StudentDetailVO;
import com.student.manager.dto.StudentImportRow;
import com.student.manager.dto.StudentPageQuery;
import com.student.manager.dto.StudentPageVO;
import com.student.manager.dto.StudentTemplateRow;
import com.student.manager.dto.StudentUpdateRequest;
import com.student.manager.entity.Student;
import com.student.manager.mapper.StudentMapper;
import com.student.manager.service.StudentService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * 学生管理业务实现，使用纯 MyBatis。
 */
@Service
public class StudentServiceImpl implements StudentService {

    @Resource
    private StudentMapper studentMapper;

    @Override
    public ResponseDTO<PageResult<StudentPageVO>> pageQuery(StudentPageQuery query) {
        int pageNum = query.getPageNum() == null ? 1 : query.getPageNum();
        int pageSize = query.getPageSize() == null ? 10 : query.getPageSize();
        int offset = (pageNum - 1) * pageSize;
        String studentNo = normalize(query.getStudentNo());
        String name = normalize(query.getName());
        List<StudentPageVO> list = studentMapper.selectPage(offset, pageSize, studentNo, name, query.getClassId());
        long total = studentMapper.countPage(studentNo, name, query.getClassId());
        return ResponseDTO.ok(new PageResult<>(total, list));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ResponseDTO<Void> addStudent(StudentAddRequest request) {
        Student exist = studentMapper.selectByStudentNo(request.getStudentNo());
        if (exist != null) {
            return ResponseDTO.userErrorParam("学号 [" + request.getStudentNo() + "] 已存在");
        }
        Integer cnt = studentMapper.selectCountByUserId(request.getId());
        if (cnt == null || cnt == 0) {
            return ResponseDTO.userErrorParam("用户 ID [" + request.getId() + "] 在 users 表中不存在");
        }
        if (request.getClassId() != null && studentMapper.selectOrgIdById(request.getClassId()) == null) {
            return ResponseDTO.userErrorParam("班级 ID [" + request.getClassId() + "] 不存在");
        }

        Student student = new Student();
        student.setId(request.getId());
        student.setStudentNo(request.getStudentNo());
        student.setClassId(request.getClassId());
        studentMapper.insert(student);
        return ResponseDTO.ok();
    }

    @Override
    public ResponseDTO<StudentDetailVO> getStudentById(Integer id) {
        Student student = studentMapper.selectById(id);
        if (student == null) {
            return ResponseDTO.userErrorParam("学生不存在，id=" + id);
        }
        StudentDetailVO vo = new StudentDetailVO();
        vo.setId(student.getId());
        vo.setStudentNo(student.getStudentNo());
        vo.setClassId(student.getClassId());
        return ResponseDTO.ok(vo);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ResponseDTO<Void> updateStudent(StudentUpdateRequest request) {
        Student student = studentMapper.selectById(request.getId());
        if (student == null) {
            return ResponseDTO.userErrorParam("学生不存在，id=" + request.getId());
        }
        Student exist = studentMapper.selectByStudentNo(request.getStudentNo());
        if (exist != null && !exist.getId().equals(request.getId())) {
            return ResponseDTO.userErrorParam("学号 [" + request.getStudentNo() + "] 已被其他学生使用");
        }
        if (request.getClassId() != null && studentMapper.selectOrgIdById(request.getClassId()) == null) {
            return ResponseDTO.userErrorParam("班级 ID [" + request.getClassId() + "] 不存在");
        }

        student.setStudentNo(request.getStudentNo());
        student.setClassId(request.getClassId());
        studentMapper.updateById(student);
        return ResponseDTO.ok();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ResponseDTO<Void> deleteStudent(Integer id) {
        if (studentMapper.selectById(id) == null) {
            return ResponseDTO.userErrorParam("学生不存在，id=" + id);
        }
        studentMapper.deleteById(id);
        return ResponseDTO.ok();
    }

    @Override
    public void downloadTemplate(HttpServletResponse response) throws IOException {
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setCharacterEncoding("utf-8");
        String fn = URLEncoder.encode("student_template", "UTF-8").replaceAll("\\+", "%20");
        response.setHeader("Content-Disposition", "attachment;filename*=utf-8''" + fn + ".xlsx");
        List<StudentTemplateRow> list = new ArrayList<>();
        StudentTemplateRow row = new StudentTemplateRow();
        row.setStudentNo("2024001");
        row.setName("张三");
        row.setClassName("计算机2401班");
        list.add(row);
        EasyExcel.write(response.getOutputStream(), StudentTemplateRow.class).sheet("学生模板").doWrite(list);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ResponseDTO<ExcelImportResult> importExcel(MultipartFile file) throws IOException {
        ExcelImportResult result = new ExcelImportResult();
        List<StudentImportRow> rows = new ArrayList<>();
        EasyExcel.read(file.getInputStream(), StudentImportRow.class, new ReadListener<StudentImportRow>() {
            @Override
            public void invoke(StudentImportRow row, AnalysisContext context) {
                rows.add(row);
            }

            @Override
            public void doAfterAllAnalysed(AnalysisContext context) {
                // EasyExcel 回调，无需额外处理
            }
        }).sheet().doRead();
        if (rows.isEmpty()) {
            return ResponseDTO.userErrorParam("Excel 文件为空");
        }

        Set<String> existingNos = new HashSet<>(studentMapper.selectAllStudentNos());
        Set<String> batchNos = new HashSet<>();
        List<Student> valid = new ArrayList<>();

        for (int i = 0; i < rows.size(); i++) {
            StudentImportRow row = rows.get(i);
            int rowNum = i + 2;
            List<String> errors = new ArrayList<>();

            String studentNo = normalize(row.getStudentNo());
            if (studentNo == null || studentNo.isEmpty()) {
                errors.add("学号不能为空");
            } else if (existingNos.contains(studentNo)) {
                errors.add("学号 [" + studentNo + "] 已存在");
            } else if (batchNos.contains(studentNo)) {
                errors.add("学号 [" + studentNo + "] 在文件中重复");
            }

            String name = normalize(row.getName());
            Integer userId = null;
            if (name == null || name.isEmpty()) {
                errors.add("姓名不能为空");
            } else {
                List<Integer> ids = studentMapper.selectUserIdByName(name);
                if (ids.isEmpty()) {
                    errors.add("姓名 [" + name + "] 在 users 表中不存在");
                } else if (ids.size() > 1) {
                    errors.add("姓名 [" + name + "] 对应多个用户");
                } else {
                    userId = ids.get(0);
                    if (studentMapper.selectById(userId) != null) {
                        errors.add("用户 [" + name + "] 已关联学生");
                    }
                }
            }

            Integer classId = null;
            String className = normalize(row.getClassName());
            if (className != null && !className.isEmpty()) {
                classId = studentMapper.selectOrgIdByName(className);
                if (classId == null) {
                    errors.add("班级名称 [" + className + "] 不存在");
                }
            }

            if (!errors.isEmpty()) {
                result.getErrors().add(new ExcelImportError(rowNum, String.join("；", errors)));
                result.setFailCount(result.getFailCount() + 1);
            } else {
                Student student = new Student();
                student.setId(userId);
                student.setStudentNo(studentNo);
                student.setClassId(classId);
                valid.add(student);
                existingNos.add(studentNo);
                batchNos.add(studentNo);
            }
        }

        if (!valid.isEmpty()) {
            studentMapper.batchInsertStudents(valid);
            result.setSuccessCount(valid.size());
        }
        return ResponseDTO.ok(result);
    }

    private String normalize(String value) {
        return value == null ? null : value.trim();
    }
}
