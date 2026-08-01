package net.lab1024.course.module.admin.course.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import net.lab1024.course.module.admin.course.entity.Course;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 课程 Mapper 接口
 */
@Mapper
public interface CourseMapper extends BaseMapper<Course> {

    /**
     * 根据学期ID查询所有课程列表
     */
    @Select("SELECT * FROM course WHERE semester_id = #{semesterId} AND is_deleted = 0 ORDER BY create_time DESC")
    List<Course> selectBySemesterId(@Param("semesterId") Long semesterId);
}
