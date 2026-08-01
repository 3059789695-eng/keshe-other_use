/*
 * 文件：CourseOpeningPageVO.java
 * 包路径：com.course.opening.vo
 */
package com.course.opening.vo;

import lombok.Data;

import java.math.BigDecimal;

/**
 * 开课分页列表返回对象。
 */
@Data
public class CourseOpeningPageVO {

    private Integer id;
    private Integer courseId;
    private String courseNo;
    private String courseName;
    private BigDecimal credit;
    private Integer semesterId;
    private String semesterName;
    private Integer teacherId;
    private String teacherName;
    private Integer maxStudents;
}
