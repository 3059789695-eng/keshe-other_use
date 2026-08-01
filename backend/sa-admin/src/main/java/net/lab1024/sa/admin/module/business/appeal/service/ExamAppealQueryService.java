package net.lab1024.sa.admin.module.business.appeal.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import jakarta.annotation.Resource;
import net.lab1024.sa.admin.module.business.appeal.dao.ExamAppealDao;
import net.lab1024.sa.admin.module.business.appeal.domain.form.AppealQueryForm;
import net.lab1024.sa.admin.module.business.appeal.domain.vo.AppealDetailVO;
import net.lab1024.sa.admin.module.business.appeal.domain.vo.AppealVO;
import net.lab1024.sa.base.common.code.UserErrorCode;
import net.lab1024.sa.base.common.domain.PageResult;
import net.lab1024.sa.base.common.domain.ResponseDTO;
import net.lab1024.sa.base.common.util.SmartPageUtil;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 考试成绩复议查询服务。
 */
@Service
public class ExamAppealQueryService {

    @Resource
    private ExamAppealDao examAppealDao;

    /**
     * 分页查询复议申请。
     */
    public ResponseDTO<PageResult<AppealVO>> queryPage(AppealQueryForm queryForm) {
        Page<?> page = SmartPageUtil.convert2PageQuery(queryForm);
        List<AppealVO> list = examAppealDao.query(page, queryForm);
        return ResponseDTO.ok(SmartPageUtil.convert2PageResult(page, list));
    }

    /**
     * 查询复议申请详情。
     */
    public ResponseDTO<AppealDetailVO> getDetail(Long appealId) {
        AppealDetailVO detail = examAppealDao.queryDetail(appealId);
        if (detail == null) {
            return ResponseDTO.error(UserErrorCode.DATA_NOT_EXIST);
        }
        return ResponseDTO.ok(detail);
    }
}
