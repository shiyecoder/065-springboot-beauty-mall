package com.grad.beauty.controller;

import com.grad.beauty.common.R;
import com.grad.beauty.dto.Reqs;
import com.grad.beauty.service.OrderService;
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

/** 正装订单：下单、支付登记、发货、取消、退款。不接真实支付接口。 */
@RestController
@RequestMapping("/api/makeup-order")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;

    @GetMapping("/page")
    public R<?> page(@RequestParam Map<String, Object> q) {
        return R.ok(orderService.page(q));
    }

    @GetMapping("/{id}")
    public R<?> detail(@PathVariable Long id) {
        return R.ok(orderService.detail(id));
    }

    @PostMapping
    public R<?> create(@Valid @RequestBody Reqs.OrderCreate req) {
        return R.ok(orderService.create(req));
    }

    @PostMapping("/{id}/pay")
    public R<?> pay(@PathVariable Long id, @RequestBody(required = false) Map<String, String> body) {
        return R.ok(orderService.pay(id, body == null ? null : body.get("payType")));
    }

    @PostMapping("/{id}/ship")
    public R<?> ship(@PathVariable Long id) {
        return R.ok(orderService.ship(id));
    }

    @PostMapping("/{id}/cancel")
    public R<?> cancel(@PathVariable Long id) {
        return R.ok(orderService.cancel(id));
    }

    @PostMapping("/{id}/refund")
    public R<?> refund(@PathVariable Long id, @Valid @RequestBody Reqs.Refund req) {
        return R.ok(orderService.refund(id, req));
    }
}
