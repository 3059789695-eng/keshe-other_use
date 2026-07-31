package net.lab1024.sa.admin.module.business.score.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import net.lab1024.sa.admin.module.business.score.domain.entity.StudentAnswerEntity;
import org.apache.ibatis.annotations.Mapper;

/**
 * 学生作答记录 Dao
 */
@Mapper
public interface StudentAnswerDao extends BaseMapper<StudentAnswerEntity> {
}
