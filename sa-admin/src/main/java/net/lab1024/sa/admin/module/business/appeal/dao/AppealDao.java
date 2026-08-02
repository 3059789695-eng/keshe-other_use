package net.lab1024.sa.admin.module.business.appeal.dao;

import net.lab1024.sa.admin.module.business.appeal.domain.entity.AppealEntity;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 复议申请 Dao（纯 MyBatis）
 */
@Mapper
public interface AppealDao {

    int insert(AppealEntity entity);

    AppealEntity selectById(Long appealId);

    /**
     * 查询某道题最新的一条复议记录
     */
    AppealEntity selectLatestByAnswerDetailId(Long answerDetailId);

    /**
     * 根据答案详情 ID 和学生 ID 查询是否已提交过复议
     */
    AppealEntity selectByAnswerDetailAndStudent(@Param("answerDetailId") Long answerDetailId,
                                                 @Param("studentId") Long studentId);

    List<AppealEntity> selectByStudentId(Long studentId);

    List<AppealEntity> selectByExamIdsAndStudent(@Param("examIds") List<Long> examIds,
                                                  @Param("studentId") Long studentId);

    /**
     * 分页查询用：按学生 ID + 可选考试 ID + 可选状态 筛选
     */
    List<AppealEntity> selectByCondition(@Param("studentId") Long studentId,
                                          @Param("examId") Long examId,
                                          @Param("status") Integer status);
}
