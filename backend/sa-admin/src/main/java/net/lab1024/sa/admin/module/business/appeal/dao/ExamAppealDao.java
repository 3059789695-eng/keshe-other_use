package net.lab1024.sa.admin.module.business.appeal.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import net.lab1024.sa.admin.module.business.appeal.domain.entity.ExamAppealEntity;
import net.lab1024.sa.admin.module.business.appeal.domain.form.AppealQueryForm;
import net.lab1024.sa.admin.module.business.appeal.domain.vo.AppealDetailVO;
import net.lab1024.sa.admin.module.business.appeal.domain.vo.AppealVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.math.BigDecimal;
import java.util.List;

/**
 * 成绩复议数据访问接口。
 */
@Mapper
public interface ExamAppealDao extends BaseMapper<ExamAppealEntity> {

    List<AppealVO> query(Page<?> page, @Param("query") AppealQueryForm query);

    AppealDetailVO queryDetail(@Param("appealId") Long appealId);

    int updateReview(@Param("appealId") Long appealId,
                     @Param("reviewResult") Integer reviewResult,
                     @Param("adjustedScore") BigDecimal adjustedScore,
                     @Param("teacherOpinion") String teacherOpinion,
                     @Param("reviewerId") Long reviewerId);

    int insertReviewNotice(@Param("appealId") Long appealId);
}
