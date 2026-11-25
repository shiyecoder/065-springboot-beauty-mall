package com.grad.beauty.controller;

import com.grad.beauty.common.R;
import com.grad.beauty.service.SystemService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/** 系统管理：用户、角色与分配菜单、菜单树、字典、日志、消息、公告。 */
@RestController
@RequestMapping("/api/system")
@RequiredArgsConstructor
public class SystemController {

    private final SystemService systemService;

    @GetMapping("/user/page")
    public R<?> users(@RequestParam Map<String, Object> q) {
        return R.ok(systemService.userPage(q));
    }

    @PostMapping("/user")
    public R<Long> saveUser(@RequestBody Map<String, Object> body) {
        return R.ok(systemService.saveUser(body));
    }

    @PostMapping("/user/{id}/reset")
    public R<Void> reset(@PathVariable Long id) {
        systemService.resetPassword(id);
        return R.ok();
    }

    @GetMapping("/role/list")
    public R<?> roles() {
        return R.ok(systemService.roleList());
    }

    @PostMapping("/role/{id}/menus")
    public R<Void> assignMenus(@PathVariable Long id, @RequestBody Map<String, List<Long>> body) {
        systemService.assignMenus(id, body.getOrDefault("menuIds", List.of()));
        return R.ok();
    }

    @GetMapping("/menu/tree")
    public R<?> menuTree() {
        return R.ok(systemService.menuTree());
    }

    @GetMapping("/dict/list")
    public R<?> dicts() {
        return R.ok(systemService.dictList());
    }

    @GetMapping("/log/page")
    public R<?> logs(@RequestParam Map<String, Object> q) {
        return R.ok(systemService.logPage(q));
    }

    @GetMapping("/message/list")
    public R<?> messages() {
        return R.ok(systemService.myMessages());
    }

    @PostMapping("/message/{id}/read")
    public R<Void> read(@PathVariable Long id) {
        systemService.readMessage(id);
        return R.ok();
    }

    @PostMapping("/message/read-all")
    public R<Void> readAll() {
        systemService.readAll();
        return R.ok();
    }

    @GetMapping("/notice/list")
    public R<?> notices() {
        return R.ok(systemService.notices());
    }
}
