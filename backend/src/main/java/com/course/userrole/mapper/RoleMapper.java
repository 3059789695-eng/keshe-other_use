/*
 * 文件：RoleMapper.java
 * 包路径：com.course.userrole.mapper
 */
package com.course.userrole.mapper;

import com.course.userrole.entity.Role;
import com.course.userrole.vo.RoleVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 角色 Dao，使用纯 MyBatis XML。
 */
@Mapper
public interface RoleMapper {

    Role selectById(@Param("id") Long id);

    List<RoleVO> selectAllRoles();
}
