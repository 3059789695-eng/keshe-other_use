package net.lab1024.sa.admin.module.business.appeal.domain.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 成绩复议申请表 t_exam_appeal。
 */
@Data
@TableName("t_exam_appeal")
public class ExamAppealEntity {

    @TableId(type = IdType.AUTO)
    private Long appealId;
    private Long answerId;
    private String appealReason;
    /** 复议状态 [0:待处理,1:已通过,2:已驳回] */
    private Integer appealStatus;
    private BigDecimal adjustedScore;
    private String teacherOpinion;
    private Long reviewerId;
    private LocalDateTime applicationTime;
    private LocalDateTime reviewTime;
}
