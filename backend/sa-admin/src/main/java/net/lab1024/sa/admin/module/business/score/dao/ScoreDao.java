package net.lab1024.sa.admin.module.business.score.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.math.BigDecimal;

/**
 * 成绩写操作数据访问接口。
 */
@Mapper
public interface ScoreDao {

    int updateAnswerScore(@Param("answerId") Long answerId, @Param("adjustedScore") BigDecimal adjustedScore);

    int recalculateExamScore(@Param("answerId") Long answerId);
}
