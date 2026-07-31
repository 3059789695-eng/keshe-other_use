package net.lab1024.sa.admin.module.business.score.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import net.lab1024.sa.admin.module.business.score.domain.entity.AnswerDetailEntity;
import org.apache.ibatis.annotations.Mapper;

/**
 * 答案详情 Dao
 */
@Mapper
public interface AnswerDetailDao extends BaseMapper<AnswerDetailEntity> {
}
