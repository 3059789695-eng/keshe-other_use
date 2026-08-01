/*
 * 文件：CourseOpeningMapper.java
 * 包路径：com.course.opening.mapper
 */
package com.course.opening.mapper;

import com.course.opening.entity.CourseOpening;
import com.course.opening.vo.CourseOpeningPageVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 开课 Dao，使用纯 MyBatis XML。
 */
@Mapper
public interface CourseOpeningMapper {
    CourseOpening selectById(@Param("id") Integer id);
    int insert(CourseOpening opening);
    int updateById(CourseOpening opening);
    int deleteById(@Param("id") Integer id);
    List<CourseOpeningPageVO> selectPage(@Param("offset") int offset,
                                         @Param("pageSize") int pageSize,
                                         @Param("courseName") String courseName,
                                         @Param("semesterId") Integer semesterId,
                                         @Param("semesterName") String semesterName,
                                         @Param("teacherName") String teacherName);
    long countPage(@Param("courseName") String courseName,
                   @Param("semesterId") Integer semesterId,
                   @Param("semesterName") String semesterName,
                   @Param("teacherName") String teacherName);
    Integer countByUnique(@Param("courseId") Integer courseId,
                          @Param("semesterId") Integer semesterId,
                          @Param("teacherId") Integer teacherId,
                          @Param("excludeId") Integer excludeId);
}
