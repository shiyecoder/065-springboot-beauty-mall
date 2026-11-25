package com.grad.beauty.controller;

import com.grad.beauty.common.R;
import com.grad.beauty.dto.Reqs;
import com.grad.beauty.service.GoodsService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/** 商品与试用装接口（需求 7.2）。 */
@RestController
@RequiredArgsConstructor
public class GoodsController {

    private final GoodsService goodsService;

    @GetMapping("/api/cosmetic-goods/page")
    public R<?> goodsPage(@RequestParam Map<String, Object> q) {
        return R.ok(goodsService.goodsPage(q));
    }

    @GetMapping("/api/cosmetic-goods/{id}")
    public R<?> goodsDetail(@PathVariable Long id) {
        return R.ok(goodsService.goodsDetail(id));
    }

    @PostMapping("/api/cosmetic-goods")
    public R<Long> addGoods(@RequestBody Reqs.Goods req) {
        return R.ok(goodsService.saveGoods(null, req));
    }

    @PutMapping("/api/cosmetic-goods/{id}")
    public R<Long> editGoods(@PathVariable Long id, @RequestBody Reqs.Goods req) {
        return R.ok(goodsService.saveGoods(id, req));
    }

    @DeleteMapping("/api/cosmetic-goods/{id}")
    public R<Void> delGoods(@PathVariable Long id) {
        goodsService.deleteGoods(id);
        return R.ok();
    }

    @GetMapping("/api/sample-sku/page")
    public R<?> samplePage(@RequestParam Map<String, Object> q) {
        return R.ok(goodsService.samplePage(q));
    }

    @GetMapping("/api/sample-sku/{id}")
    public R<?> sampleDetail(@PathVariable Long id) {
        return R.ok(goodsService.sampleDetail(id));
    }

    @PostMapping("/api/sample-sku")
    public R<Long> addSample(@Valid @RequestBody Reqs.Sample req) {
        return R.ok(goodsService.saveSample(null, req));
    }

    @PutMapping("/api/sample-sku/{id}")
    public R<Long> editSample(@PathVariable Long id, @RequestBody Reqs.Sample req) {
        return R.ok(goodsService.saveSample(id, req));
    }

    @DeleteMapping("/api/sample-sku/{id}")
    public R<Void> delSample(@PathVariable Long id) {
        goodsService.deleteGoods(id);
        return R.ok();
    }

    @PostMapping("/api/sample-sku/stock")
    public R<Void> stockChange(@Valid @RequestBody Reqs.StockChange req) {
        goodsService.stockChange(req);
        return R.ok();
    }

    @GetMapping("/api/sample-sku/log/page")
    public R<?> stockLogs(@RequestParam Map<String, Object> q) {
        return R.ok(goodsService.stockLogPage(q));
    }
}
