package net.lab1024.sa.admin.module.business.score.domain.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 学生作答记录表 t_student_answer
 */
@Data
@TableName("t_student_answer")
public class StudentAnswerEntity {

    @TableId(type = IdType.AUTO)
    private Long answerId;

    private Long examId;

    private Long studentId;

    /** 状态 [1:未验证,2:已验证待开考,3:答题中,4:已提交,5:已批改] */
    private Integer status;

    /** 身份验证失败次数 */
    private Integer verifyFailCount;

    /** 验证锁定截止时间 */
    private LocalDateTime verifyLockUntil;

    /** 开始答题时间 */
    private LocalDateTime startAnswerTime;

    /** 最后保存时间（草稿） */
    private LocalDateTime lastSaveTime;

    /** 提交时间 */
    private LocalDateTime submitTime;

    /** IP 地址 */
    private String ipAddress;

    /** 设备信息 */
    private String deviceInfo;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;
}
