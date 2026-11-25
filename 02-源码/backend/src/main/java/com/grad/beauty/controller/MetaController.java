package com.grad.beauty.controller;

import com.grad.beauty.common.R;
import com.grad.beauty.service.AuthService;
import com.grad.beauty.service.SystemService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 公共元数据：字典、公告。前端登录后缓存一次，下拉统一从这里取。 */
@RestController
@RequestMapping("/api/meta")
@RequiredArgsConstructor
public class MetaController {

    private final AuthService authService;
    private final SystemService systemService;

    @GetMapping("/dicts")
    public R<?> dicts() {
        return R.ok(authService.dictMap());
    }

    @GetMapping("/notices")
    public R<?> notices() {
        return R.ok(systemService.notices());
    }
}
