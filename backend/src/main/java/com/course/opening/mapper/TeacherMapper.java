/*
 * 文件：TeacherMapper.java
 * 包路径：com.course.opening.mapper
 */
package com.course.opening.mapper;

import com.course.opening.entity.Teacher;
import com.course.opening.vo.TeacherOptionVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 教师 Dao。
 */
@Mapper
public interface TeacherMapper {
    Teacher selectById(@Param("id") Integer id);
    List<TeacherOptionVO> selectTeacherOptions();
}
