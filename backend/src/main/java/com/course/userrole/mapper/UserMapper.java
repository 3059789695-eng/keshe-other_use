/*
 * 文件：UserMapper.java
 * 包路径：com.course.userrole.mapper
 */
package com.course.userrole.mapper;

import com.course.userrole.entity.User;
import com.course.userrole.vo.UserRolePageVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 用户 Dao，使用纯 MyBatis XML。
 */
@Mapper
public interface UserMapper {

    User selectById(@Param("id") Long id);

    List<UserRolePageVO> selectUserPage(@Param("offset") int offset,
                                        @Param("pageSize") int pageSize,
                                        @Param("username") String username,
                                        @Param("name") String name);

    long countUserPage(@Param("username") String username,
                       @Param("name") String name);
}
