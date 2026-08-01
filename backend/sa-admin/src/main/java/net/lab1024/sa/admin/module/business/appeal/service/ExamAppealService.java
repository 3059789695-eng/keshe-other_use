package net.lab1024.sa.admin.module.business.appeal.service;

import jakarta.annotation.Resource;
import net.lab1024.sa.admin.module.business.appeal.constant.AppealStatusConst;
import net.lab1024.sa.admin.module.business.appeal.dao.ExamAppealDao;
import net.lab1024.sa.admin.module.business.appeal.domain.form.AppealReviewForm;
import net.lab1024.sa.admin.module.business.appeal.domain.vo.AppealDetailVO;
import net.lab1024.sa.admin.module.business.score.service.ScoreService;
import net.lab1024.sa.admin.util.AdminRequestUtil;
import net.lab1024.sa.base.common.code.UserErrorCode;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

/**
 * 考试成绩复议写操作服务。
 */
@Service
public class ExamAppealService {

    @Resource
    private ExamAppealDao examAppealDao;

    @Resource
    private ScoreService scoreService;

    /**
     * 通过或驳回复议申请。
     */
    @Transactional(rollbackFor = Exception.class)
    public ResponseDTO<String> review(AppealReviewForm reviewForm) {
        AppealDetailVO detail = examAppealDao.queryDetail(reviewForm.getAppealId());
        if (detail == null) {
            return ResponseDTO.error(UserErrorCode.DATA_NOT_EXIST);
        }
        if (!Integer.valueOf(AppealStatusConst.PENDING).equals(detail.getAppealStatus())) {
            return ResponseDTO.userErrorParam("该复议已经处理，不能重复操作");
        }
        if (!Integer.valueOf(AppealStatusConst.APPROVED).equals(reviewForm.getReviewResult())
                && !Integer.valueOf(AppealStatusConst.REJECTED).equals(reviewForm.getReviewResult())) {
            return ResponseDTO.userErrorParam("处理结果只能为通过或驳回");
        }

        BigDecimal adjustedScore = reviewForm.getAdjustedScore();
        if (Integer.valueOf(AppealStatusConst.APPROVED).equals(reviewForm.getReviewResult())) {
            if (adjustedScore == null) {
                return ResponseDTO.userErrorParam("通过复议时必须填写调整后分数");
            }
            if (adjustedScore.compareTo(BigDecimal.ZERO) < 0 || adjustedScore.compareTo(detail.getMaxScore()) > 0) {
                return ResponseDTO.userErrorParam("调整后分数必须在0分和题目满分之间");
            }
        } else {
            adjustedScore = null;
        }

        Long reviewerId = AdminRequestUtil.getRequestUser().getEmployeeId();
        int updated = examAppealDao.updateReview(reviewForm.getAppealId(), reviewForm.getReviewResult(),
                adjustedScore, reviewForm.getTeacherOpinion(), reviewerId);
        if (updated == 0) {
            return ResponseDTO.userErrorParam("该复议已被其他教师处理，请刷新后查看");
        }

        if (Integer.valueOf(AppealStatusConst.APPROVED).equals(reviewForm.getReviewResult())) {
            scoreService.adjustAnswerScore(detail.getAnswerId(), adjustedScore);
        }
        examAppealDao.insertReviewNotice(reviewForm.getAppealId());
        return ResponseDTO.ok();
    }
}
