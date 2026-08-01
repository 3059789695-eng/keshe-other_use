package net.lab1024.course.common.interceptor;

import net.lab1024.course.common.result.Result;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.PrintWriter;

/**
 * 角色鉴权拦截器
 * 通过请求头 role 校验用户身份
 * teacher -> 仅可访问 /api/teacher/ 前缀接口
 * admin  -> 仅可访问 /api/admin/ 前缀接口
 */
@Component
public class RoleInterceptor implements HandlerInterceptor {

    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        String role = request.getHeader("role");
        String uri = request.getRequestURI();

        // 公共接口（教师和管理员都可调用）
        if (uri.startsWith("/api/common/")) {
            return true;
        }

        // 教师角色校验
        if (uri.startsWith("/api/teacher/")) {
            if (!"teacher".equals(role)) {
                writeForbidden(response, "无权访问教师接口，请使用 teacher 角色");
                return false;
            }
            return true;
        }

        // 管理员角色校验
        if (uri.startsWith("/api/admin/")) {
            if (!"admin".equals(role)) {
                writeForbidden(response, "无权访问管理员接口，请使用 admin 角色");
                return false;
            }
            return true;
        }

        return true;
    }

    /**
     * 返回 403 禁止访问响应
     */
    private void writeForbidden(HttpServletResponse response, String msg) throws Exception {
        response.setContentType("application/json;charset=UTF-8");
        response.setStatus(200);
        PrintWriter writer = response.getWriter();
        writer.write(OBJECT_MAPPER.writeValueAsString(Result.forbidden(msg)));
        writer.flush();
        writer.close();
    }
}
