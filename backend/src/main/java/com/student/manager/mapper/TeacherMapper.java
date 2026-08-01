/*
 * 文件：TeacherMapper.java
 * 包路径：com.student.manager.mapper
 */
package com.student.manager.mapper;

import com.student.manager.dto.TeacherPageVO;
import com.student.manager.entity.Teacher;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 教师表 Dao，使用纯 MyBatis XML。
 */
@Mapper
public interface TeacherMapper {

    Teacher selectById(@Param("id") Integer id);

    int insert(Teacher teacher);

    int updateById(Teacher teacher);

    int deleteById(@Param("id") Integer id);

    List<TeacherPageVO> selectPage(@Param("offset") int offset,
                                   @Param("pageSize") int pageSize,
                                   @Param("teacherNo") String teacherNo,
                                   @Param("name") String name);

    long countPage(@Param("teacherNo") String teacherNo,
                   @Param("name") String name);

    Teacher selectByTeacherNo(@Param("teacherNo") String teacherNo);

    List<String> selectAllTeacherNos();

    Integer selectCountByUserId(@Param("userId") Integer userId);

    Integer selectOrgIdById(@Param("orgId") Integer orgId);

    List<Integer> selectUserIdsByName(@Param("name") String name);

    List<Integer> selectOrgIdsByName(@Param("name") String name);

    int batchInsertTeachers(@Param("list") List<Teacher> list);
}
