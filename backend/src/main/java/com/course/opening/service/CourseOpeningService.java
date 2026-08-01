/*
 * 文件：CourseOpeningService.java
 * 包路径：com.course.opening.service
 */
package com.course.opening.service;

import com.course.opening.common.PageResult;
import com.course.opening.common.ResponseDTO;
import com.course.opening.dto.CourseOpeningAddRequest;
import com.course.opening.dto.CourseOpeningPageQuery;
import com.course.opening.dto.CourseOpeningUpdateRequest;
import com.course.opening.vo.ClassOptionVO;
import com.course.opening.vo.CourseOpeningDetailVO;
import com.course.opening.vo.CourseOpeningPageVO;
import com.course.opening.vo.CourseOptionVO;
import com.course.opening.vo.SemesterOptionVO;
import com.course.opening.vo.TeacherOptionVO;

import java.util.List;

/**
 * 开课管理业务接口，对应 T-11。
 */
public interface CourseOpeningService {
    ResponseDTO<PageResult<CourseOpeningPageVO>> page(CourseOpeningPageQuery query);
    ResponseDTO<Void> add(CourseOpeningAddRequest request);
    ResponseDTO<CourseOpeningDetailVO> getById(Integer id);
    ResponseDTO<Void> update(Integer id, CourseOpeningUpdateRequest request);
    ResponseDTO<Void> delete(Integer id);
    ResponseDTO<List<CourseOptionVO>> listCourses();
    ResponseDTO<List<SemesterOptionVO>> listSemesters();
    ResponseDTO<List<TeacherOptionVO>> listTeachers();
    ResponseDTO<List<ClassOptionVO>> listClasses();
}
