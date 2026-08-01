/*
 * 文件：CourseOpeningController.java
 * 包路径：com.course.opening.controller
 */
package com.course.opening.controller;

import com.course.opening.common.PageResult;
import com.course.opening.common.ResponseDTO;
import com.course.opening.dto.CourseOpeningAddRequest;
import com.course.opening.dto.CourseOpeningPageQuery;
import com.course.opening.dto.CourseOpeningUpdateRequest;
import com.course.opening.service.CourseOpeningService;
import com.course.opening.vo.ClassOptionVO;
import com.course.opening.vo.CourseOpeningDetailVO;
import com.course.opening.vo.CourseOpeningPageVO;
import com.course.opening.vo.CourseOptionVO;
import com.course.opening.vo.SemesterOptionVO;
import com.course.opening.vo.TeacherOptionVO;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.RequiredArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 开课管理接口，对应 T-11。
 */
@Validated
@RestController
@RequestMapping("/api/course-opening")
@RequiredArgsConstructor
public class CourseOpeningController {

    private final CourseOpeningService courseOpeningService;

    @GetMapping("/page")
    public ResponseDTO<PageResult<CourseOpeningPageVO>> page(@Valid CourseOpeningPageQuery query) {
        return courseOpeningService.page(query);
    }

    @PostMapping
    public ResponseDTO<Void> add(@Valid @RequestBody CourseOpeningAddRequest request) {
        return courseOpeningService.add(request);
    }

    @GetMapping("/{id}")
    public ResponseDTO<CourseOpeningDetailVO> detail(
            @PathVariable("id")
            @NotNull(message = "开课 ID 不能为空")
            @Positive(message = "开课 ID 必须为正整数")
            Integer id) {
        return courseOpeningService.getById(id);
    }

    @PutMapping("/{id}")
    public ResponseDTO<Void> update(
            @PathVariable("id")
            @NotNull(message = "开课 ID 不能为空")
            @Positive(message = "开课 ID 必须为正整数")
            Integer id,
            @Valid @RequestBody CourseOpeningUpdateRequest request) {
        return courseOpeningService.update(id, request);
    }

    @DeleteMapping("/{id}")
    public ResponseDTO<Void> delete(
            @PathVariable("id")
            @NotNull(message = "开课 ID 不能为空")
            @Positive(message = "开课 ID 必须为正整数")
            Integer id) {
        return courseOpeningService.delete(id);
    }

    @GetMapping("/courses")
    public ResponseDTO<List<CourseOptionVO>> courses() {
        return courseOpeningService.listCourses();
    }

    @GetMapping("/semesters")
    public ResponseDTO<List<SemesterOptionVO>> semesters() {
        return courseOpeningService.listSemesters();
    }

    @GetMapping("/teachers")
    public ResponseDTO<List<TeacherOptionVO>> teachers() {
        return courseOpeningService.listTeachers();
    }

    @GetMapping("/classes")
    public ResponseDTO<List<ClassOptionVO>> classes() {
        return courseOpeningService.listClasses();
    }
}
