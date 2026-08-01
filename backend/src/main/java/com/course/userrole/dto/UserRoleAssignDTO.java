package com.course.userrole.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

/**
 * 分配角色请求参数。
 * roleIds 允许为空数组，空数组表示清除该用户全部角色。
 */
@Data
public class UserRoleAssignDTO {

    @NotNull(message = "roleIds 不能为 null")
    private List<@NotNull(message = "roleId 不能为 null") Long> roleIds;
}
