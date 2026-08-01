package net.lab1024.course.module.admin.course.controller;

import net.lab1024.course.common.result.Result;
import net.lab1024.course.module.admin.course.dto.CourseAddDTO;
import net.lab1024.course.module.admin.course.dto.CourseEditDTO;
import net.lab1024.course.module.admin.course.service.CourseService;
import net.lab1024.course.module.admin.course.vo.CourseVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;

/**
 * 管理员端 - 课程管理 Controller
 *
 * 接口前缀：/api/admin/semester-course/course
 * 角色要求：请求头 role=admin
 */
@RestController
@RequestMapping("/api/admin/semester-course/course")
public class CourseController {

    @Autowired
    private CourseService courseService;

    /**
     * 新增课程
     * POST /api/admin/semester-course/course/add
     */
    @PostMapping("/add")
    public Result<Void> addCourse(@Valid @RequestBody CourseAddDTO addDTO) {
        courseService.addCourse(addDTO);
        return Result.success();
    }

    /**
     * 编辑课程
     * PUT /api/admin/semester-course/course/edit
     */
    @PutMapping("/edit")
    public Result<Void> editCourse(@Valid @RequestBody CourseEditDTO editDTO) {
        courseService.editCourse(editDTO);
        return Result.success();
    }

    /**
     * 查询课程下拉列表（可按学期筛选）
     * GET /api/admin/semester-course/course/list?semesterId=1
     */
    @GetMapping("/list")
    public Result<List<CourseVO>> listCourses(@RequestParam(required = false) Long semesterId) {
        List<CourseVO> list = courseService.listCourses(semesterId);
        return Result.success(list);
    }

    /**
     * 禁用/启用课程
     * PUT /api/admin/semester-course/course/toggle?id=1&enable=false
     */
    @PutMapping("/toggle")
    public Result<Void> toggleCourse(@RequestParam Long id, @RequestParam boolean enable) {
        courseService.toggleCourse(id, enable);
        return Result.success(enable ? "课程已启用" : "课程已禁用", null);
    }
}
