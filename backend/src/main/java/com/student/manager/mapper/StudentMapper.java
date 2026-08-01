/*
 * 文件：StudentMapper.java
 * 包路径：com.student.manager.mapper
 */
package com.student.manager.mapper;

import com.student.manager.dto.StudentPageVO;
import com.student.manager.entity.Student;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 学生表 Dao，使用纯 MyBatis XML。
 */
@Mapper
public interface StudentMapper {

    Student selectById(@Param("id") Integer id);

    int insert(Student student);

    int updateById(Student student);

    int deleteById(@Param("id") Integer id);

    List<StudentPageVO> selectPage(@Param("offset") int offset,
                                   @Param("pageSize") int pageSize,
                                   @Param("studentNo") String studentNo,
                                   @Param("name") String name,
                                   @Param("classId") Integer classId);

    long countPage(@Param("studentNo") String studentNo,
                   @Param("name") String name,
                   @Param("classId") Integer classId);

    Student selectByStudentNo(@Param("studentNo") String studentNo);

    List<String> selectAllStudentNos();

    List<Integer> selectUserIdByName(@Param("name") String name);

    Integer selectOrgIdByName(@Param("name") String name);

    Integer selectCountByUserId(@Param("userId") Integer userId);

    Integer selectOrgIdById(@Param("orgId") Integer orgId);

    int batchInsertStudents(@Param("list") List<Student> list);
}
