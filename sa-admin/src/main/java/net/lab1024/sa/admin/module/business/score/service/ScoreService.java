package net.lab1024.sa.admin.module.business.score.service;

import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import net.lab1024.sa.admin.module.business.score.dao.ScoreDao;
import net.lab1024.sa.admin.module.business.score.domain.entity.ScoreEntity;
import net.lab1024.sa.base.common.code.UserErrorCode;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

/**
 * 成绩管理 - 写操作
 */
@Slf4j
@Service
public class ScoreService {

    @Resource
    private ScoreDao scoreDao;

    /**
     * 重算总分（复议/违规扣分后调用）
     * 根据答案详情表中的各题得分重新汇总
     *
     * @param examId    考试 ID
     * @param studentId 学生 ID
     * @param newScore  新总分（由调用方计算好传入）
     */
    @Transactional(rollbackFor = Exception.class)
    public ResponseDTO<String> recalculateScore(Long examId, Long studentId, BigDecimal newScore) {
        // 1. 查询已有成绩记录
        ScoreEntity entity = scoreDao.selectByExamIdAndStudent(examId, studentId);
        if (entity == null) {
            return ResponseDTO.error(UserErrorCode.DATA_NOT_EXIST);
        }

        // 2. 更新总分和及格状态
        entity.setTotalScore(newScore);
        // 及格线由考试表定义，这里简化处理：60 分及格
        entity.setPassStatus(newScore.compareTo(new BigDecimal("60")) >= 0 ? 1 : 0);
        scoreDao.updateById(entity);

        log.info("重算成绩：examId={}, studentId={}, newScore={}", examId, studentId, newScore);
        return ResponseDTO.ok();
    }

    /**
     * 根据答案详情重算总分
     * 遍历所有答案详情，汇总得分，取原始分（非加权分）
     */
    @Transactional(rollbackFor = Exception.class)
    public void recalculateFromDetails(Long examId, Long studentId,
                                        List<BigDecimal> questionScores,
                                        ScoreEntity scoreEntity) {
        BigDecimal total = questionScores.stream()
                .filter(s -> s != null)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        scoreEntity.setTotalScore(total);
        scoreEntity.setPassStatus(total.compareTo(new BigDecimal("60")) >= 0 ? 1 : 0);
        scoreDao.updateById(scoreEntity);

        log.info("根据详情重算成绩：examId={}, studentId={}, total={}", examId, studentId, total);
    }
}
