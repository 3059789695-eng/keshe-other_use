package net.lab1024.course.module.admin.semester.dto;

import lombok.Data;
import org.springframework.format.annotation.DateTimeFormat;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import java.time.LocalDate;

/**
 * 新增学期 DTO
 */
@Data
public class SemesterAddDTO {

    /** 学期名称 */
    @NotBlank(message = "学期名称不能为空")
    private String semesterName;

    /** 开始日期 */
    @NotNull(message = "开始日期不能为空")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    private LocalDate startDate;

    /** 结束日期 */
    @NotNull(message = "结束日期不能为空")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    private LocalDate endDate;
}
