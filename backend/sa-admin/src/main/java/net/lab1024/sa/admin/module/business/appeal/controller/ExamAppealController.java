package net.lab1024.sa.admin.module.business.appeal.controller;

import cn.dev33.satoken.annotation.SaCheckPermission;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import net.lab1024.sa.admin.module.business.appeal.domain.form.AppealQueryForm;
import net.lab1024.sa.admin.module.business.appeal.domain.form.AppealReviewForm;
import net.lab1024.sa.admin.module.business.appeal.domain.vo.AppealDetailVO;
import net.lab1024.sa.admin.module.business.appeal.domain.vo.AppealVO;
import net.lab1024.sa.admin.module.business.appeal.service.ExamAppealService;
import net.lab1024.sa.admin.module.business.appeal.service.ExamAppealQueryService;
import net.lab1024.sa.base.common.domain.PageResult;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.springframework.web.bind.annotation.*;

/**
 * 教师端考试成绩复议接口。
 */
@RestController
@Tag(name = "考试成绩复议处理")
public class ExamAppealController {

    @Resource
    private ExamAppealService examAppealService;

    @Resource
    private ExamAppealQueryService examAppealQueryService;

    @Operation(summary = "分页查询复议申请，Web和移动端共用")
    @PostMapping("/appeal/application/query")
    @SaCheckPermission("appeal:application:query")
    public ResponseDTO<PageResult<AppealVO>> queryPage(@RequestBody @Valid AppealQueryForm queryForm) {
        return examAppealQueryService.queryPage(queryForm);
    }

    @Operation(summary = "查看复议申请详情，Web和移动端共用")
    @GetMapping("/appeal/application/detail/{appealId}")
    @SaCheckPermission("appeal:application:query")
    public ResponseDTO<AppealDetailVO> getDetail(@PathVariable Long appealId) {
        return examAppealQueryService.getDetail(appealId);
    }

    @Operation(summary = "通过或驳回复议申请，Web和移动端共用")
    @PostMapping("/appeal/application/review")
    @SaCheckPermission("appeal:application:review")
    public ResponseDTO<String> review(@RequestBody @Valid AppealReviewForm reviewForm) {
        return examAppealService.review(reviewForm);
    }
}
