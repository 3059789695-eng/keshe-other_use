package net.lab1024.sa.admin.module.business.appeal.service;

import net.lab1024.sa.admin.module.business.appeal.dao.ExamAppealDao;
import net.lab1024.sa.admin.module.business.appeal.domain.form.AppealReviewForm;
import net.lab1024.sa.admin.module.business.appeal.domain.vo.AppealDetailVO;
import net.lab1024.sa.admin.module.business.score.service.ScoreService;
import net.lab1024.sa.admin.module.system.login.domain.RequestEmployee;
import net.lab1024.sa.admin.util.AdminRequestUtil;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * 成绩复议写操作服务测试。
 */
@ExtendWith(MockitoExtension.class)
class ExamAppealServiceTest {

    @Mock
    private ExamAppealDao examAppealDao;

    @Mock
    private ScoreService scoreService;

    @InjectMocks
    private ExamAppealService examAppealService;

    @Test
    void shouldRejectMissingAppeal() {
        when(examAppealDao.queryDetail(1L)).thenReturn(null);

        ResponseDTO<String> result = examAppealService.review(form(1, null));

        assertFalse(result.getOk());
    }

    @Test
    void shouldRejectRepeatedReview() {
        AppealDetailVO detail = pendingDetail();
        detail.setAppealStatus(1);
        when(examAppealDao.queryDetail(1L)).thenReturn(detail);

        ResponseDTO<String> result = examAppealService.review(form(1, new BigDecimal("15")));

        assertFalse(result.getOk());
        assertTrue(result.getMsg().contains("已经处理"));
    }

    @Test
    void shouldRequireAdjustedScoreWhenApproved() {
        when(examAppealDao.queryDetail(1L)).thenReturn(pendingDetail());

        ResponseDTO<String> result = examAppealService.review(form(1, null));

        assertFalse(result.getOk());
        assertTrue(result.getMsg().contains("调整后分数"));
    }

    @Test
    void shouldRejectScoreAboveQuestionMaximum() {
        when(examAppealDao.queryDetail(1L)).thenReturn(pendingDetail());

        ResponseDTO<String> result = examAppealService.review(form(1, new BigDecimal("21")));

        assertFalse(result.getOk());
        assertTrue(result.getMsg().contains("题目满分"));
    }

    @Test
    void shouldUpdateScoreTotalAndNoticeWhenApproved() {
        AppealDetailVO detail = pendingDetail();
        when(examAppealDao.queryDetail(1L)).thenReturn(detail);
        when(examAppealDao.updateReview(eq(1L), eq(1), eq(new BigDecimal("15")), anyString(), eq(9L))).thenReturn(1);
        RequestEmployee employee = new RequestEmployee();
        employee.setEmployeeId(9L);

        try (MockedStatic<AdminRequestUtil> requestUtil = mockStatic(AdminRequestUtil.class)) {
            requestUtil.when(AdminRequestUtil::getRequestUser).thenReturn(employee);
            ResponseDTO<String> result = examAppealService.review(form(1, new BigDecimal("15")));

            assertTrue(result.getOk());
            verify(scoreService).adjustAnswerScore(3L, new BigDecimal("15"));
            verify(examAppealDao).insertReviewNotice(1L);
        }
    }

    private AppealReviewForm form(int result, BigDecimal adjustedScore) {
        AppealReviewForm form = new AppealReviewForm();
        form.setAppealId(1L);
        form.setReviewResult(result);
        form.setAdjustedScore(adjustedScore);
        form.setTeacherOpinion("测试处理意见");
        return form;
    }

    private AppealDetailVO pendingDetail() {
        AppealDetailVO detail = new AppealDetailVO();
        detail.setAppealId(1L);
        detail.setAnswerId(3L);
        detail.setAppealStatus(0);
        detail.setMaxScore(new BigDecimal("20"));
        return detail;
    }
}
