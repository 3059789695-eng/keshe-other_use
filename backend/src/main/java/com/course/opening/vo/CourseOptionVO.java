/*
 * 文件：CourseOptionVO.java
 * 包路径：com.course.opening.vo
 */
package com.course.opening.vo;

import lombok.Data;

/**
 * 课程下拉选项。
 */
@Data
public class CourseOptionVO {

    private Integer id;
    private String courseNo;
    private String courseName;
}
