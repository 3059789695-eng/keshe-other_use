package net.lab1024.sa.admin.module.business.appeal.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import net.lab1024.sa.admin.module.business.appeal.domain.entity.AppealEntity;
import org.apache.ibatis.annotations.Mapper;

/**
 * 复议申请 Dao
 */
@Mapper
public interface AppealDao extends BaseMapper<AppealEntity> {
}
