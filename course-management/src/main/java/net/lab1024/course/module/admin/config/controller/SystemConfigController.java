package net.lab1024.course.module.admin.config.controller;

import net.lab1024.course.common.result.Result;
import net.lab1024.course.module.admin.config.service.SystemConfigService;
import net.lab1024.course.module.admin.config.vo.SystemConfigVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * 系统配置 Controller
 *
 * 管理员接口前缀：/api/admin/semester-course/config（需要 role=admin）
 * 公共接口前缀：/api/common/config（教师和管理员都可调用）
 */
@RestController
public class SystemConfigController {

    @Autowired
    private SystemConfigService systemConfigService;

    /**
     * 设置当前生效学期
     * PUT /api/admin/semester-course/config/semester?semesterId=1
     */
    @PutMapping("/api/admin/semester-course/config/semester")
    public Result<Void> setActiveSemester(@RequestParam Long semesterId) {
        systemConfigService.setActiveSemester(semesterId);
        return Result.success("生效学期设置成功", null);
    }

    /**
     * 设置当前生效课程
     * PUT /api/admin/semester-course/config/course?courseId=1
     */
    @PutMapping("/api/admin/semester-course/config/course")
    public Result<Void> setActiveCourse(@RequestParam Long courseId) {
        systemConfigService.setActiveCourse(courseId);
        return Result.success("生效课程设置成功", null);
    }

    /**
     * 查询当前生效配置（公共接口，教师和管理员都可调用）
     * GET /api/common/config
     */
    @GetMapping("/api/common/config")
    public Result<SystemConfigVO> getActiveConfig() {
        SystemConfigVO config = systemConfigService.getActiveConfig();
        return Result.success(config);
    }
}
