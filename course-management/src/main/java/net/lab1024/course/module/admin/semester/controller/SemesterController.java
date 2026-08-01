package net.lab1024.course.module.admin.semester.controller;

import net.lab1024.course.common.result.Result;
import net.lab1024.course.module.admin.semester.dto.SemesterAddDTO;
import net.lab1024.course.module.admin.semester.dto.SemesterEditDTO;
import net.lab1024.course.module.admin.semester.service.SemesterService;
import net.lab1024.course.module.admin.semester.vo.SemesterVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;

/**
 * 管理员端 - 学期管理 Controller
 *
 * 接口前缀：/api/admin/semester-course/semester
 * 角色要求：请求头 role=admin
 */
@RestController
@RequestMapping("/api/admin/semester-course/semester")
public class SemesterController {

    @Autowired
    private SemesterService semesterService;

    /**
     * 新增学期
     * POST /api/admin/semester-course/semester/add
     */
    @PostMapping("/add")
    public Result<Void> addSemester(@Valid @RequestBody SemesterAddDTO addDTO) {
        semesterService.addSemester(addDTO);
        return Result.success();
    }

    /**
     * 编辑学期
     * PUT /api/admin/semester-course/semester/edit
     */
    @PutMapping("/edit")
    public Result<Void> editSemester(@Valid @RequestBody SemesterEditDTO editDTO) {
        semesterService.editSemester(editDTO);
        return Result.success();
    }

    /**
     * 查询学期下拉列表
     * GET /api/admin/semester-course/semester/list
     */
    @GetMapping("/list")
    public Result<List<SemesterVO>> listSemesters() {
        List<SemesterVO> list = semesterService.listSemesters();
        return Result.success(list);
    }

    /**
     * 禁用/启用学期
     * PUT /api/admin/semester-course/semester/toggle?id=1&enable=false
     */
    @PutMapping("/toggle")
    public Result<Void> toggleSemester(@RequestParam Long id, @RequestParam boolean enable) {
        semesterService.toggleSemester(id, enable);
        return Result.success(enable ? "学期已启用" : "学期已禁用", null);
    }
}
