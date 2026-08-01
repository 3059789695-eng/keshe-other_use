package net.lab1024.course.common.config;

import net.lab1024.course.common.interceptor.RoleInterceptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Web MVC 配置类
 * 注册拦截器、跨域配置等
 */
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Autowired
    private RoleInterceptor roleInterceptor;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // 角色鉴权拦截器，拦截所有 /api/ 开头的请求
        registry.addInterceptor(roleInterceptor)
                .addPathPatterns("/api/**");
    }
}
