package net.lab1024.course.module.admin.semester.service;

import net.lab1024.course.module.admin.semester.dto.SemesterAddDTO;
import net.lab1024.course.module.admin.semester.dto.SemesterEditDTO;
import net.lab1024.course.module.admin.semester.vo.SemesterVO;

import java.util.List;

/**
 * 学期 Service 接口
 */
public interface SemesterService {

    /**
     * 新增学期
     */
    void addSemester(SemesterAddDTO addDTO);

    /**
     * 编辑学期
     */
    void editSemester(SemesterEditDTO editDTO);

    /**
     * 查询学期下拉列表（所有未删除的学期）
     */
    List<SemesterVO> listSemesters();

    /**
     * 禁用/启用学期（逻辑删除等价于禁用）
     *
     * @param id    学期ID
     * @param enable true=启用（恢复），false=禁用（删除）
     */
    void toggleSemester(Long id, boolean enable);
}
