/*
 * 文件：UserRoleController.java
 * 包路径：com.course.userrole.controller
 */
package com.course.userrole.controller;

import com.course.userrole.common.PageResult;
import com.course.userrole.common.ResponseDTO;
import com.course.userrole.dto.UserRoleAssignDTO;
import com.course.userrole.service.UserRoleService;
import com.course.userrole.vo.RoleVO;
import com.course.userrole.vo.UserRolePageVO;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.RequiredArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 用户角色分配接口，对应 R-02。
 */
@Validated
@RestController
@RequestMapping("/api/user-role")
@RequiredArgsConstructor
public class UserRoleController {

    private final UserRoleService userRoleService;

    @GetMapping("/roles")
    public ResponseDTO<List<RoleVO>> listAllRoles() {
        return userRoleService.listAllRoles();
    }

    @GetMapping("/user/{userId}/roles")
    public ResponseDTO<List<Long>> listRoleIdsByUserId(
            @PathVariable("userId")
            @NotNull(message = "userId 不能为空")
            @Positive(message = "userId 必须为正整数")
            Long userId) {
        return userRoleService.listRoleIdsByUserId(userId);
    }

    @PostMapping("/user/{userId}/roles")
    public ResponseDTO<Void> assignRoles(
            @PathVariable("userId")
            @NotNull(message = "userId 不能为空")
            @Positive(message = "userId 必须为正整数")
            Long userId,
            @Valid @RequestBody UserRoleAssignDTO dto) {
        return userRoleService.assignRoles(userId, dto.getRoleIds());
    }

    @GetMapping("/users")
    public ResponseDTO<PageResult<UserRolePageVO>> pageUsers(
            @RequestParam(defaultValue = "1")
            @Min(value = 1, message = "pageNum 必须大于 0")
            Integer pageNum,
            @RequestParam(defaultValue = "10")
            @Min(value = 1, message = "pageSize 必须大于 0")
            @Max(value = 100, message = "pageSize 不能超过 100")
            Integer pageSize,
            @RequestParam(required = false) String username,
            @RequestParam(required = false) String name) {
        return userRoleService.pageUsers(pageNum, pageSize, username, name);
    }
}
