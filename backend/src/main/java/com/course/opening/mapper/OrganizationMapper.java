/*
 * 文件：OrganizationMapper.java
 * 包路径：com.course.opening.mapper
 */
package com.course.opening.mapper;

import com.course.opening.entity.Organization;
import com.course.opening.vo.ClassOptionVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 组织/班级 Dao。
 */
@Mapper
public interface OrganizationMapper {
    Organization selectById(@Param("id") Integer id);
    List<ClassOptionVO> selectClassOptions();
}
