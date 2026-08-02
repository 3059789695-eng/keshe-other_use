package net.lab1024.sa.admin.module.business.score.dao;

import net.lab1024.sa.admin.module.business.score.domain.entity.ScoreEntity;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 成绩 Dao（纯 MyBatis）
 */
@Mapper
public interface ScoreDao {

    int insert(ScoreEntity entity);

    int updateById(ScoreEntity entity);

    ScoreEntity selectById(Long scoreId);

    ScoreEntity selectByExamIdAndStudent(@Param("examId") Long examId,
                                          @Param("studentId") Long studentId);

    List<ScoreEntity> selectByStudentId(Long studentId);
}
