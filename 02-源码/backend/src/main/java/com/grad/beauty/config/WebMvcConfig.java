package com.grad.beauty.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * 静态资源配置：/uploads/** 指向项目根目录的 uploads/（不是用户主目录）。
 * 需求第 2 条：图片一律本地上传，禁止外链，断网仍可显示。
 *
 * 注意：app.upload-dir 默认是相对路径 ./uploads，实际解析结果取决于启动时的工作目录。
 * 若从 backend/ 目录启动（mvn spring-boot:run 或 cd backend && java -jar），
 * ./uploads 会指向 backend/uploads（不存在），导致 /uploads/** 全部 404、列表页缩略图变灰块。
 * 因此这里做一次「候选目录探测」：同级目录不存在时依次尝试上一级、上两级，取第一个存在的 uploads/。
 */
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Value("${app.upload-dir:./uploads}")
    private String uploadDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String abs = resolveUploadDir();
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:" + abs + "/");
    }

    /** 依次探测 ./uploads、../uploads、../../uploads，返回第一个真实存在的目录；都不存在则用默认值。 */
    private String resolveUploadDir() {
        Path configured = Paths.get(uploadDir).toAbsolutePath().normalize();
        if (Files.isDirectory(configured)) {
            return configured.toString();
        }
        // 配置的是相对路径时，逐级向上找同名的 uploads 目录
        if (!Paths.get(uploadDir).isAbsolute()) {
            Path dir = Paths.get("").toAbsolutePath().normalize();
            for (int i = 0; i < 3 && dir != null; i++) {
                Path candidate = dir.resolve(uploadDir).normalize();
                if (Files.isDirectory(candidate)) {
                    return candidate.toString();
                }
                dir = dir.getParent();
            }
        }
        // 兜底：使用默认值，并在日志里留痕（启动后 /uploads 会 404，便于排查）
        System.err.println("[WebMvcConfig] 未找到 uploads 目录，使用 " + configured
                + File.separator + "（图片可能 404）");
        return configured.toString();
    }
}
