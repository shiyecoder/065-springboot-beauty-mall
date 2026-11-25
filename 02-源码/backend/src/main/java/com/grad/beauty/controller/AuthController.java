package com.grad.beauty.controller;

import com.grad.beauty.common.R;
import com.grad.beauty.dto.Reqs;
import com.grad.beauty.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/** 认证与个人中心：登录、当前用户、菜单、字典、改资料、改密码。 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public R<Map<String, Object>> login(@Valid @RequestBody Reqs.Login req) {
        return R.ok(authService.login(req));
    }

    @GetMapping("/me")
    public R<Map<String, Object>> me() {
        return R.ok(authService.me());
    }

    @GetMapping("/menus")
    public R<?> menus() {
        return R.ok(authService.menusOf(com.grad.beauty.common.UserContext.roleId()));
    }

    @PutMapping("/profile")
    public R<Void> updateProfile(@RequestBody Reqs.Profile req) {
        authService.updateProfile(req);
        return R.ok();
    }

    @PutMapping("/password")
    public R<Void> changePassword(@Valid @RequestBody Reqs.ChangePwd req) {
        authService.changePassword(req);
        return R.ok();
    }
}
