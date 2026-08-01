/*
 * 文件：TeacherServiceImpl.java
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
import com.student.manager.dto.TeacherAddRequest;
import com.student.manager.dto.TeacherDetailVO;
import com.student.manager.dto.TeacherImportRow;
import com.student.manager.dto.TeacherPageQuery;
import com.student.manager.dto.TeacherPageVO;
import com.student.manager.dto.TeacherTemplateRow;
import com.student.manager.dto.TeacherUpdateRequest;
import com.student.manager.entity.Teacher;
import com.student.manager.mapper.TeacherMapper;
import com.student.manager.service.TeacherService;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * 教师管理业务实现，使用纯 MyBatis。
 */
@Service
public class TeacherServiceImpl implements TeacherService {

    @Resource
    private TeacherMapper teacherMapper;

    @Override
    public ResponseDTO<PageResult<TeacherPageVO>> pageQuery(TeacherPageQuery query) {
        int pageNum = query.getPageNum() == null ? 1 : query.getPageNum();
        int pageSize = query.getPageSize() == null ? 10 : query.getPageSize();
        int offset = (pageNum - 1) * pageSize;
        String teacherNo = normalize(query.getTeacherNo());
        String name = normalize(query.getName());
        List<TeacherPageVO> list = teacherMapper.selectPage(offset, pageSize, teacherNo, name);
        long total = teacherMapper.countPage(teacherNo, name);
        return ResponseDTO.ok(new PageResult<>(total, list));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ResponseDTO<Void> addTeacher(TeacherAddRequest request) {
        String teacherNo = normalize(request.getTeacherNo());
        if (teacherMapper.selectByTeacherNo(teacherNo) != null) {
            return ResponseDTO.userErrorParam("教师编号 [" + teacherNo + "] 已存在");
        }
        Integer userId = request.getId();
        Integer userCount = teacherMapper.selectCountByUserId(userId);
        if (userCount == null || userCount == 0) {
            return ResponseDTO.userErrorParam("用户 id [" + userId + "] 在 users 表中不存在");
        }
        if (teacherMapper.selectById(userId) != null) {
            return ResponseDTO.userErrorParam("用户 id [" + userId + "] 已关联教师");
        }
        Integer majorId = request.getMajorId();
        if (majorId == null || teacherMapper.selectOrgIdById(majorId) == null) {
            return ResponseDTO.userErrorParam("学院/专业 id [" + majorId + "] 在 organizations 表中不存在");
        }

        Teacher teacher = new Teacher();
        teacher.setId(userId);
        teacher.setTeacherNo(teacherNo);
        teacher.setMajorId(majorId);
        teacherMapper.insert(teacher);
        return ResponseDTO.ok();
    }

    @Override
    public ResponseDTO<TeacherDetailVO> getTeacherById(Integer id) {
        Teacher teacher = teacherMapper.selectById(id);
        if (teacher == null) {
            return ResponseDTO.userErrorParam("教师不存在，id=" + id);
        }
        TeacherDetailVO vo = new TeacherDetailVO();
        vo.setId(teacher.getId());
        vo.setTeacherNo(teacher.getTeacherNo());
        vo.setMajorId(teacher.getMajorId());
        return ResponseDTO.ok(vo);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ResponseDTO<Void> updateTeacher(TeacherUpdateRequest request) {
        Teacher teacher = teacherMapper.selectById(request.getId());
        if (teacher == null) {
            return ResponseDTO.userErrorParam("教师不存在，id=" + request.getId());
        }
        String teacherNo = normalize(request.getTeacherNo());
        Teacher exists = teacherMapper.selectByTeacherNo(teacherNo);
        if (exists != null && !exists.getId().equals(request.getId())) {
            return ResponseDTO.userErrorParam("教师编号 [" + teacherNo + "] 已被其他教师使用");
        }
        Integer majorId = request.getMajorId();
        if (majorId == null || teacherMapper.selectOrgIdById(majorId) == null) {
            return ResponseDTO.userErrorParam("学院/专业 id [" + majorId + "] 在 organizations 表中不存在");
        }

        teacher.setTeacherNo(teacherNo);
        teacher.setMajorId(majorId);
        teacherMapper.updateById(teacher);
        return ResponseDTO.ok();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ResponseDTO<Void> deleteTeacher(Integer id) {
        if (teacherMapper.selectById(id) == null) {
            return ResponseDTO.userErrorParam("教师不存在，id=" + id);
        }
        teacherMapper.deleteById(id);
        return ResponseDTO.ok();
    }

    @Override
    public void downloadTemplate(HttpServletResponse response) throws IOException {
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setCharacterEncoding("utf-8");
        String filename = URLEncoder.encode("教师信息导入模板", "UTF-8").replaceAll("\\+", "%20");
        response.setHeader("Content-Disposition", "attachment;filename*=utf-8''" + filename + ".xlsx");

        TeacherTemplateRow sample = new TeacherTemplateRow();
        sample.setTeacherNo("T2024001");
        sample.setName("张三");
        sample.setMajorName("计算机学院");
        EasyExcel.write(response.getOutputStream(), TeacherTemplateRow.class)
                .sheet("教师模板")
                .doWrite(Collections.singletonList(sample));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ResponseDTO<ExcelImportResult> importExcel(MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) {
            return ResponseDTO.userErrorParam("请上传 .xlsx 文件");
        }
        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || !originalFilename.toLowerCase(Locale.ROOT).endsWith(".xlsx")) {
            return ResponseDTO.userErrorParam("仅支持 .xlsx 格式文件");
        }

        ExcelImportResult result = new ExcelImportResult();
        List<TeacherImportRow> rows = new ArrayList<>();
        List<Integer> rowNumbers = new ArrayList<>();
        EasyExcel.read(file.getInputStream(), TeacherImportRow.class, new ReadListener<TeacherImportRow>() {
            @Override
            public void invoke(TeacherImportRow row, AnalysisContext context) {
                rows.add(row);
                rowNumbers.add(context.readRowHolder().getRowIndex() + 1);
            }

            @Override
            public void doAfterAllAnalysed(AnalysisContext context) {
                // EasyExcel 回调，无需额外处理
            }
        }).sheet().doRead();

        if (rows.isEmpty()) {
            return ResponseDTO.userErrorParam("Excel 文件为空或无有效数据行");
        }

        Set<String> existingTeacherNos = new HashSet<>(teacherMapper.selectAllTeacherNos());
        Set<String> batchTeacherNos = new HashSet<>();
        List<Teacher> validTeachers = new ArrayList<>();
        boolean hasValidData = false;

        for (int i = 0; i < rows.size(); i++) {
            TeacherImportRow row = rows.get(i);
            int rowNum = rowNumbers.get(i);
            if (isBlankRow(row)) {
                continue;
            }
            hasValidData = true;

            List<String> errors = new ArrayList<>();
            String teacherNo = normalize(row.getTeacherNo());
            if (!StringUtils.hasText(teacherNo)) {
                errors.add("教师编号不能为空");
            } else if (existingTeacherNos.contains(teacherNo)) {
                errors.add("教师编号 [" + teacherNo + "] 已存在");
            } else if (batchTeacherNos.contains(teacherNo)) {
                errors.add("教师编号 [" + teacherNo + "] 在文件中重复");
            }

            Integer userId = null;
            String name = normalize(row.getName());
            if (!StringUtils.hasText(name)) {
                errors.add("姓名不能为空");
            } else {
                List<Integer> userIds = teacherMapper.selectUserIdsByName(name);
                if (userIds.isEmpty()) {
                    errors.add("姓名 [" + name + "] 在 users 表中不存在");
                } else if (userIds.size() > 1) {
                    errors.add("姓名 [" + name + "] 对应多个用户");
                } else {
                    userId = userIds.get(0);
                    if (teacherMapper.selectById(userId) != null) {
                        errors.add("姓名 [" + name + "] 对应用户已关联教师");
                    }
                }
            }

            Integer majorId = null;
            String majorName = normalize(row.getMajorName());
            if (!StringUtils.hasText(majorName)) {
                errors.add("学院名称不能为空");
            } else {
                List<Integer> orgIds = teacherMapper.selectOrgIdsByName(majorName);
                if (orgIds.isEmpty()) {
                    errors.add("学院名称 [" + majorName + "] 在 organizations 表中不存在");
                } else if (orgIds.size() > 1) {
                    errors.add("学院名称 [" + majorName + "] 对应多个组织");
                } else {
                    majorId = orgIds.get(0);
                }
            }

            if (!errors.isEmpty()) {
                result.getErrors().add(new ExcelImportError(rowNum, String.join("；", errors)));
                result.setFailCount(result.getFailCount() + 1);
                continue;
            }

            Teacher teacher = new Teacher();
            teacher.setId(userId);
            teacher.setTeacherNo(teacherNo);
            teacher.setMajorId(majorId);
            validTeachers.add(teacher);
            existingTeacherNos.add(teacherNo);
            batchTeacherNos.add(teacherNo);
        }

        if (!hasValidData) {
            return ResponseDTO.userErrorParam("Excel 文件为空或无有效数据行");
        }
        if (!validTeachers.isEmpty()) {
            try {
                teacherMapper.batchInsertTeachers(validTeachers);
            } catch (DuplicateKeyException e) {
                return ResponseDTO.userErrorParam("导入数据与数据库冲突：教师编号或用户 id 重复");
            }
        }
        result.setSuccessCount(validTeachers.size());
        return ResponseDTO.ok(result);
    }

    private String normalize(String value) {
        return value == null ? null : value.trim();
    }

    private boolean isBlankRow(TeacherImportRow row) {
        return row == null
                || (!StringUtils.hasText(row.getTeacherNo())
                && !StringUtils.hasText(row.getName())
                && !StringUtils.hasText(row.getMajorName()));
    }
}
