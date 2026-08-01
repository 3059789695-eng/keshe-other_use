package net.lab1024.course.module.admin.semester.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import net.lab1024.course.module.admin.semester.entity.Semester;
import org.apache.ibatis.annotations.Mapper;

/**
 * 学期 Mapper 接口
 */
@Mapper
public interface SemesterMapper extends BaseMapper<Semester> {
}
