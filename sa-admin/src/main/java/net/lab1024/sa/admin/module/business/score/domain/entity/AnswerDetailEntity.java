package net.lab1024.sa.admin.module.business.score.domain.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 答案详情表 t_answer_detail
 */
@Data
@TableName("t_answer_detail")
public class AnswerDetailEntity {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 作答记录 ID */
    private Long answerId;

    /** 题目 ID */
    private Long questionId;

    /** 用户答案文本 */
    private String userAnswer;

    /** 语音答题录音 URL */
    private String voiceRecordUrl;

    /** 得分（NULL 表示未批改） */
    private BigDecimal score;

    /** 批改方式 [1:规则自动,2:外部服务,3:人工] */
    private Integer gradeType;

    /** 批改评语 */
    private String gradeRemark;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;
}
