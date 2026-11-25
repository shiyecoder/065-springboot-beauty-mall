package com.grad.beauty.controller;

import com.grad.beauty.common.R;
import com.grad.beauty.dto.Reqs;
import com.grad.beauty.service.TrialService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/** 试用申领：提交、审核、发放、详情。所有状态流转由后端状态机校验。 */
@RestController
@RequestMapping("/api/sample-apply")
@RequiredArgsConstructor
public class ApplyController {

    private final TrialService trialService;

    @GetMapping("/page")
    public R<?> page(@RequestParam Map<String, Object> q) {
        return R.ok(trialService.applyPage(q));
    }

    @GetMapping("/{id}")
    public R<?> detail(@PathVariable Long id) {
        return R.ok(trialService.applyDetail(id));
    }

    @PostMapping
    public R<?> create(@Valid @RequestBody Reqs.ApplyCreate req) {
        return R.ok(trialService.createApply(req));
    }

    @PostMapping("/{id}/audit")
    public R<?> audit(@PathVariable Long id, @RequestBody Reqs.ApplyAudit req) {
        return R.ok(trialService.auditApply(id, req));
    }

    @PostMapping("/{id}/send")
    public R<?> send(@PathVariable Long id, @Valid @RequestBody Reqs.ApplySend req) {
        return R.ok(trialService.sendApply(id, req));
    }

    @PostMapping("/{id}/require-profile")
    public R<Void> requireProfile(@PathVariable Long id, @RequestBody Map<String, String> body) {
        trialService.requireProfile(id, body.get("reason"));
        return R.ok();
    }
}
