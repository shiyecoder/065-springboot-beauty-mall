package com.grad.beauty.controller;

import com.grad.beauty.common.R;
import com.grad.beauty.service.DashboardService;
import com.grad.beauty.service.GoodsService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 数据看板与试用效果报表。 */
@RestController
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;
    private final GoodsService goodsService;

    @GetMapping("/api/dashboard/overview")
    public R<?> overview() {
        return R.ok(dashboardService.overview());
    }

    @GetMapping("/api/dashboard/stock-warning")
    public R<?> stockWarning() {
        return R.ok(goodsService.stockWarnings());
    }

    @GetMapping("/api/stat/report")
    public R<?> report() {
        return R.ok(dashboardService.report());
    }
}
