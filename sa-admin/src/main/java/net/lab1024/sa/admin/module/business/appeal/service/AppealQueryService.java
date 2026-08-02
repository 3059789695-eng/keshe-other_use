package net.lab1024.sa.admin.module.business.appeal.service;

import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import net.lab1024.sa.admin.module.business.appeal.constant.AppealStatusEnum;
import net.lab1024.sa.admin.module.business.appeal.dao.AppealDao;
import net.lab1024.sa.admin.module.business.appeal.domain.entity.AppealEntity;
import net.lab1024.sa.admin.module.business.appeal.domain.form.AppealQueryForm;
import net.lab1024.sa.admin.module.business.appeal.domain.vo.AppealDetailVO;
import net.lab1024.sa.admin.module.business.appeal.domain.vo.AppealVO;
import net.lab1024.sa.admin.util.AdminRequestUtil;
import net.lab1024.sa.base.common.code.UserErrorCode;
import net.lab1024.sa.base.common.domain.PageResult;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import net.lab1024.sa.base.common.util.SmartBeanUtil;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

/**
 * 复议管理 - 读操作
 */
@Slf4j
@Service
public class AppealQueryService {

    @Resource
    private AppealDao appealDao;

    /**
     * 分页查询复议记录（B区：复议进度列表 / S-10：查看复议进度）
     *
     * 排序规则：
     * - 待审核记录排在最前面
     * - 然后按申请时间倒序
     *
     * 支持按状态筛选
     */
    public ResponseDTO<PageResult<AppealVO>> queryPage(AppealQueryForm form) {
        // 1. 确定学生 ID
        Long studentId = form.getStudentId();
        if (studentId == null) {
            studentId = AdminRequestUtil.getRequestUserId();
        }

        // 2. 分页查询（PageHelper 自动拦截）
        PageHelper.startPage(form.getPageNum().intValue(), form.getPageSize().intValue());
        List<AppealEntity> entityList = appealDao.selectByCondition(
                studentId, form.getExamId(), form.getStatus());

        // 3. PageHelper 分页信息
        PageInfo<AppealEntity> pageInfo = new PageInfo<>(entityList);

        // 4. Entity 转 VO
        List<AppealVO> voList = pageInfo.getList().stream().map(entity -> {
            AppealVO vo = SmartBeanUtil.copy(entity, AppealVO.class);
            vo.setStatusText(AppealStatusEnum.getDescByValue(entity.getStatus()));
            // TODO: 关联查询考试标题、学生姓名、题目内容
            return vo;
        }).collect(Collectors.toList());

        // 5. 组装 PageResult
        PageResult<AppealVO> result = new PageResult<>();
        result.setPageNum((long) pageInfo.getPageNum());
        result.setPageSize((long) pageInfo.getPageSize());
        result.setTotal(pageInfo.getTotal());
        result.setPages((long) pageInfo.getPages());
        result.setList(voList);
        result.setEmptyFlag(voList.isEmpty());

        return ResponseDTO.ok(result);
    }

    /**
     * 查看复议详情
     */
    public ResponseDTO<AppealDetailVO> getDetail(Long appealId) {
        AppealEntity entity = appealDao.selectById(appealId);
        if (entity == null) {
            return ResponseDTO.error(UserErrorCode.DATA_NOT_EXIST);
        }

        // 组装详情 VO
        AppealDetailVO vo = SmartBeanUtil.copy(entity, AppealDetailVO.class);
        vo.setStatusText(AppealStatusEnum.getDescByValue(entity.getStatus()));
        vo.setAppealStatus(AppealStatusEnum.getDescByValue(entity.getStatus()));

        // evidenceUrls 从逗号分隔字符串转换为 List
        if (entity.getEvidenceUrls() != null && !entity.getEvidenceUrls().isEmpty()) {
            vo.setEvidenceUrls(Arrays.asList(entity.getEvidenceUrls().split(",")));
        }

        // TODO: 关联查询以下数据
        // - 题目内容 (t_question)
        // - 学生答案 (t_answer_detail)
        // - 评分要点/扣分依据 (t_answer_detail.grade_remark)
        // - 考试标题/时间 (t_exam)
        // - 学生姓名/教师姓名 (t_employee)
        // - 原考试成绩 (t_score)
        // - 当前题目成绩

        return ResponseDTO.ok(vo);
    }
}
