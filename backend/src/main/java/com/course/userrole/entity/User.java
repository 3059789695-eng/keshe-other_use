/*
 * 文件：User.java
 * 包路径：com.course.userrole.entity
 */
package com.course.userrole.entity;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户表实体。
 */
@Data
public class User {
    private Long id;
    private String username;
    private String password;
    private String name;
    private String email;
    private String userType;
    private Integer status;
    private Integer tempPwdFlag;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
