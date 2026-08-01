/*
 * 文件：CourseOpeningApplication.java
 * 包路径：com.course.opening
 */
package com.course.opening;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * 开课管理模块启动类。
 */
@SpringBootApplication
@MapperScan("com.course.opening.mapper")
public class CourseOpeningApplication {

    public static void main(String[] args) {
        SpringApplication.run(CourseOpeningApplication.class, args);
    }
}
