package com.course.userrole;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * 用户角色分配模块启动类。
 */
@SpringBootApplication
@MapperScan("com.course.userrole.mapper")
public class UserRoleApplication {

    public static void main(String[] args) {
        SpringApplication.run(UserRoleApplication.class, args);
    }
}
