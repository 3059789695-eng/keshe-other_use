/*
 * 文件：CourseOpeningDetailVO.java
 * 包路径：com.course.opening.vo
 */
package com.course.opening.vo;

import lombok.Data;

/**
 * 开课详情返回对象，用于编辑页回显。
 */
@Data
public class CourseOpeningDetailVO {

    private Integer id;
    private Integer courseId;
    private Integer semesterId;
    private Integer teacherId;
    private Integer maxStudents;
}
