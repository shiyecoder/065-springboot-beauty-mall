package com.grad.beauty.controller;

import com.grad.beauty.common.R;
import com.grad.beauty.dto.Reqs;
import com.grad.beauty.service.ConvertService;
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

/** 创新点接口：转化评分、规则配置、计算留痕、人工修正、跟进登记、转化看板。 */
@RestController
@RequiredArgsConstructor
public class ConvertController {

    private final ConvertService convertService;

    @GetMapping("/api/convert-track/page")
    public R<?> page(@RequestParam Map<String, Object> q) {
        return R.ok(convertService.trackPage(q));
    }

    @GetMapping("/api/convert-track/{id}/score")
    public R<?> score(@PathVariable Long id) {
        return R.ok(convertService.compute(id));
    }

    @GetMapping("/api/convert-track/{id}/snapshot")
    public R<?> snapshot(@PathVariable Long id) {
        return R.ok(convertService.latestSnapshot(id));
    }

    @PostMapping("/api/convert-track/{id}/follow")
    public R<Void> follow(@PathVariable Long id, @Valid @RequestBody Reqs.Follow req) {
        convertService.follow(id, req);
        return R.ok();
    }

    @PostMapping("/api/convert-track/{id}/correction")
    public R<Void> correction(@PathVariable Long id, @Valid @RequestBody Reqs.Correction req) {
        convertService.correct(id, req);
        return R.ok();
    }

    @GetMapping("/api/convert-rule/current")
    public R<?> currentRule() {
        return R.ok(convertService.currentRule());
    }

    @GetMapping("/api/convert-rule/list")
    public R<?> ruleList() {
        return R.ok(convertService.ruleList());
    }

    @PostMapping("/api/convert-rule")
    public R<?> saveRule(@Valid @RequestBody Reqs.RuleSave req) {
        return R.ok(convertService.saveRule(req));
    }

    @GetMapping("/api/convert-board")
    public R<?> board() {
        return R.ok(convertService.board());
    }
}
