package net.lab1024.sa.admin.module.business.score.dao;

import net.lab1024.sa.admin.module.business.score.domain.entity.AnswerDetailEntity;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * 答案详情 Dao（纯 MyBatis）
 */
@Mapper
public interface AnswerDetailDao {

    int updateById(AnswerDetailEntity entity);

    AnswerDetailEntity selectById(Long id);

    List<AnswerDetailEntity> selectByAnswerId(Long answerId);

    /**
     * 查询待批改的外部服务答案（grade_type=2 且 score IS NULL）
     */
    List<AnswerDetailEntity> selectUngradedExternal();
}
