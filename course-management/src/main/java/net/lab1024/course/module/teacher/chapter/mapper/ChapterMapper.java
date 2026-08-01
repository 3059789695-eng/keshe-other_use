package net.lab1024.course.module.teacher.chapter.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import net.lab1024.course.module.teacher.chapter.entity.Chapter;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 章节 Mapper 接口
 */
@Mapper
public interface ChapterMapper extends BaseMapper<Chapter> {

    /**
     * 查询指定父章节下的最大排序值
     *
     * @param parentId 父章节ID
     * @return 最大排序值，若无子章节则返回 0
     */
    @Select("SELECT COALESCE(MAX(sort), 0) FROM teacher_chapter WHERE parent_id = #{parentId} AND is_deleted = 0")
    Integer selectMaxSortByParentId(@Param("parentId") Long parentId);

    /**
     * 查询指定父章节下的所有直接子章节，按 sort 升序排列
     *
     * @param parentId 父章节ID
     * @return 子章节列表
     */
    @Select("SELECT * FROM teacher_chapter WHERE parent_id = #{parentId} AND is_deleted = 0 ORDER BY sort ASC")
    java.util.List<Chapter> selectChildrenByParentId(@Param("parentId") Long parentId);
}
