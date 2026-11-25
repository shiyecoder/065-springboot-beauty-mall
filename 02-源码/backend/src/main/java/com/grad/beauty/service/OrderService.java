package com.grad.beauty.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.grad.beauty.common.BizException;
import com.grad.beauty.common.PageResult;
import com.grad.beauty.common.UserContext;
import com.grad.beauty.dto.Reqs;
import com.grad.beauty.entity.CosmeticGoods;
import com.grad.beauty.entity.ConvertTrack;
import com.grad.beauty.entity.MakeupOrder;
import com.grad.beauty.entity.SampleApply;
import com.grad.beauty.entity.SampleSku;
import com.grad.beauty.entity.TrialReport;
import com.grad.beauty.mapper.CosmeticGoodsMapper;
import com.grad.beauty.mapper.ConvertTrackMapper;
import com.grad.beauty.mapper.MakeupOrderMapper;
import com.grad.beauty.mapper.SampleApplyMapper;
import com.grad.beauty.mapper.SampleSkuMapper;
import com.grad.beauty.mapper.TrialReportMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

/**
 * 正装订单服务（需求 5.6）：
 * - 下单校验库存与限购（单用户单商品 30 天内最多 5 件），超限后端拒绝
 * - 支付只登记方式与状态，不接真实支付
 * - 支付超时 30 分钟自动取消并回补库存
 * - 下单时若来源申领单在归因窗口内，自动回填转化订单；退款冲减转化记录
 */
@Service
@RequiredArgsConstructor
public class OrderService {

    private final MakeupOrderMapper orderMapper;
    private final CosmeticGoodsMapper goodsMapper;
    private final SampleApplyMapper applyMapper;
    private final SampleSkuMapper skuMapper;
    private final ConvertTrackMapper trackMapper;
    private final TrialReportMapper reportMapper;
    private final TrialService trialService;

    public PageResult<Map<String, Object>> page(Map<String, Object> q) {
        long page = num(q.get("page"), 1), size = Math.min(num(q.get("size"), 10), 100);
        LambdaQueryWrapper<MakeupOrder> w = new LambdaQueryWrapper<MakeupOrder>()
                .orderByDesc(MakeupOrder::getCreateTime);
        if (UserContext.isTrialUser()) {
            w.eq(MakeupOrder::getUserId, UserContext.userId());
        }
        if (!str(q.get("status")).isEmpty()) {
            w.eq(MakeupOrder::getStatus, str(q.get("status")));
        }
        String kw = str(q.get("keyword"));
        if (!kw.isEmpty()) {
            w.and(x -> x.like(MakeupOrder::getOrderNo, kw));
        }
        if ("trial".equals(str(q.get("source")))) {
            w.isNotNull(MakeupOrder::getSourceApplyId);
        } else if ("direct".equals(str(q.get("source")))) {
            w.isNull(MakeupOrder::getSourceApplyId);
        }
        Page<MakeupOrder> p = orderMapper.selectPage(new Page<>(page, size), w);
        List<Map<String, Object>> rows = p.getRecords().stream().map(this::vo).collect(Collectors.toList());
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    public Map<String, Object> vo(MakeupOrder o) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", o.getId());
        m.put("orderNo", o.getOrderNo());
        m.put("userId", o.getUserId());
        m.put("userName", userName(o.getUserId()));
        CosmeticGoods g = goodsMapper.selectById(o.getGoodsId());
        m.put("goodsId", o.getGoodsId());
        m.put("goodsName", g == null ? "" : g.getGoodsName());
        m.put("goodsCover", g == null ? null : g.getCoverImage());
        m.put("goodsType", g == null ? "" : g.getGoodsType());
        m.put("buyQty", o.getBuyQty());
        m.put("goodsAmount", o.getGoodsAmount());
        m.put("discountAmount", o.getDiscountAmount());
        m.put("payAmount", o.getPayAmount());
        m.put("sourceApplyId", o.getSourceApplyId());
        if (o.getSourceApplyId() != null) {
            SampleApply a = applyMapper.selectById(o.getSourceApplyId());
            m.put("sourceApplyNo", a == null ? null : a.getApplyNo());
            if (a != null && a.getSendTime() != null) {
                LocalDate end = a.getSendTime().toLocalDate().plusDays(30);
                m.put("attributionEnd", end);
                m.put("inWindow", !end.isBefore(LocalDate.now()));
            }
        }
        m.put("payType", o.getPayType());
        m.put("payStatus", o.getPayStatus());
        m.put("status", o.getStatus());
        m.put("createTime", o.getCreateTime());
        return m;
    }

    public Map<String, Object> detail(Long id) {
        MakeupOrder o = orderMapper.selectById(id);
        if (o == null) {
            throw new BizException(4000, "订单不存在");
        }
        if (UserContext.isTrialUser() && !o.getUserId().equals(UserContext.userId())) {
            throw new BizException(4003, "无权查看他人订单");
        }
        Map<String, Object> m = vo(o);
        // 关联链路：申领 → 报告 → 转化 → 订单
        if (o.getSourceApplyId() != null) {
            SampleApply a = applyMapper.selectById(o.getSourceApplyId());
            SampleSku s = a == null ? null : skuMapper.selectById(a.getSampleId());
            m.put("chain", Map.of(
                    "applyNo", a == null ? "" : a.getApplyNo(),
                    "sendTime", a == null ? null : a.getSendTime(),
                    "applyStatus", a == null ? "" : a.getStatus(),
                    "sampleNo", s == null ? "" : s.getSampleNo()));
            TrialReport r = reportMapper.selectOne(new LambdaQueryWrapper<TrialReport>()
                    .eq(TrialReport::getApplyId, o.getSourceApplyId()).last("limit 1"));
            m.put("reportNo", r == null ? null : r.getReportNo());
            ConvertTrack t = trackMapper.selectOne(new LambdaQueryWrapper<ConvertTrack>()
                    .eq(ConvertTrack::getApplyId, o.getSourceApplyId()).last("limit 1"));
            m.put("convertScore", t == null ? null : t.getConvertScore());
            m.put("convertLevel", t == null ? null : t.getConvertLevel());
        }
        return m;
    }

    /**
     * 下单：校验库存与 30 天限购；扣减库存；命中归因窗口则回填转化。
     * 支付超时 30 分钟由定时任务取消并回补。
     */
    @Transactional
    public Map<String, Object> create(Reqs.OrderCreate req) {
        CosmeticGoods g = goodsMapper.selectById(req.goodsId());
        if (g == null) {
            throw new BizException(4000, "商品不存在");
        }
        if (req.buyQty() < 1 || req.buyQty() > 10) {
            throw new BizException(4000, "购买件数必须在 1-10 之间");
        }
        if (g.getStockQty() == null || g.getStockQty() < req.buyQty()) {
            throw new BizException(4009, "正装库存不足，当前仅剩 " + (g.getStockQty() == null ? 0 : g.getStockQty()) + " 件");
        }
        // 单用户单商品 30 天内最多 5 件（不含已取消）
        List<MakeupOrder> recent = orderMapper.selectList(new LambdaQueryWrapper<MakeupOrder>()
                .eq(MakeupOrder::getUserId, UserContext.userId())
                .eq(MakeupOrder::getGoodsId, req.goodsId())
                .ne(MakeupOrder::getStatus, "已取消")
                .ge(MakeupOrder::getCreateTime, LocalDateTime.now().minusDays(30)));
        int bought = recent.stream().mapToInt(o -> o.getBuyQty() == null ? 0 : o.getBuyQty()).sum();
        if (bought + req.buyQty() > 5) {
            throw new BizException(4009, "单用户单商品 30 天内最多购买 5 件，你已购买 " + bought + " 件");
        }
        // 来源申领单：必须在归因窗口内且属于本人
        SampleApply src = null;
        if (req.sourceApplyNo() != null && !req.sourceApplyNo().isBlank()) {
            src = applyMapper.selectOne(new LambdaQueryWrapper<SampleApply>()
                    .eq(SampleApply::getApplyNo, req.sourceApplyNo().trim()).last("limit 1"));
            if (src == null || !src.getUserId().equals(UserContext.userId())) {
                throw new BizException(4000, "来源申领单不存在或不属于本人");
            }
            if (src.getSendTime() != null
                    && src.getSendTime().toLocalDate().plusDays(30).isBefore(LocalDate.now())) {
                throw new BizException(4001, "该申领单已超出 30 天归因窗口，订单不计入本次试用转化");
            }
        }
        BigDecimal goodsAmount = g.getSalePrice().multiply(BigDecimal.valueOf(req.buyQty()))
                .setScale(2, RoundingMode.HALF_UP);
        // 优惠：来源申领单的报告已通过则享 8% 试用报告券，不超过商品金额
        BigDecimal discount = BigDecimal.ZERO;
        if (src != null) {
            Long passed = reportMapper.selectCount(new LambdaQueryWrapper<TrialReport>()
                    .eq(TrialReport::getApplyId, src.getId()).eq(TrialReport::getStatus, "已通过"));
            if (passed != null && passed > 0) {
                discount = goodsAmount.multiply(new BigDecimal("0.08")).setScale(2, RoundingMode.HALF_UP);
            }
        }
        BigDecimal pay = goodsAmount.subtract(discount);
        if (pay.compareTo(BigDecimal.ZERO) < 0) {
            throw new BizException(4000, "优惠金额不能超过商品金额");
        }
        MakeupOrder o = new MakeupOrder();
        o.setOrderNo("ZD" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyMMdd"))
                + String.format("%06d", ThreadLocalRandom.current().nextInt(1, 999999)));
        o.setUserId(UserContext.userId());
        o.setGoodsId(req.goodsId());
        o.setBuyQty(req.buyQty());
        o.setGoodsAmount(goodsAmount);
        o.setDiscountAmount(discount);
        o.setPayAmount(pay);
        o.setSourceApplyId(src == null ? null : src.getId());
        o.setPayType(req.payType());
        o.setPayStatus("未支付");
        o.setStatus("待支付");
        o.setCreateBy(UserContext.userId());
        orderMapper.insert(o);
        // 下单即锁库存
        g.setStockQty(g.getStockQty() - req.buyQty());
        if (g.getStockQty() == 0) {
            g.setStatus("已售罄");
        }
        goodsMapper.updateById(g);
        trialService.operLog("正装下单", "新增", o.getOrderNo(),
                "商品 " + g.getGoodsName() + " × " + req.buyQty() + "，实付 " + pay);
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("id", o.getId());
        r.put("orderNo", o.getOrderNo());
        r.put("payAmount", pay);
        r.put("status", o.getStatus());
        return r;
    }

    /** 支付登记：待支付 → 待发货，回填转化归因 */
    @Transactional
    public Map<String, Object> pay(Long id, String payType) {
        MakeupOrder o = mustGet(id);
        if (!"待支付".equals(o.getStatus())) {
            throw new BizException(4001, "当前状态「" + o.getStatus() + "」不允许支付");
        }
        o.setStatus("待发货");
        o.setPayStatus("已支付");
        if (payType != null && !payType.isBlank()) {
            o.setPayType(payType);
        }
        orderMapper.updateById(o);
        // 归因：来源申领单在窗口内则回填转化订单
        if (o.getSourceApplyId() != null) {
            ConvertTrack t = trackMapper.selectOne(new LambdaQueryWrapper<ConvertTrack>()
                    .eq(ConvertTrack::getApplyId, o.getSourceApplyId()).last("limit 1"));
            if (t != null && !t.getAttributionEnd().isBefore(LocalDate.now())) {
                t.setOrderId(o.getId());
                t.setFollowStatus("已下单");
                trackMapper.updateById(t);
            }
        }
        trialService.operLog("正装订单", "支付", o.getOrderNo(), "支付方式 " + o.getPayType());
        return Map.of("id", id, "status", o.getStatus());
    }

    @Transactional
    public Map<String, Object> ship(Long id) {
        MakeupOrder o = mustGet(id);
        if (!"待发货".equals(o.getStatus())) {
            throw new BizException(4001, "只有待发货订单可以发货");
        }
        o.setStatus("已发货");
        orderMapper.updateById(o);
        trialService.operLog("正装订单", "发货", o.getOrderNo(), "状态 待发货 → 已发货");
        return Map.of("id", id, "status", o.getStatus());
    }

    @Transactional
    public Map<String, Object> cancel(Long id) {
        MakeupOrder o = mustGet(id);
        if (!"待支付".equals(o.getStatus())) {
            throw new BizException(4001, "只有待支付订单可以取消");
        }
        restoreStock(o);
        o.setStatus("已取消");
        o.setPayStatus("未支付");
        orderMapper.updateById(o);
        trialService.operLog("正装订单", "取消", o.getOrderNo(), "取消订单并回补库存");
        return Map.of("id", id, "status", o.getStatus());
    }

    /** 退款：回补库存 + 冲减转化记录（转化率分母仍为审核通过的申领单） */
    @Transactional
    public Map<String, Object> refund(Long id, Reqs.Refund req) {
        MakeupOrder o = mustGet(id);
        if (List.of("已退款", "已取消", "待支付").contains(o.getStatus())) {
            throw new BizException(4001, "当前状态「" + o.getStatus() + "」不允许退款");
        }
        if (req.reason() == null || req.reason().trim().length() < 5) {
            throw new BizException(4000, "退款原因不少于 5 字");
        }
        restoreStock(o);
        o.setStatus("已退款");
        o.setPayStatus("已退款");
        orderMapper.updateById(o);
        if (o.getSourceApplyId() != null) {
            ConvertTrack t = trackMapper.selectOne(new LambdaQueryWrapper<ConvertTrack>()
                    .eq(ConvertTrack::getApplyId, o.getSourceApplyId()).last("limit 1"));
            if (t != null && t.getOrderId() != null && t.getOrderId().equals(o.getId())) {
                t.setOrderId(null);
                t.setFollowStatus("已放弃");
                trackMapper.updateById(t);
            }
        }
        trialService.operLog("正装订单", "退款", o.getOrderNo(), "退款原因：" + req.reason().trim());
        return Map.of("id", id, "status", o.getStatus());
    }

    private void restoreStock(MakeupOrder o) {
        CosmeticGoods g = goodsMapper.selectById(o.getGoodsId());
        if (g != null) {
            g.setStockQty((g.getStockQty() == null ? 0 : g.getStockQty()) + o.getBuyQty());
            if ("已售罄".equals(g.getStatus()) && g.getStockQty() > 0) {
                g.setStatus("在售");
            }
            goodsMapper.updateById(g);
        }
    }

    private MakeupOrder mustGet(Long id) {
        MakeupOrder o = orderMapper.selectById(id);
        if (o == null) {
            throw new BizException(4000, "订单不存在");
        }
        if (UserContext.isTrialUser() && !o.getUserId().equals(UserContext.userId())) {
            throw new BizException(4003, "无权操作他人订单");
        }
        return o;
    }

    /** 支付超时取消：30 分钟未支付自动取消并回补库存（由定时任务调用） */
    @Transactional
    public int cancelTimeoutOrders() {
        List<MakeupOrder> list = orderMapper.selectList(new LambdaQueryWrapper<MakeupOrder>()
                .eq(MakeupOrder::getStatus, "待支付")
                .lt(MakeupOrder::getCreateTime, LocalDateTime.now().minusMinutes(30)));
        for (MakeupOrder o : list) {
            restoreStock(o);
            o.setStatus("已取消");
            orderMapper.updateById(o);
        }
        return list.size();
    }

    @org.springframework.beans.factory.annotation.Autowired
    private com.grad.beauty.mapper.SysUserMapper userMapper;

    private String userName(Long userId) {
        if (userId == null) {
            return "";
        }
        var u = userMapper.selectById(userId);
        return u == null ? "" : u.getRealName();
    }

    private static long num(Object o, long def) {
        if (o == null || "".equals(o)) {
            return def;
        }
        try {
            return Long.parseLong(String.valueOf(o));
        } catch (NumberFormatException e) {
            return def;
        }
    }

    private static String str(Object o) {
        return o == null ? "" : String.valueOf(o).trim();
    }
}
