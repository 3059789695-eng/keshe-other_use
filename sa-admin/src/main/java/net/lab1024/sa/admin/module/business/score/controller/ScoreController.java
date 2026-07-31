package net.lab1024.sa.admin.module.business.score.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import net.lab1024.sa.admin.module.business.score.domain.form.ScoreQueryForm;
import net.lab1024.sa.admin.module.business.score.domain.vo.ScoreDetailVO;
import net.lab1024.sa.admin.module.business.score.domain.vo.ScoreHistoryVO;
import net.lab1024.sa.admin.module.business.score.service.ScoreQueryService;
import net.lab1024.sa.base.common.annoation.NoNeedLogin;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 成绩管理接口
 */
@RestController
@Tag(name = "成绩管理")
public class ScoreController {

    @Resource
    private ScoreQueryService scoreQueryService;

    /**
     * S-07：查看本次成绩与反馈
     *
     * 返回成绩详情，包含：
     * - 总分、及格状态、排名
     * - 每题得分（原始分 × 难度系数 = 加权分）
     * - 评分理由（30-80字）
     * - 三维度评分明细（相关性、知识点覆盖度、逻辑表达性）
     * - AI 整体学习建议（亮点、薄弱点、改进建议）
     */
    @Operation(summary = "查看本次成绩与反馈（S-07）")
    @NoNeedLogin
    @PostMapping("/score/score/detail")
    // TODO: 正式上线时恢复：@SaCheckPermission("score:score:detail") 并去掉 @NoNeedLogin
    public ResponseDTO<ScoreDetailVO> detail(@RequestBody @Valid ScoreQueryForm form) {
        return scoreQueryService.getDetail(form);
    }

    /**
     * 学生查看历史成绩列表
     *
     * 返回该学生的所有考试成绩，包含：
     * - 考试标题、课程名称、学期
     * - 总分、及格状态、排名
     * - 是否有复议记录
     * - 按交卷时间倒序排列
     */
    @Operation(summary = "查看历史成绩列表")
    @NoNeedLogin
    @PostMapping("/score/score/history")
    // TODO: 正式上线时恢复：@SaCheckPermission("score:score:history") 并去掉 @NoNeedLogin
    public ResponseDTO<List<ScoreHistoryVO>> history(@RequestParam(required = false) Long studentId) {
        return scoreQueryService.getHistory(studentId);
    }
}
