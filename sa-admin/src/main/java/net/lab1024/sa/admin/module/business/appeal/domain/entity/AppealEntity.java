package net.lab1024.sa.admin.module.business.appeal.domain.entity;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 复议申请表 t_appeal
 */
@Data
public class AppealEntity {

    private Long appealId;

    /** 成绩 ID */
    private Long scoreId;

    /** 答案详情 ID（定位到具体题目） */
    private Long answerDetailId;

    /** 考试 ID */
    private Long examId;

    /** 学生 ID */
    private Long studentId;

    /** 复议理由（最多 500 字） */
    private String appealReason;

    /** 证据截图 URL 数组（JSON 格式，最多 3 张） */
    private String evidenceUrls;

    /** 状态 [1:待审核,2:已通过,3:已驳回] */
    private Integer status;

    /** 原题目得分 */
    private BigDecimal oldScore;

    /** 复议后得分 */
    private BigDecimal newScore;

    /** 教师处理意见 */
    private String teacherRemark;

    /** 处理教师 ID */
    private Long teacherId;

    /** 处理时间 */
    private LocalDateTime handleTime;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;
}
