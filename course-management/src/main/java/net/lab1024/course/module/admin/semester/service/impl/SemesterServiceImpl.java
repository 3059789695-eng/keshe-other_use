package net.lab1024.course.module.admin.semester.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import net.lab1024.course.module.admin.semester.dto.SemesterAddDTO;
import net.lab1024.course.module.admin.semester.dto.SemesterEditDTO;
import net.lab1024.course.module.admin.semester.entity.Semester;
import net.lab1024.course.module.admin.semester.mapper.SemesterMapper;
import net.lab1024.course.module.admin.semester.service.SemesterService;
import net.lab1024.course.module.admin.semester.vo.SemesterVO;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 学期 Service 实现类
 */
@Service
public class SemesterServiceImpl implements SemesterService {

    @Autowired
    private SemesterMapper semesterMapper;

    @Override
    public void addSemester(SemesterAddDTO addDTO) {
        Semester semester = new Semester();
        BeanUtils.copyProperties(addDTO, semester);
        semesterMapper.insert(semester);
    }

    @Override
    public void editSemester(SemesterEditDTO editDTO) {
        Semester semester = semesterMapper.selectById(editDTO.getId());
        if (semester == null) {
            throw new IllegalArgumentException("学期不存在");
        }
        BeanUtils.copyProperties(editDTO, semester);
        semesterMapper.updateById(semester);
    }

    @Override
    public List<SemesterVO> listSemesters() {
        // 查询所有未删除的学期，按创建时间倒序
        LambdaQueryWrapper<Semester> wrapper = new LambdaQueryWrapper<Semester>()
                .orderByDesc(Semester::getCreateTime);
        List<Semester> list = semesterMapper.selectList(wrapper);
        return list.stream().map(this::convertToVO).collect(Collectors.toList());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void toggleSemester(Long id, boolean enable) {
        Semester semester = semesterMapper.selectById(id);
        if (semester == null) {
            throw new IllegalArgumentException("学期不存在");
        }
        if (enable) {
            // 启用：设置 is_deleted = 0
            semester.setIsDeleted(0);
        } else {
            // 禁用：设置 is_deleted = 1
            semester.setIsDeleted(1);
        }
        semesterMapper.updateById(semester);
    }

    private SemesterVO convertToVO(Semester semester) {
        SemesterVO vo = new SemesterVO();
        BeanUtils.copyProperties(semester, vo);
        return vo;
    }
}
