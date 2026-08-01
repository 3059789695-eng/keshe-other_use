package net.lab1024.course.module.teacher.chapter.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import net.lab1024.course.module.teacher.chapter.dto.ChapterAddDTO;
import net.lab1024.course.module.teacher.chapter.dto.ChapterEditDTO;
import net.lab1024.course.module.teacher.chapter.entity.Chapter;
import net.lab1024.course.module.teacher.chapter.mapper.ChapterMapper;
import net.lab1024.course.module.teacher.chapter.service.ChapterService;
import net.lab1024.course.module.teacher.chapter.vo.ChapterPageVO;
import net.lab1024.course.module.teacher.chapter.vo.ChapterVO;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 章节 Service 实现类
 */
@Service
public class ChapterServiceImpl implements ChapterService {

    @Autowired
    private ChapterMapper chapterMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void addChapter(ChapterAddDTO addDTO) {
        // 构建实体
        Chapter chapter = new Chapter();
        chapter.setParentId(addDTO.getParentId());
        chapter.setChapterName(addDTO.getChapterName());

        // 如果是顶级章节（parentId=0），需要设置 courseId
        if (addDTO.getParentId() == 0) {
            if (addDTO.getCourseId() == null) {
                throw new IllegalArgumentException("添加顶级章节时，课程ID不能为空");
            }
            chapter.setCourseId(addDTO.getCourseId());
        } else {
            // 子章节继承父章节的 courseId
            Chapter parent = chapterMapper.selectById(addDTO.getParentId());
            if (parent == null || parent.getIsDeleted() == 1) {
                throw new IllegalArgumentException("父章节不存在或已被删除");
            }
            chapter.setCourseId(parent.getCourseId());
        }

        // 自动计算 sort：取当前父级下最大 sort + 1，新增后排在最末尾
        Integer maxSort = chapterMapper.selectMaxSortByParentId(addDTO.getParentId());
        chapter.setSort(maxSort + 1);

        chapterMapper.insert(chapter);
    }

    @Override
    public ChapterPageVO queryTopChapters(Long courseId, Integer pageNum, Integer pageSize) {
        // 分页查询顶级章节（parent_id = 0）
        Page<Chapter> page = new Page<>(pageNum, pageSize);
        LambdaQueryWrapper<Chapter> wrapper = new LambdaQueryWrapper<Chapter>()
                .eq(Chapter::getParentId, 0L)
                .eq(Chapter::getCourseId, courseId)
                .orderByAsc(Chapter::getSort);

        Page<Chapter> result = chapterMapper.selectPage(page, wrapper);

        // 无数据直接返回
        if (result.getRecords().isEmpty()) {
            return ChapterPageVO.noMoreData(pageNum, pageSize);
        }

        // 转换为 VO
        List<ChapterVO> voList = result.getRecords().stream()
                .map(this::convertToVO)
                .collect(Collectors.toList());

        ChapterPageVO pageVO = new ChapterPageVO();
        pageVO.setRecords(voList);
        pageVO.setPageNum((int) result.getCurrent());
        pageVO.setPageSize((int) result.getSize());
        pageVO.setTotal(result.getTotal());
        pageVO.setTotalPages(result.getPages());
        pageVO.setHasMore(result.getCurrent() < result.getPages());
        pageVO.setMessage(pageVO.getHasMore() ? "加载更多" : "已加载全部章节");
        return pageVO;
    }

    @Override
    public List<ChapterVO> queryChildrenChapters(Long parentId) {
        // 查询所有直接子章节
        List<Chapter> children = chapterMapper.selectChildrenByParentId(parentId);
        return children.stream().map(this::convertToVO).collect(Collectors.toList());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void editChapter(ChapterEditDTO editDTO) {
        Chapter chapter = chapterMapper.selectById(editDTO.getId());
        if (chapter == null || chapter.getIsDeleted() == 1) {
            throw new IllegalArgumentException("章节不存在或已被删除");
        }
        // 仅允许修改章节名称
        chapter.setChapterName(editDTO.getChapterName());
        chapterMapper.updateById(chapter);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteChapter(Long id) {
        Chapter chapter = chapterMapper.selectById(id);
        if (chapter == null || chapter.getIsDeleted() == 1) {
            throw new IllegalArgumentException("章节不存在或已被删除");
        }
        // 1. 逻辑删除当前章节
        chapterMapper.deleteById(id); // MyBatis-Plus @TableLogic 自动逻辑删除

        // 2. 递归逻辑删除所有子孙章节（MySQL 5.7 不支持 WITH RECURSIVE，用 Java 递归实现）
        logicDeleteChildren(id);
    }

    /**
     * 递归删除所有子孙章节（Java 层递归实现）
     *
     * @param parentId 父章节ID
     */
    private void logicDeleteChildren(Long parentId) {
        List<Chapter> children = chapterMapper.selectChildrenByParentId(parentId);
        for (Chapter child : children) {
            chapterMapper.deleteById(child.getId()); // 逻辑删除
            // 递归删除子章节的子孙
            logicDeleteChildren(child.getId());
        }
    }

    /**
     * 将 Chapter 实体转换为 ChapterVO
     */
    private ChapterVO convertToVO(Chapter chapter) {
        ChapterVO vo = new ChapterVO();
        BeanUtils.copyProperties(chapter, vo);
        // 查询是否有子章节
        List<Chapter> children = chapterMapper.selectChildrenByParentId(chapter.getId());
        vo.setHasChildren(!children.isEmpty());
        vo.setChildrenCount(children.size());
        return vo;
    }
}
