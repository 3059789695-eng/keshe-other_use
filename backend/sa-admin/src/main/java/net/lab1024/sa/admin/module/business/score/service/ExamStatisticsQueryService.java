package net.lab1024.sa.admin.module.business.score.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletResponse;
import net.lab1024.sa.admin.module.business.score.dao.ExamStatisticsDao;
import net.lab1024.sa.admin.module.business.score.domain.form.ExamQueryForm;
import net.lab1024.sa.admin.module.business.score.domain.form.ExamStudentQueryForm;
import net.lab1024.sa.admin.module.business.score.domain.vo.*;
import net.lab1024.sa.base.common.code.UserErrorCode;
import net.lab1024.sa.base.common.domain.PageResult;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import net.lab1024.sa.base.common.util.SmartPageUtil;
import net.lab1024.sa.base.common.util.SmartExcelUtil;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.List;

/**
 * 教师端考试完成情况与成绩统计查询服务。
 */
@Service
public class ExamStatisticsQueryService {

    @Resource
    private ExamStatisticsDao examStatisticsDao;

    /**
     * 分页查询考试及完成数量。
     */
    public ResponseDTO<PageResult<ExamListVO>> queryPage(ExamQueryForm queryForm) {
        Page<?> page = SmartPageUtil.convert2PageQuery(queryForm);
        List<ExamListVO> list = examStatisticsDao.queryExam(page, queryForm);
        return ResponseDTO.ok(SmartPageUtil.convert2PageResult(page, list));
    }

    /**
     * 查询指定考试的成绩统计数据。
     */
    public ResponseDTO<ExamStatisticsVO> getStatistics(Long examId) {
        ExamStatisticsVO statistics = examStatisticsDao.queryStatistics(examId);
        if (statistics == null) {
            return ResponseDTO.error(UserErrorCode.DATA_NOT_EXIST);
        }
        statistics.setScoreDistribution(examStatisticsDao.queryScoreDistribution(examId));
        return ResponseDTO.ok(statistics);
    }

    /**
     * 分页查询学生完成情况和成绩。
     */
    public ResponseDTO<PageResult<StudentScoreVO>> queryStudentPage(ExamStudentQueryForm queryForm) {
        if (examStatisticsDao.queryStatistics(queryForm.getExamId()) == null) {
            return ResponseDTO.error(UserErrorCode.DATA_NOT_EXIST);
        }
        Page<?> page = SmartPageUtil.convert2PageQuery(queryForm);
        List<StudentScoreVO> list = examStatisticsDao.queryStudent(page, queryForm);
        return ResponseDTO.ok(SmartPageUtil.convert2PageResult(page, list));
    }

    /**
     * 查询学生完整答卷。
     */
    public ResponseDTO<StudentAnswerDetailVO> getAnswerDetail(Long examId, Long studentId) {
        StudentAnswerDetailVO detail = examStatisticsDao.queryAnswerDetail(examId, studentId);
        if (detail == null) {
            return ResponseDTO.error(UserErrorCode.DATA_NOT_EXIST);
        }
        detail.setAnswerList(examStatisticsDao.queryAnswerItems(detail.getExamRecordId()));
        return ResponseDTO.ok(detail);
    }

    /**
     * 导出指定考试的全部学生成绩。
     */
    public void exportAllStudentScores(Long examId, HttpServletResponse response) throws IOException {
        List<StudentScoreExcelVO> list = examStatisticsDao.queryAllStudentScores(examId);
        SmartExcelUtil.exportExcel(response, "考试成绩.xlsx", "成绩", StudentScoreExcelVO.class, list);
    }

    /**
     * 导出指定考试的未完成学生名单。
     */
    public void exportUnfinishedStudents(Long examId, HttpServletResponse response) throws IOException {
        List<UnfinishedStudentExcelVO> list = examStatisticsDao.queryUnfinishedStudents(examId);
        SmartExcelUtil.exportExcel(response, "未完成学生名单.xlsx", "未完成名单", UnfinishedStudentExcelVO.class, list);
    }
}
