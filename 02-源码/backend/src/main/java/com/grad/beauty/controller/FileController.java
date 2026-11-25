package com.grad.beauty.controller;

import com.grad.beauty.common.BizException;
import com.grad.beauty.common.R;
import com.grad.beauty.common.UserContext;
import com.grad.beauty.entity.SysFile;
import com.grad.beauty.mapper.SysFileMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * 文件上传（需求 7.5）：只允许图片 jpg/jpeg/png/webp，单张 ≤5MB；
 * 校验扩展名 + MIME + 文件头，重命名后按 uploads/{bizType}/{yyyyMM}/{uuid}.{ext} 保存，
 * 返回相对路径，前端只用返回值，禁止填写外链。
 */
@RestController
@RequestMapping("/api/file")
@RequiredArgsConstructor
public class FileController {

    private static final List<String> ALLOW_EXT = List.of("jpg", "jpeg", "png", "webp");
    private static final List<String> ALLOW_MIME = List.of("image/jpeg", "image/png", "image/webp");

    private final SysFileMapper fileMapper;

    @Value("${app.upload-dir:./uploads}")
    private String uploadDir;

    @PostMapping("/upload")
    public R<Map<String, Object>> upload(@RequestParam("file") MultipartFile file,
                                         @RequestParam(value = "bizType", defaultValue = "common") String bizType) {
        if (file == null || file.isEmpty()) {
            throw new BizException(4000, "请选择要上传的文件");
        }
        if (file.getSize() > 5L * 1024 * 1024) {
            throw new BizException(4000, "单张图片不得超过 5MB");
        }
        String name = file.getOriginalFilename() == null ? "file" : file.getOriginalFilename();
        String ext = name.contains(".") ? name.substring(name.lastIndexOf('.') + 1).toLowerCase() : "";
        if (!ALLOW_EXT.contains(ext)) {
            throw new BizException(4000, "只允许 jpg/jpeg/png/webp 图片");
        }
        String mime = file.getContentType() == null ? "" : file.getContentType().toLowerCase();
        if (!ALLOW_MIME.contains(mime)) {
            throw new BizException(4000, "文件类型不合法：" + mime);
        }
        try {
            // 文件头校验，防止改扩展名绕过
            byte[] head = new byte[12];
            try (var in = file.getInputStream()) {
                in.read(head);
            }
            if (!isImage(head)) {
                throw new BizException(4000, "文件内容不是有效图片");
            }
            String month = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMM"));
            Path dir = Paths.get(resolveUploadDir(), bizType, month);
            Files.createDirectories(dir);
            String fileName = UUID.randomUUID().toString().replace("-", "") + "." + ext;
            File target = dir.resolve(fileName).toFile();
            file.transferTo(target);
            String rel = "/uploads/" + bizType + "/" + month + "/" + fileName;

            SysFile rec = new SysFile();
            rec.setFileName(name);
            rec.setFilePath(rel);
            rec.setFileSize(file.getSize());
            rec.setFileType(mime);
            rec.setBizType(bizType);
            rec.setUploaderId(UserContext.userId());
            rec.setCreateTime(LocalDateTime.now());
            fileMapper.insert(rec);

            Map<String, Object> data = new LinkedHashMap<>();
            data.put("fileName", name);
            data.put("filePath", rel);
            data.put("fileSize", file.getSize());
            data.put("fileType", mime);
            return R.ok(data);
        } catch (BizException e) {
            throw e;
        } catch (Exception e) {
            throw new BizException(5000, "上传失败：" + e.getMessage());
        }
    }

    private boolean isImage(byte[] h) {
        if (h.length < 4) {
            return false;
        }
        // JPEG FF D8 FF / PNG 89 50 4E 47 / WEBP RIFF....WEBP
        boolean jpg = (h[0] & 0xFF) == 0xFF && (h[1] & 0xFF) == 0xD8;
        boolean png = (h[0] & 0xFF) == 0x89 && h[1] == 'P' && h[2] == 'N' && h[3] == 'G';
        boolean webp = h.length >= 12 && h[0] == 'R' && h[1] == 'I' && h[2] == 'F' && h[3] == 'F';
        return jpg || png || webp;
    }

    /** 与 WebMvcConfig 同样的向上探测逻辑，保证上传目录与静态映射目录一致 */
    private String resolveUploadDir() {
        Path configured = Paths.get(uploadDir).toAbsolutePath().normalize();
        if (Files.isDirectory(configured)) {
            return configured.toString();
        }
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
        return configured.toString();
    }
}
