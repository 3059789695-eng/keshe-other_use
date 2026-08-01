package net.lab1024.course.module.teacher.chapter.vo;

import lombok.Data;
import java.util.List;

/**
 * 章节分页返回 VO（加载更多）
 */
@Data
public class ChapterPageVO {

    /** 当前页章节列表 */
    private List<ChapterVO> records;

    /** 当前页码 */
    private Integer pageNum;

    /** 每页条数 */
    private Integer pageSize;

    /** 总记录数 */
    private Long total;

    /** 总页数 */
    private Long totalPages;

    /** 是否还有更多数据 */
    private Boolean hasMore;

    /** 提示文案 */
    private String message;

    /**
     * 构造没有更多数据时的返回
     */
    public static ChapterPageVO noMoreData(int pageNum, int pageSize) {
        ChapterPageVO vo = new ChapterPageVO();
        vo.setRecords(List.of());
        vo.setPageNum(pageNum);
        vo.setPageSize(pageSize);
        vo.setTotal(0L);
        vo.setTotalPages(0L);
        vo.setHasMore(false);
        vo.setMessage("暂无更多章节，请主动添加顶级章节或子章节");
        return vo;
    }
}
