package net.lab1024.sa.admin.module.business.appeal.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import net.lab1024.sa.admin.module.business.appeal.domain.form.AppealQueryForm;
import net.lab1024.sa.admin.module.business.appeal.domain.form.AppealSubmitForm;
import net.lab1024.sa.admin.module.business.appeal.domain.vo.AppealDetailVO;
import net.lab1024.sa.admin.module.business.appeal.domain.vo.AppealVO;
import net.lab1024.sa.admin.module.business.appeal.service.AppealQueryService;
import net.lab1024.sa.admin.module.business.appeal.service.AppealService;
import net.lab1024.sa.base.common.annoation.NoNeedLogin;
import net.lab1024.sa.base.common.domain.PageResult;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.springframework.web.bind.annotation.*;

/**
 * 复议管理接口（学生端）
 */
@RestController
@Tag(name = "复议管理")
public class AppealController {

    @Resource
    private AppealService appealService;

    @Resource
    private AppealQueryService appealQueryService;

    /**
     * S-09：提交复议申请
     *
     * 在成绩详情页，每道题旁有"申请复议"按钮。
     * 点击后填写复议理由（最多500字），可上传截图证据（最多3张）。
     * 提交后该题状态变为"待审核"。同一道题不可重复提交。
     */
    @Operation(summary = "提交复议申请（S-09）")
    @NoNeedLogin  // TODO: 正式上线恢复 @SaCheckPermission("appeal:appeal:submit")
    @PostMapping("/appeal/appeal/submit")
    public ResponseDTO<String> submit(@RequestBody @Valid AppealSubmitForm form) {
        return appealService.submit(form);
    }

    /**
     * 检查某道题是否已提交复议
     *
     * 前端根据此接口控制按钮状态：
     * - 未提交 → 显示"申请复议"按钮
     * - 已提交 → 按钮变灰，显示"已申请复议"
     */
    @Operation(summary = "检查题目是否已申请复议")
    @NoNeedLogin  // TODO: 正式上线恢复 @SaCheckPermission("appeal:appeal:query")
    @GetMapping("/appeal/appeal/checkSubmitted")
    public ResponseDTO<Boolean> checkSubmitted(@RequestParam Long answerDetailId) {
        return appealService.checkSubmitted(answerDetailId);
    }

    /**
     * 分页查询复议记录（复议进度查看）
     *
     * 排序规则：待审核记录在上，已通过和已驳回在下
     * 支持按状态筛选（全部/待审核/已通过/已驳回）
     * 底部有分页控件
     */
    @Operation(summary = "分页查询复议记录")
    @NoNeedLogin  // TODO: 正式上线恢复 @SaCheckPermission("appeal:appeal:query")
    @PostMapping("/appeal/appeal/query")
    public ResponseDTO<PageResult<AppealVO>> query(@RequestBody @Valid AppealQueryForm form) {
        return appealQueryService.queryPage(form);
    }

    /**
     * 查看复议详情
     *
     * 展示：
     * - 原题目及学生完整作答
     * - 学生提交的复议理由 + 证据截图
     * - 教师处理意见、调整后分数
     * - 处理状态（待审核/已通过/已驳回）
     */
    @Operation(summary = "查看复议详情")
    @NoNeedLogin  // TODO: 正式上线恢复 @SaCheckPermission("appeal:appeal:query")
    @GetMapping("/appeal/appeal/{appealId}")
    public ResponseDTO<AppealDetailVO> detail(@PathVariable Long appealId) {
        return appealQueryService.getDetail(appealId);
    }
}
