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

/** 试用报告：用户提交、审核员审核、列表查询。 */
@RestController
@RequestMapping("/api/trial-report")
@RequiredArgsConstructor
public class ReportController {

    private final TrialService trialService;

    @GetMapping("/page")
    public R<?> page(@RequestParam Map<String, Object> q) {
        return R.ok(trialService.reportPage(q));
    }

    @PostMapping
    public R<?> create(@Valid @RequestBody Reqs.ReportCreate req) {
        return R.ok(trialService.createReport(req));
    }

    @PostMapping("/{id}/audit")
    public R<?> audit(@PathVariable Long id, @RequestBody Reqs.ReportAudit req) {
        return R.ok(trialService.auditReport(id, req));
    }
}
