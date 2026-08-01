/*
 * 文件：CourseMapper.java
 * 包路径：com.course.opening.mapper
 */
package com.course.opening.mapper;

import com.course.opening.entity.Course;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 课程 Dao。
 */
@Mapper
public interface CourseMapper {
    Course selectById(@Param("id") Integer id);
    List<Course> selectAll();
}
