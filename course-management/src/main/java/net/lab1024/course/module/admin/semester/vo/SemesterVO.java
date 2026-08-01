package net.lab1024.course.module.admin.semester.vo;

import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 学期返回 VO
 */
@Data
public class SemesterVO {

    /** 学期ID */
    private Long id;

    /** 学期名称 */
    private String semesterName;

    /** 开始日期 */
    private LocalDate startDate;

    /** 结束日期 */
    private LocalDate endDate;

    /** 是否启用（0=禁用/已删除，1=启用） */
    private Integer isDeleted;

    /** 创建时间 */
    private LocalDateTime createTime;
}
