package net.lab1024.course.module.teacher.chapter.controller;

import net.lab1024.course.common.result.Result;
import net.lab1024.course.module.teacher.chapter.dto.ChapterAddDTO;
import net.lab1024.course.module.teacher.chapter.dto.ChapterEditDTO;
import net.lab1024.course.module.teacher.chapter.service.ChapterService;
import net.lab1024.course.module.teacher.chapter.vo.ChapterPageVO;
import net.lab1024.course.module.teacher.chapter.vo.ChapterVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;

/**
 * 教师端 - 课程章节管理 Controller
 *
 * 接口前缀：/api/teacher/chapter
 * 角色要求：请求头 role=teacher
 */
@RestController
@RequestMapping("/api/teacher/chapter")
public class ChapterController {

    @Autowired
    private ChapterService chapterService;

    /**
     * 1. 添加章节（顶级或子章节）
     * POST /api/teacher/chapter/add
     */
    @PostMapping("/add")
    public Result<Void> addChapter(@Valid @RequestBody ChapterAddDTO addDTO) {
        chapterService.addChapter(addDTO);
        return Result.success();
    }

    /**
     * 2. 分页查询顶级章节列表（加载更多）
     * GET /api/teacher/chapter/page?courseId=1&pageNum=1&pageSize=10
     */
    @GetMapping("/page")
    public Result<ChapterPageVO> queryPage(
            @RequestParam Long courseId,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        ChapterPageVO pageVO = chapterService.queryTopChapters(courseId, pageNum, pageSize);
        return Result.success(pageVO);
    }

    /**
     * 3. 展开查询子章节
     * GET /api/teacher/chapter/children?parentId=1
     */
    @GetMapping("/children")
    public Result<List<ChapterVO>> queryChildren(@RequestParam Long parentId) {
        List<ChapterVO> list = chapterService.queryChildrenChapters(parentId);
        return Result.success(list);
    }

    /**
     * 4. 编辑章节名称
     * PUT /api/teacher/chapter/edit
     */
    @PutMapping("/edit")
    public Result<Void> editChapter(@Valid @RequestBody ChapterEditDTO editDTO) {
        chapterService.editChapter(editDTO);
        return Result.success();
    }

    /**
     * 5. 删除章节（逻辑删除，含递归子树）
     * DELETE /api/teacher/chapter/delete/{id}
     */
    @DeleteMapping("/delete/{id}")
    public Result<Void> deleteChapter(@PathVariable Long id) {
        chapterService.deleteChapter(id);
        return Result.success("删除成功", null);
    }
}
