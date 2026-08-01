package net.lab1024.course;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * 课程管理系统 - 启动类
 * 基于 Spring Boot 2.7.18 + MyBatis-Plus + MySQL 5.7 + JDK 17
 *
 * @author course-team
 */
@SpringBootApplication
public class CourseApplication {
    public static void main(String[] args) {
        SpringApplication.run(CourseApplication.class, args);
        System.out.println("==========================================");
        System.out.println("  课程管理系统启动成功！");
        System.out.println("  接口地址: http://localhost:8080");
        System.out.println("==========================================");
    }
}
