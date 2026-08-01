package net.lab1024.sa.admin.module.business.score.service;

import jakarta.annotation.Resource;
import net.lab1024.sa.admin.module.business.score.dao.ScoreDao;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

/**
 * 成绩写操作服务。
 */
@Service
public class ScoreService {

    @Resource
    private ScoreDao scoreDao;

    /**
     * 调整单题得分并重新计算考试总分。
     */
    @Transactional(rollbackFor = Exception.class)
    public void adjustAnswerScore(Long answerId, BigDecimal adjustedScore) {
        scoreDao.updateAnswerScore(answerId, adjustedScore);
        scoreDao.recalculateExamScore(answerId);
    }
}
