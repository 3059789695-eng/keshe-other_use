package net.lab1024.course.module.admin.config.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import net.lab1024.course.module.admin.config.entity.SystemConfig;
import net.lab1024.course.module.admin.config.mapper.SystemConfigMapper;
import net.lab1024.course.module.admin.config.service.SystemConfigService;
import net.lab1024.course.module.admin.config.vo.SystemConfigVO;
import net.lab1024.course.module.admin.course.entity.Course;
import net.lab1024.course.module.admin.course.mapper.CourseMapper;
import net.lab1024.course.module.admin.semester.entity.Semester;
import net.lab1024.course.module.admin.semester.mapper.SemesterMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 系统配置 Service 实现类
 */
@Service
public class SystemConfigServiceImpl implements SystemConfigService {

    /** 配置键：当前生效学期 */
    private static final String KEY_ACTIVE_SEMESTER = "active_semester";

    /** 配置键：当前生效课程 */
    private static final String KEY_ACTIVE_COURSE = "active_course";

    @Autowired
    private SystemConfigMapper systemConfigMapper;

    @Autowired
    private SemesterMapper semesterMapper;

    @Autowired
    private CourseMapper courseMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void setActiveSemester(Long semesterId) {
        // 校验学期是否存在
        Semester semester = semesterMapper.selectById(semesterId);
        if (semester == null) {
            throw new IllegalArgumentException("学期不存在");
        }
        // 保存或更新配置（全局唯一）
        saveOrUpdateConfig(KEY_ACTIVE_SEMESTER, String.valueOf(semesterId));
        // 切换学期后，当前课程自动清空
        saveOrUpdateConfig(KEY_ACTIVE_COURSE, "");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void setActiveCourse(Long courseId) {
        // 校验课程是否存在
        Course course = courseMapper.selectById(courseId);
        if (course == null) {
            throw new IllegalArgumentException("课程不存在");
        }
        saveOrUpdateConfig(KEY_ACTIVE_COURSE, String.valueOf(courseId));
    }

    @Override
    public SystemConfigVO getActiveConfig() {
        SystemConfigVO vo = new SystemConfigVO();

        // 查询生效学期
        SystemConfig semesterConfig = systemConfigMapper.selectByConfigKey(KEY_ACTIVE_SEMESTER);
        if (semesterConfig != null && !semesterConfig.getConfigValue().isEmpty()) {
            Long semesterId = Long.valueOf(semesterConfig.getConfigValue());
            Semester semester = semesterMapper.selectById(semesterId);
            if (semester != null) {
                vo.setSemesterId(semester.getId());
                vo.setSemesterName(semester.getSemesterName());
            }
        }

        // 查询生效课程
        SystemConfig courseConfig = systemConfigMapper.selectByConfigKey(KEY_ACTIVE_COURSE);
        if (courseConfig != null && !courseConfig.getConfigValue().isEmpty()) {
            Long courseId = Long.valueOf(courseConfig.getConfigValue());
            Course course = courseMapper.selectById(courseId);
            if (course != null) {
                vo.setCourseId(course.getId());
                vo.setCourseName(course.getCourseName());
            }
        }

        return vo;
    }

    /**
     * 保存或更新配置
     */
    private void saveOrUpdateConfig(String key, String value) {
        SystemConfig config = systemConfigMapper.selectByConfigKey(key);
        if (config == null) {
            config = new SystemConfig();
            config.setConfigKey(key);
            config.setConfigValue(value);
            systemConfigMapper.insert(config);
        } else {
            config.setConfigValue(value);
            systemConfigMapper.updateById(config);
        }
    }
}
