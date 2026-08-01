/*
 * 文件：UserRoleMapper.java
 * 包路径：com.course.userrole.mapper
 */
package com.course.userrole.mapper;

import com.course.userrole.entity.UserRole;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 用户角色关联 Dao，使用纯 MyBatis XML。
 */
@Mapper
public interface UserRoleMapper {

    int deleteByUserId(@Param("userId") Long userId);

    int insertBatch(@Param("list") List<UserRole> list);

    List<Long> selectRoleIdsByUserId(@Param("userId") Long userId);
}
