/*
 * 文件：SemesterMapper.java
 * 包路径：com.course.opening.mapper
 */
package com.course.opening.mapper;

import com.course.opening.entity.Semester;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 学期 Dao。
 */
@Mapper
public interface SemesterMapper {
    Semester selectById(@Param("id") Integer id);
    List<Semester> selectAll();
}
