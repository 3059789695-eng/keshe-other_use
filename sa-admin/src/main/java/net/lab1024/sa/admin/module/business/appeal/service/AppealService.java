package net.lab1024.sa.admin.module.business.appeal.service;

import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import net.lab1024.sa.admin.module.business.appeal.constant.AppealStatusEnum;
import net.lab1024.sa.admin.module.business.appeal.dao.AppealDao;
import net.lab1024.sa.admin.module.business.appeal.domain.entity.AppealEntity;
import net.lab1024.sa.admin.module.business.appeal.domain.form.AppealSubmitForm;
import net.lab1024.sa.admin.module.system.login.domain.RequestEmployee;
import net.lab1024.sa.admin.util.AdminRequestUtil;
import net.lab1024.sa.base.common.code.UserErrorCode;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import net.lab1024.sa.base.common.util.SmartBeanUtil;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 复议管理 - 学生端写操作
 */
@Slf4j
@Service
public class AppealService {

    @Resource
    private AppealDao appealDao;

    /**
     * 提交复议申请（S-09）
     *
     * 业务规则：
     * 1. 同一道题不可重复提交（代码校验）
     * 2. 复议理由必填，最多 500 字
     * 3. 证据截图最多 3 张
     */
    @Transactional(rollbackFor = Exception.class)
    public ResponseDTO<String> submit(AppealSubmitForm form) {
        // 1. 获取当前登录学生
        RequestEmployee requestEmployee = AdminRequestUtil.getRequestUser();

        // 2. 业务校验：同一道题不可重复提交
        AppealEntity existing = appealDao.selectByAnswerDetailAndStudent(
                form.getAnswerDetailId(), requestEmployee.getEmployeeId());
        if (existing != null) {
            return ResponseDTO.userErrorParam("该题目已申请过复议，不可重复提交");
        }

        // 3. 校验复议理由
        if (form.getAppealReason() == null || form.getAppealReason().trim().isEmpty()) {
            return ResponseDTO.userErrorParam("复议理由不能为空");
        }
        if (form.getAppealReason().length() > 500) {
            return ResponseDTO.userErrorParam("复议理由最多 500 字");
        }

        // 4. 组装实体
        AppealEntity entity = SmartBeanUtil.copy(form, AppealEntity.class);
        entity.setStudentId(requestEmployee.getEmployeeId());
        entity.setStatus(AppealStatusEnum.PENDING.getValue()); // 待审核
        if (form.getEvidenceUrls() != null && !form.getEvidenceUrls().isEmpty()) {
            // List 转逗号分隔字符串存储
            entity.setEvidenceUrls(String.join(",", form.getEvidenceUrls()));
        }

        // 5. 写库
        appealDao.insert(entity);
        log.info("学生 {} 提交复议申请，appealId={}, answerDetailId={}",
                requestEmployee.getEmployeeId(), entity.getAppealId(), form.getAnswerDetailId());

        return ResponseDTO.ok();
    }

    /**
     * 检查某道题是否已提交复议
     *
     * 前端根据此接口控制按钮：
     * - 未提交 → 显示"申请复议"按钮
     * - 已提交 → 显示"已申请复议"，通过 GET /appeal/appeal/{id} 查处理状态
     */
    public ResponseDTO<Boolean> checkSubmitted(Long answerDetailId) {
        RequestEmployee requestEmployee = AdminRequestUtil.getRequestUser();

        AppealEntity existing = appealDao.selectByAnswerDetailAndStudent(
                answerDetailId, requestEmployee.getEmployeeId());

        return ResponseDTO.ok(existing != null);
    }
}
