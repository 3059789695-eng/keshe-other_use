package net.lab1024.sa.admin.module.business.score.controller;

import cn.dev33.satoken.annotation.SaCheckPermission;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import net.lab1024.sa.admin.module.business.score.domain.form.ExamQueryForm;
import net.lab1024.sa.admin.module.business.score.domain.form.ExamStudentQueryForm;
import net.lab1024.sa.admin.module.business.score.domain.vo.*;
import net.lab1024.sa.admin.module.business.score.service.ExamStatisticsQueryService;
import net.lab1024.sa.base.common.domain.PageResult;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;

/**
 * 教师端考试完成情况与成绩统计接口。
 */
@RestController
@Tag(name = "考试完成情况与成绩统计")
public class ExamStatisticsController {

    @Resource
    private ExamStatisticsQueryService examStatisticsQueryService;

    @Operation(summary = "分页查询考试")
    @PostMapping("/score/exam/query")
    @SaCheckPermission("score:statistics:query")
    public ResponseDTO<PageResult<ExamListVO>> queryPage(@RequestBody @Valid ExamQueryForm queryForm) {
        return examStatisticsQueryService.queryPage(queryForm);
    }

    @Operation(summary = "查看考试统计数据")
    @GetMapping("/score/statistics/detail/{examId}")
    @SaCheckPermission("score:statistics:query")
    public ResponseDTO<ExamStatisticsVO> getDetail(@PathVariable Long examId) {
        return examStatisticsQueryService.getStatistics(examId);
    }

    @Operation(summary = "分页查询学生完成情况和成绩")
    @PostMapping("/score/student/query")
    @SaCheckPermission("score:statistics:query")
    public ResponseDTO<PageResult<StudentScoreVO>> queryStudentPage(@RequestBody @Valid ExamStudentQueryForm queryForm) {
        return examStatisticsQueryService.queryStudentPage(queryForm);
    }

    @Operation(summary = "查看学生完整答卷")
    @GetMapping("/score/answer/detail/{examId}/{studentId}")
    @SaCheckPermission("score:statistics:query")
    public ResponseDTO<StudentAnswerDetailVO> getAnswerDetail(@PathVariable Long examId, @PathVariable Long studentId) {
        return examStatisticsQueryService.getAnswerDetail(examId, studentId);
    }

    @Operation(summary = "导出全部学生成绩")
    @GetMapping("/score/statistics/export/{examId}")
    @SaCheckPermission("score:statistics:export")
    public void export(@PathVariable Long examId, HttpServletResponse response) throws IOException {
        examStatisticsQueryService.exportAllStudentScores(examId, response);
    }

    @Operation(summary = "导出未完成学生名单")
    @GetMapping("/score/unfinished/export/{examId}")
    @SaCheckPermission("score:statistics:export")
    public void exportUnfinished(@PathVariable Long examId, HttpServletResponse response) throws IOException {
        examStatisticsQueryService.exportUnfinishedStudents(examId, response);
    }
}
