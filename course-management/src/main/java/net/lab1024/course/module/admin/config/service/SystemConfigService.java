package net.lab1024.course.module.admin.config.service;

import net.lab1024.course.module.admin.config.vo.SystemConfigVO;

/**
 * 系统配置 Service 接口
 */
public interface SystemConfigService {

    /**
     * 设置当前生效学期
     * 全局唯一：设置新学期后，旧的自动失效
     */
    void setActiveSemester(Long semesterId);

    /**
     * 设置当前生效课程
     */
    void setActiveCourse(Long courseId);

    /**
     * 查询当前生效配置
     * 公共接口，教师和管理员均可调用
     */
    SystemConfigVO getActiveConfig();
}
