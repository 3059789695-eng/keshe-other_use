package net.lab1024.course.module.admin.config.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import net.lab1024.course.module.admin.config.entity.SystemConfig;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 系统配置 Mapper 接口
 */
@Mapper
public interface SystemConfigMapper extends BaseMapper<SystemConfig> {

    /**
     * 根据配置键查询配置
     */
    @Select("SELECT * FROM system_config WHERE config_key = #{configKey} LIMIT 1")
    SystemConfig selectByConfigKey(@Param("configKey") String configKey);
}
