package com.course.userrole.vo;

import lombok.Data;

/**
 * 用户分页列表返回对象。
 * roleIds / roleNames 为逗号分隔字符串；assigned 用于列表页展示分配角色按钮。
 */
@Data
public class UserRolePageVO {

    private Long id;

    private String username;

    private String name;

    private String roleIds;

    private String roleNames;

    private Boolean assigned;
}
