package com.grad.beauty.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.grad.beauty.entity.ConvertTrack;
import com.grad.beauty.entity.CosmeticGoods;
import com.grad.beauty.entity.MakeupOrder;
import com.grad.beauty.entity.SampleApply;
import com.grad.beauty.entity.SampleSku;
import com.grad.beauty.entity.SkinProfile;
import com.grad.beauty.entity.TrialReport;
import com.grad.beauty.mapper.ConvertTrackMapper;
import com.grad.beauty.mapper.CosmeticGoodsMapper;
import com.grad.beauty.mapper.MakeupOrderMapper;
import com.grad.beauty.mapper.SampleApplyMapper;
import com.grad.beauty.mapper.SampleSkuMapper;
import com.grad.beauty.mapper.SkinProfileMapper;
import com.grad.beauty.mapper.TrialReportMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/**
 * 数据看板与试用效果报表（需求第 9、5.7 节）。
 * 8 个核心指标 + 6 张图表，全部由明细聚合，保证统计总数与明细一致。
 */
@Service
@RequiredArgsConstructor
public class DashboardService {

    private final SampleApplyMapper applyMapper;
    private final SampleSkuMapper skuMapper;
    private final TrialReportMapper reportMapper;
    private final MakeupOrderMapper orderMapper;
    private final ConvertTrackMapper trackMapper;
    private final CosmeticGoodsMapper goodsMapper;
    private final SkinProfileMapper profileMapper;

    public Map<String, Object> overview() {
        List<SampleApply> all = applyMapper.selectList(new LambdaQueryWrapper<>());
        List<TrialReport> reports = reportMapper.selectList(new LambdaQueryWrapper<>());
        List<SampleApply> sent = all.stream()
                .filter(a -> !"待审核".equals(a.getStatus()) && !"已驳回".equals(a.getStatus())
                        && !"待发放".equals(a.getStatus())).toList();
        List<SampleApply> done = all.stream().filter(a -> "已完成".equals(a.getStatus())).toList();

        long todayApply = all.stream().filter(a -> a.getCreateTime() != null
                && a.getCreateTime().toLocalDate().equals(LocalDate.now())).count();
        long pending = all.stream().filter(a -> "待审核".equals(a.getStatus())).count();
        long remain = skuMapper.selectList(new LambdaQueryWrapper<SampleSku>()
                        .ne(SampleSku::getStatus, "已下架")).stream()
                .mapToLong(s -> s.getRemainQty() == null ? 0 : s.getRemainQty()).sum();
        long passedReports = reports.stream().filter(r -> "已通过".equals(r.getStatus())).count();
        double submitRate = sent.isEmpty() ? 0 : Math.round(reports.size() * 1000.0 / sent.size()) / 10.0;
        double avgScore = reports.isEmpty() ? 0 : Math.round(reports.stream()
                .mapToDouble(r -> ((r.getAbsorbScore() == null ? 0 : r.getAbsorbScore())
                        + (r.getMildScore() == null ? 0 : r.getMildScore())) / 2.0)
                .average().orElse(0) * 100) / 100.0;
        double convRate = done.isEmpty() ? 0 : Math.round(orderMapper.selectList(
                new LambdaQueryWrapper<MakeupOrder>().isNotNull(MakeupOrder::getSourceApplyId))
                .stream().filter(o -> !"已退款".equals(o.getStatus())).count() * 1000.0 / done.size()) / 10.0;
        long highTodo = trackMapper.selectList(new LambdaQueryWrapper<ConvertTrack>()
                        .eq(ConvertTrack::getConvertLevel, "高意向")
                        .eq(ConvertTrack::getFollowStatus, "未跟进")).size();
        BigDecimal cost = skuMapper.selectList(new LambdaQueryWrapper<>()).stream()
                .map(s -> s.getCostPrice() == null ? BigDecimal.ZERO
                        : s.getCostPrice().multiply(BigDecimal.valueOf(s.getSentQty() == null ? 0 : s.getSentQty())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Map<String, Object> kpi = new LinkedHashMap<>();
        kpi.put("todayApply", todayApply);
        kpi.put("pendingApply", pending);
        kpi.put("remainQty", remain);
        kpi.put("reportRate", submitRate);
        kpi.put("avgScore", avgScore);
        kpi.put("convertRate", convRate);
        kpi.put("highIntentTodo", highTodo);
        kpi.put("sampleCost", cost);
        kpi.put("passedReports", passedReports);

        // 近 30 天申领量与转化量
        TreeMap<String, long[]> trend = new TreeMap<>();
        for (int i = 29; i >= 0; i--) {
            trend.put(LocalDate.now().minusDays(i).format(DateTimeFormatter.ofPattern("MM-dd")), new long[]{0, 0});
        }
        for (SampleApply a : all) {
            String k = a.getCreateTime() == null ? null
                    : a.getCreateTime().toLocalDate().format(DateTimeFormatter.ofPattern("MM-dd"));
            if (k != null && trend.containsKey(k)) {
                trend.get(k)[0]++;
            }
        }
        for (MakeupOrder o : orderMapper.selectList(new LambdaQueryWrapper<MakeupOrder>()
                .isNotNull(MakeupOrder::getSourceApplyId))) {
            String k = o.getCreateTime() == null ? null
                    : o.getCreateTime().toLocalDate().format(DateTimeFormatter.ofPattern("MM-dd"));
            if (k != null && trend.containsKey(k)) {
                trend.get(k)[1]++;
            }
        }
        List<String> cats = new ArrayList<>();
        List<Long> applySeries = new ArrayList<>();
        List<Long> convSeries = new ArrayList<>();
        trend.forEach((k, v) -> {
            cats.add(k);
            applySeries.add(v[0]);
            convSeries.add(v[1]);
        });

        // 各品类转化率
        Map<String, long[]> byType = new LinkedHashMap<>();
        for (SampleApply a : done) {
            SampleSku s = skuMapper.selectById(a.getSampleId());
            CosmeticGoods g = s == null ? null : goodsMapper.selectById(s.getGoodsId());
            if (g != null) {
                byType.computeIfAbsent(g.getGoodsType(), k -> new long[]{0, 0})[0]++;
            }
        }
        for (MakeupOrder o : orderMapper.selectList(new LambdaQueryWrapper<MakeupOrder>()
                .isNotNull(MakeupOrder::getSourceApplyId))) {
            CosmeticGoods g = goodsMapper.selectById(o.getGoodsId());
            if (g != null && byType.containsKey(g.getGoodsType())) {
                byType.get(g.getGoodsType())[1]++;
            }
        }
        List<Map<String, Object>> typeConv = new ArrayList<>();
        byType.forEach((k, v) -> typeConv.add(Map.of("label", k, "value",
                v[0] == 0 ? 0 : Math.round(v[1] * 1000.0 / v[0]) / 10.0)));

        // 肤质分布
        Map<String, Long> skinMap = new LinkedHashMap<>();
        for (SkinProfile p : profileMapper.selectList(new LambdaQueryWrapper<SkinProfile>()
                .eq(SkinProfile::getStatus, 1))) {
            skinMap.merge(p.getSkinType(), 1L, Long::sum);
        }
        List<Map<String, Object>> skinDist = new ArrayList<>();
        skinMap.forEach((k, v) -> skinDist.add(Map.of("label", k, "value", v)));

        // 报告评分分布
        int[] scoreBucket = new int[5];
        for (TrialReport r : reports) {
            int avg = Math.round(((r.getAbsorbScore() == null ? 0 : r.getAbsorbScore())
                    + (r.getMildScore() == null ? 0 : r.getMildScore())) / 2.0f);
            scoreBucket[Math.max(0, Math.min(4, avg - 1))]++;
        }
        List<Map<String, Object>> scoreDist = new ArrayList<>();
        for (int i = 0; i < 5; i++) {
            scoreDist.add(Map.of("label", (i + 1) + "星", "value", scoreBucket[i]));
        }

        // 漏斗
        long applied = all.size();
        long approved = all.stream().filter(a -> !"待审核".equals(a.getStatus())
                && !"已驳回".equals(a.getStatus())).count();
        long sentCount = sent.size();
        long reported = reports.size();
        long ordered = orderMapper.selectList(new LambdaQueryWrapper<MakeupOrder>()
                .isNotNull(MakeupOrder::getSourceApplyId)).stream()
                .filter(o -> !"已退款".equals(o.getStatus())).count();
        List<Map<String, Object>> funnel = List.of(
                Map.of("label", "申领", "value", applied),
                Map.of("label", "审核通过", "value", approved),
                Map.of("label", "已发放", "value", sentCount),
                Map.of("label", "报告提交", "value", reported),
                Map.of("label", "下单正装", "value", ordered));

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("kpi", kpi);
        data.put("trend", Map.of("cats", cats, "apply", applySeries, "convert", convSeries));
        data.put("typeConvert", typeConv);
        data.put("skinDist", skinDist);
        data.put("scoreDist", scoreDist);
        data.put("funnel", funnel);
        return data;
    }

    /** 试用效果报表：按商品分组，口径为报告审核通过时间归属自然日 */
    public List<Map<String, Object>> report() {
        List<CosmeticGoods> goods = goodsMapper.selectList(new LambdaQueryWrapper<CosmeticGoods>()
                .orderByDesc(CosmeticGoods::getId));
        List<Map<String, Object>> out = new ArrayList<>();
        for (CosmeticGoods g : goods) {
            List<SampleSku> skus = skuMapper.selectList(new LambdaQueryWrapper<SampleSku>()
                    .eq(SampleSku::getGoodsId, g.getId()));
            if (skus.isEmpty()) {
                continue;
            }
            List<Long> skuIds = skus.stream().map(SampleSku::getId).toList();
            List<SampleApply> applies = applyMapper.selectList(new LambdaQueryWrapper<SampleApply>()
                    .in(SampleApply::getSampleId, skuIds));
            if (applies.isEmpty()) {
                continue;
            }
            long approved = applies.stream().filter(a -> !"待审核".equals(a.getStatus())
                    && !"已驳回".equals(a.getStatus())).count();
            List<SampleApply> sentList = applies.stream()
                    .filter(a -> !"待审核".equals(a.getStatus()) && !"已驳回".equals(a.getStatus())
                            && !"待发放".equals(a.getStatus())).toList();
            List<Long> applyIds = sentList.stream().map(SampleApply::getId).toList();
            List<TrialReport> reps = applyIds.isEmpty() ? List.of()
                    : reportMapper.selectList(new LambdaQueryWrapper<TrialReport>()
                    .in(TrialReport::getApplyId, applyIds));
            long passed = reps.stream().filter(r -> "已通过".equals(r.getStatus())).count();
            List<MakeupOrder> orders = orderMapper.selectList(new LambdaQueryWrapper<MakeupOrder>()
                    .eq(MakeupOrder::getGoodsId, g.getId())
                    .isNotNull(MakeupOrder::getSourceApplyId)
                    .ne(MakeupOrder::getStatus, "已退款"));
            BigDecimal sales = orders.stream().map(MakeupOrder::getPayAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            BigDecimal cost = BigDecimal.ZERO;
            int sentQty = 0;
            for (SampleSku s : skus) {
                int q = s.getSentQty() == null ? 0 : s.getSentQty();
                sentQty += q;
                if (s.getCostPrice() != null) {
                    cost = cost.add(s.getCostPrice().multiply(BigDecimal.valueOf(q)));
                }
            }
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("goodsId", g.getId());
            m.put("goodsName", g.getGoodsName());
            m.put("goodsType", g.getGoodsType());
            m.put("skuCount", skus.size());
            m.put("applyCount", applies.size());
            m.put("approveRate", applies.isEmpty() ? 0
                    : Math.round(approved * 1000.0 / applies.size()) / 10.0);
            m.put("sentCount", sentList.size());
            m.put("reportCount", reps.size());
            m.put("reportRate", sentList.isEmpty() ? 0
                    : Math.round(reps.size() * 1000.0 / sentList.size()) / 10.0);
            m.put("avgScore", reps.isEmpty() ? 0 : Math.round(reps.stream()
                    .mapToDouble(r -> ((r.getAbsorbScore() == null ? 0 : r.getAbsorbScore())
                            + (r.getMildScore() == null ? 0 : r.getMildScore())) / 2.0)
                    .average().orElse(0) * 100) / 100.0);
            m.put("passedCount", passed);
            m.put("convertRate", sentList.isEmpty() ? 0
                    : Math.round(orders.size() * 1000.0 / sentList.size()) / 10.0);
            m.put("cost", cost);
            m.put("sales", sales);
            m.put("roi", cost.compareTo(BigDecimal.ZERO) == 0 ? 0
                    : sales.divide(cost, 2, java.math.RoundingMode.HALF_UP));
            m.put("sentQty", sentQty);
            out.add(m);
        }
        return out;
    }
}
