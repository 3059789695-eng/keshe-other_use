/*
 * 文件：Role.java
 * 包路径：com.course.userrole.entity
 */
package com.course.userrole.entity;

import lombok.Data;

/**
 * 角色表实体。
 */
@Data
public class Role {
    private Long id;
    private String name;
    private String description;
}
