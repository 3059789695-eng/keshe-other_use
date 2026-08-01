/*
 * 文件：CourseOpeningServiceImpl.java
 * 包路径：com.course.opening.service.impl
 */
package com.course.opening.service.impl;

import com.course.opening.common.BusinessException;
import com.course.opening.common.PageResult;
import com.course.opening.common.ResponseDTO;
import com.course.opening.dto.CourseOpeningAddRequest;
import com.course.opening.dto.CourseOpeningPageQuery;
import com.course.opening.dto.CourseOpeningUpdateRequest;
import com.course.opening.entity.Course;
import com.course.opening.entity.CourseOpening;
import com.course.opening.entity.Semester;
import com.course.opening.mapper.CourseMapper;
import com.course.opening.mapper.CourseOpeningMapper;
import com.course.opening.mapper.OrganizationMapper;
import com.course.opening.mapper.SemesterMapper;
import com.course.opening.mapper.TeacherMapper;
import com.course.opening.service.CourseOpeningService;
import com.course.opening.vo.ClassOptionVO;
import com.course.opening.vo.CourseOpeningDetailVO;
import com.course.opening.vo.CourseOpeningPageVO;
import com.course.opening.vo.CourseOptionVO;
import com.course.opening.vo.SemesterOptionVO;
import com.course.opening.vo.TeacherOptionVO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 开课管理业务实现，使用纯 MyBatis。
 */
@Service
@RequiredArgsConstructor
public class CourseOpeningServiceImpl implements CourseOpeningService {

    private final CourseOpeningMapper courseOpeningMapper;
    private final CourseMapper courseMapper;
    private final SemesterMapper semesterMapper;
    private final TeacherMapper teacherMapper;
    private final OrganizationMapper organizationMapper;

    @Override
    public ResponseDTO<PageResult<CourseOpeningPageVO>> page(CourseOpeningPageQuery query) {
        int pageNum = query.getPageNum() == null ? 1 : query.getPageNum();
        int pageSize = query.getPageSize() == null ? 10 : query.getPageSize();
        int offset = (pageNum - 1) * pageSize;
        String courseName = trimToNull(query.getCourseName());
        Integer semesterId = query.getSemesterId();
        String semesterName = trimToNull(query.getSemesterName());
        String teacherName = trimToNull(query.getTeacherName());
        List<CourseOpeningPageVO> list = courseOpeningMapper.selectPage(
                offset, pageSize, courseName, semesterId, semesterName, teacherName);
        long total = courseOpeningMapper.countPage(courseName, semesterId, semesterName, teacherName);
        return ResponseDTO.ok(new PageResult<>(total, list));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ResponseDTO<Void> add(CourseOpeningAddRequest request) {
        checkCourseExists(request.getCourseId());
        checkSemesterExists(request.getSemesterId());
        checkTeacherExists(request.getTeacherId());
        if (hasDuplicate(request.getCourseId(), request.getSemesterId(), request.getTeacherId(), null)) {
            return ResponseDTO.userErrorParam("同一学期、同一课程、同一教师不能重复开课");
        }

        CourseOpening opening = new CourseOpening();
        opening.setCourseId(request.getCourseId());
        opening.setSemesterId(request.getSemesterId());
        opening.setTeacherId(request.getTeacherId());
        opening.setMaxStudents(request.getMaxStudents());
        courseOpeningMapper.insert(opening);
        return ResponseDTO.ok();
    }

    @Override
    public ResponseDTO<CourseOpeningDetailVO> getById(Integer id) {
        CourseOpening opening = courseOpeningMapper.selectById(id);
        if (opening == null) {
            return ResponseDTO.userErrorParam("开课记录不存在：" + id);
        }
        CourseOpeningDetailVO vo = new CourseOpeningDetailVO();
        vo.setId(opening.getId());
        vo.setCourseId(opening.getCourseId());
        vo.setSemesterId(opening.getSemesterId());
        vo.setTeacherId(opening.getTeacherId());
        vo.setMaxStudents(opening.getMaxStudents());
        return ResponseDTO.ok(vo);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ResponseDTO<Void> update(Integer id, CourseOpeningUpdateRequest request) {
        CourseOpening opening = courseOpeningMapper.selectById(id);
        if (opening == null) {
            return ResponseDTO.userErrorParam("开课记录不存在：" + id);
        }
        checkTeacherExists(request.getTeacherId());
        if (hasDuplicate(opening.getCourseId(), opening.getSemesterId(), request.getTeacherId(), id)) {
            return ResponseDTO.userErrorParam("同一学期、同一课程、同一教师不能重复开课");
        }
        opening.setTeacherId(request.getTeacherId());
        opening.setMaxStudents(request.getMaxStudents());
        courseOpeningMapper.updateById(opening);
        return ResponseDTO.ok();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ResponseDTO<Void> delete(Integer id) {
        if (courseOpeningMapper.selectById(id) == null) {
            return ResponseDTO.userErrorParam("开课记录不存在：" + id);
        }
        courseOpeningMapper.deleteById(id);
        return ResponseDTO.ok();
    }

    @Override
    public ResponseDTO<List<CourseOptionVO>> listCourses() {
        List<CourseOptionVO> list = courseMapper.selectAll().stream().map(course -> {
            CourseOptionVO vo = new CourseOptionVO();
            vo.setId(course.getId());
            vo.setCourseNo(course.getId() == null ? null : String.valueOf(course.getId()));
            vo.setCourseName(course.getTitle());
            return vo;
        }).collect(Collectors.toList());
        return ResponseDTO.ok(list);
    }

    @Override
    public ResponseDTO<List<SemesterOptionVO>> listSemesters() {
        List<SemesterOptionVO> list = semesterMapper.selectAll().stream().map(semester -> {
            SemesterOptionVO vo = new SemesterOptionVO();
            vo.setId(semester.getId());
            vo.setSemesterName(semester.getName());
            return vo;
        }).collect(Collectors.toList());
        return ResponseDTO.ok(list);
    }

    @Override
    public ResponseDTO<List<TeacherOptionVO>> listTeachers() {
        return ResponseDTO.ok(teacherMapper.selectTeacherOptions());
    }

    @Override
    public ResponseDTO<List<ClassOptionVO>> listClasses() {
        return ResponseDTO.ok(organizationMapper.selectClassOptions());
    }

    private boolean hasDuplicate(Integer courseId, Integer semesterId, Integer teacherId, Integer excludeId) {
        Integer count = courseOpeningMapper.countByUnique(courseId, semesterId, teacherId, excludeId);
        return count != null && count > 0;
    }

    private void checkCourseExists(Integer courseId) {
        if (courseMapper.selectById(courseId) == null) {
            throw new BusinessException("课程 ID [" + courseId + "] 在 courses 表中不存在");
        }
    }

    private void checkSemesterExists(Integer semesterId) {
        if (semesterMapper.selectById(semesterId) == null) {
            throw new BusinessException("学期 ID [" + semesterId + "] 在 semesters 表中不存在");
        }
    }

    private void checkTeacherExists(Integer teacherId) {
        if (teacherMapper.selectById(teacherId) == null) {
            throw new BusinessException("教师 ID [" + teacherId + "] 在 teachers 表中不存在");
        }
    }

    private String trimToNull(String value) {
        return StringUtils.hasText(value) ? value.trim() : null;
    }
}
