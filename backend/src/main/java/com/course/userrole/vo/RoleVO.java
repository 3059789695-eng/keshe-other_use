package com.course.userrole.vo;

import lombok.Data;

/**
 * 角色列表返回对象。
 * 当前 roles 表没有 role_code 字段，roleCode 暂返回角色名称 name；
 * 若后续表结构新增 role_code，只需调整 XML 查询即可。
 */
@Data
public class RoleVO {

    private Long id;

    private String roleName;

    private String roleCode;

    private String description;
}
