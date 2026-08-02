package net.lab1024.sa.admin.module.business.score.dao;

import net.lab1024.sa.admin.module.business.score.domain.entity.StudentAnswerEntity;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 学生作答记录 Dao（纯 MyBatis）
 */
@Mapper
public interface StudentAnswerDao {

    int updateById(StudentAnswerEntity entity);

    StudentAnswerEntity selectById(Long answerId);

    StudentAnswerEntity selectByExamIdAndStudent(@Param("examId") Long examId,
                                                  @Param("studentId") Long studentId);

    List<StudentAnswerEntity> selectByAnswerIds(@Param("answerIds") List<Long> answerIds);
}
