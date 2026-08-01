package net.lab1024.course.module.admin.course.service.impl;

import net.lab1024.course.module.admin.course.dto.CourseAddDTO;
import net.lab1024.course.module.admin.course.dto.CourseEditDTO;
import net.lab1024.course.module.admin.course.entity.Course;
import net.lab1024.course.module.admin.course.mapper.CourseMapper;
import net.lab1024.course.module.admin.course.service.CourseService;
import net.lab1024.course.module.admin.course.vo.CourseVO;
import net.lab1024.course.module.admin.semester.entity.Semester;
import net.lab1024.course.module.admin.semester.mapper.SemesterMapper;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 课程 Service 实现类
 */
@Service
public class CourseServiceImpl implements CourseService {

    @Autowired
    private CourseMapper courseMapper;

    @Autowired
    private SemesterMapper semesterMapper;

    @Override
    public void addCourse(CourseAddDTO addDTO) {
        // 校验学期是否存在
        Semester semester = semesterMapper.selectById(addDTO.getSemesterId());
        if (semester == null) {
            throw new IllegalArgumentException("绑定的学期不存在");
        }
        Course course = new Course();
        BeanUtils.copyProperties(addDTO, course);
        courseMapper.insert(course);
    }

    @Override
    public void editCourse(CourseEditDTO editDTO) {
        Course course = courseMapper.selectById(editDTO.getId());
        if (course == null) {
            throw new IllegalArgumentException("课程不存在");
        }
        Semester semester = semesterMapper.selectById(editDTO.getSemesterId());
        if (semester == null) {
            throw new IllegalArgumentException("绑定的学期不存在");
        }
        BeanUtils.copyProperties(editDTO, course);
        courseMapper.updateById(course);
    }

    @Override
    public List<CourseVO> listCourses(Long semesterId) {
        List<Course> list;
        if (semesterId != null && semesterId > 0) {
            list = courseMapper.selectBySemesterId(semesterId);
        } else {
            list = courseMapper.selectList(null);
        }
        return list.stream().map(this::convertToVO).collect(Collectors.toList());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void toggleCourse(Long id, boolean enable) {
        Course course = courseMapper.selectById(id);
        if (course == null) {
            throw new IllegalArgumentException("课程不存在");
        }
        course.setIsDeleted(enable ? 0 : 1);
        courseMapper.updateById(course);
    }

    private CourseVO convertToVO(Course course) {
        CourseVO vo = new CourseVO();
        BeanUtils.copyProperties(course, vo);
        // 填充学期名称
        if (course.getSemesterId() != null) {
            Semester semester = semesterMapper.selectById(course.getSemesterId());
            if (semester != null) {
                vo.setSemesterName(semester.getSemesterName());
            }
        }
        return vo;
    }
}
