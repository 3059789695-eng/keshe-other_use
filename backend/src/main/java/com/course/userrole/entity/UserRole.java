/*
 * 文件：UserRole.java
 * 包路径：com.course.userrole.entity
 */
package com.course.userrole.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 用户角色关联表实体。
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserRole {
    private Long userId;
    private Long roleId;
}
