package net.lab1024.course.module.admin.course.service;

import net.lab1024.course.module.admin.course.dto.CourseAddDTO;
import net.lab1024.course.module.admin.course.dto.CourseEditDTO;
import net.lab1024.course.module.admin.course.vo.CourseVO;

import java.util.List;

/**
 * 课程 Service 接口
 */
public interface CourseService {

    /**
     * 新增课程
     */
    void addCourse(CourseAddDTO addDTO);

    /**
     * 编辑课程
     */
    void editCourse(CourseEditDTO editDTO);

    /**
     * 查询课程下拉列表，可按学期ID筛选
     */
    List<CourseVO> listCourses(Long semesterId);

    /**
     * 禁用/启用课程
     */
    void toggleCourse(Long id, boolean enable);
}
