package net.lab1024.sa.admin.module.business.score.domain.entity;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 成绩表 t_score
 */
@Data
public class ScoreEntity {

    private Long scoreId;

    private Long examId;

    private Long studentId;

    /** 总分 */
    private BigDecimal totalScore;

    /** 及格状态 [0:不及格,1:及格] */
    private Integer passStatus;

    /** 排名 */
    private Integer rankPosition;

    /** 交卷时间 */
    private LocalDateTime submitTime;

    /** 批改完成时间 */
    private LocalDateTime gradeTime;

    /** 备注 */
    private String remark;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;
}
