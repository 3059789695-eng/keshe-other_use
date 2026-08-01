package com.course.userrole.service;

import com.course.userrole.common.PageResult;
import com.course.userrole.common.ResponseDTO;
import com.course.userrole.vo.RoleVO;
import com.course.userrole.vo.UserRolePageVO;

import java.util.List;

/**
 * 用户角色分配服务。
 */
public interface UserRoleService {

    ResponseDTO<List<RoleVO>> listAllRoles();

    ResponseDTO<List<Long>> listRoleIdsByUserId(Long userId);

    ResponseDTO<Void> assignRoles(Long userId, List<Long> roleIds);

    ResponseDTO<PageResult<UserRolePageVO>> pageUsers(int pageNum, int pageSize, String username, String name);
}
