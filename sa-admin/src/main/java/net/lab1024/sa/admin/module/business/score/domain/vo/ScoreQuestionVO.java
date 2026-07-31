package net.lab1024.sa.admin.module.business.score.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 单题得分 VO（含三维度评分明细）
 */
@Data
public class ScoreQuestionVO {

    @Schema(description = "答案详情 ID")
    private Long answerDetailId;

    @Schema(description = "题号")
    private Integer sortOrder;

    @Schema(description = "题目 ID")
    private Long questionId;

    @Schema(description = "题目内容")
    private String questionContent;

    @Schema(description = "题型 [1:单选,2:多选,3:判断,4:简答,5:论述]")
    private Integer questionType;

    @Schema(description = "题型文本")
    private String questionTypeText;

    @Schema(description = "学生答案")
    private String userAnswer;

    @Schema(description = "原始分（本题实际得分）")
    private BigDecimal score;

    @Schema(description = "题目满分")
    private BigDecimal maxScore;

    @Schema(description = "难度系数")
    private BigDecimal difficultyValue;

    @Schema(description = "加权分（原始分 × 难度系数）")
    private BigDecimal weightedScore;

    @Schema(description = "评分理由（30-80字）")
    private String gradeRemark;

    // ===== 三维度评分明细（AI 生成） =====

    @Schema(description = "相关性得分（0-5）")
    private BigDecimal relevanceScore;

    @Schema(description = "相关性评语")
    private String relevanceComment;

    @Schema(description = "知识点覆盖度得分（0-5）")
    private BigDecimal coverageScore;

    @Schema(description = "知识点覆盖度评语")
    private String coverageComment;

    @Schema(description = "逻辑表达性得分（0-5）")
    private BigDecimal logicScore;

    @Schema(description = "逻辑表达性评语")
    private String logicComment;

    // ===== 复议相关 =====

    @Schema(description = "是否已申请复议")
    private Boolean appealed;

    @Schema(description = "复议状态 [1:待审核,2:已通过,3:已驳回]（已申请时有值）")
    private Integer appealStatus;

    @Schema(description = "复议状态文本")
    private String appealStatusText;
}
