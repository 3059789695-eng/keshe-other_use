package net.lab1024.sa.admin.module.business.score.dao;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import net.lab1024.sa.admin.module.business.score.domain.form.ExamQueryForm;
import net.lab1024.sa.admin.module.business.score.domain.form.ExamStudentQueryForm;
import net.lab1024.sa.admin.module.business.score.domain.vo.*;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 考试完成情况与成绩统计数据访问接口。
 */
@Mapper
public interface ExamStatisticsDao {

    List<ExamListVO> queryExam(Page<?> page, @Param("query") ExamQueryForm query);

    ExamStatisticsVO queryStatistics(@Param("examId") Long examId);

    List<ScoreRangeVO> queryScoreDistribution(@Param("examId") Long examId);

    List<StudentScoreVO> queryStudent(Page<?> page, @Param("query") ExamStudentQueryForm query);

    StudentAnswerDetailVO queryAnswerDetail(@Param("examId") Long examId, @Param("studentId") Long studentId);

    List<AnswerItemVO> queryAnswerItems(@Param("examRecordId") Long examRecordId);

    List<StudentScoreExcelVO> queryAllStudentScores(@Param("examId") Long examId);

    List<UnfinishedStudentExcelVO> queryUnfinishedStudents(@Param("examId") Long examId);
}
