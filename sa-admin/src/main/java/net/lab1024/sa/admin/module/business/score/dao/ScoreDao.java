package net.lab1024.sa.admin.module.business.score.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import net.lab1024.sa.admin.module.business.score.domain.entity.ScoreEntity;
import org.apache.ibatis.annotations.Mapper;

/**
 * 成绩 Dao
 */
@Mapper
public interface ScoreDao extends BaseMapper<ScoreEntity> {
}
