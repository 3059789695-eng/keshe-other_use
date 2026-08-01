/*
 * 文件：UserRoleServiceImpl.java
 * 包路径：com.course.userrole.service.impl
 */
package com.course.userrole.service.impl;

import com.course.userrole.common.PageResult;
import com.course.userrole.common.ResponseDTO;
import com.course.userrole.entity.UserRole;
import com.course.userrole.mapper.RoleMapper;
import com.course.userrole.mapper.UserMapper;
import com.course.userrole.mapper.UserRoleMapper;
import com.course.userrole.service.UserRoleService;
import com.course.userrole.vo.RoleVO;
import com.course.userrole.vo.UserRolePageVO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * 用户角色分配业务实现，使用纯 MyBatis。
 */
@Service
@RequiredArgsConstructor
public class UserRoleServiceImpl implements UserRoleService {

    private final UserMapper userMapper;
    private final RoleMapper roleMapper;
    private final UserRoleMapper userRoleMapper;

    @Override
    public ResponseDTO<List<RoleVO>> listAllRoles() {
        return ResponseDTO.ok(roleMapper.selectAllRoles());
    }

    @Override
    public ResponseDTO<List<Long>> listRoleIdsByUserId(Long userId) {
        if (userMapper.selectById(userId) == null) {
            return ResponseDTO.userErrorParam("用户不存在：" + userId);
        }
        return ResponseDTO.ok(userRoleMapper.selectRoleIdsByUserId(userId));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ResponseDTO<Void> assignRoles(Long userId, List<Long> roleIds) {
        if (userMapper.selectById(userId) == null) {
            return ResponseDTO.userErrorParam("用户不存在：" + userId);
        }
        if (roleIds == null) {
            return ResponseDTO.userErrorParam("roleIds 不能为 null");
        }

        Set<Long> distinctRoleIds = new LinkedHashSet<>();
        for (Long roleId : roleIds) {
            if (roleId == null) {
                return ResponseDTO.userErrorParam("roleId 不能为 null");
            }
            distinctRoleIds.add(roleId);
        }

        for (Long roleId : distinctRoleIds) {
            if (roleMapper.selectById(roleId) == null) {
                return ResponseDTO.userErrorParam("存在无效的角色 ID：" + roleId);
            }
        }

        userRoleMapper.deleteByUserId(userId);
        if (!distinctRoleIds.isEmpty()) {
            List<UserRole> relationList = new ArrayList<>(distinctRoleIds.size());
            for (Long roleId : distinctRoleIds) {
                relationList.add(new UserRole(userId, roleId));
            }
            userRoleMapper.insertBatch(relationList);
        }
        return ResponseDTO.ok();
    }

    @Override
    public ResponseDTO<PageResult<UserRolePageVO>> pageUsers(int pageNum, int pageSize,
                                                            String username, String name) {
        int offset = (pageNum - 1) * pageSize;
        String usernameCondition = StringUtils.hasText(username) ? username.trim() : null;
        String nameCondition = StringUtils.hasText(name) ? name.trim() : null;
        List<UserRolePageVO> list = userMapper.selectUserPage(
                offset, pageSize, usernameCondition, nameCondition);
        long total = userMapper.countUserPage(usernameCondition, nameCondition);
        return ResponseDTO.ok(new PageResult<>(total, list));
    }
}
