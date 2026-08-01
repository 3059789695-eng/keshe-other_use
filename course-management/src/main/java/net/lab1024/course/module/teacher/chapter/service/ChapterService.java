package net.lab1024.course.module.teacher.chapter.service;

import net.lab1024.course.module.teacher.chapter.dto.ChapterAddDTO;
import net.lab1024.course.module.teacher.chapter.dto.ChapterEditDTO;
import net.lab1024.course.module.teacher.chapter.vo.ChapterPageVO;
import net.lab1024.course.module.teacher.chapter.vo.ChapterVO;

import java.util.List;

/**
 * 章节 Service 接口
 */
public interface ChapterService {

    /**
     * 添加顶级章节或子章节
     */
    void addChapter(ChapterAddDTO addDTO);

    /**
     * 分页查询顶级章节列表（加载更多）
     */
    ChapterPageVO queryTopChapters(Long courseId, Integer pageNum, Integer pageSize);

    /**
     * 展开查询子章节
     */
    List<ChapterVO> queryChildrenChapters(Long parentId);

    /**
     * 编辑章节名称
     */
    void editChapter(ChapterEditDTO editDTO);

    /**
     * 删除章节（逻辑删除，递归删除所有子孙章节）
     */
    void deleteChapter(Long id);
}
