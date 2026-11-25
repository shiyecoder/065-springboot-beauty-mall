package com.grad.beauty.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.grad.beauty.common.BizException;
import com.grad.beauty.common.PageResult;
import com.grad.beauty.common.UserContext;
import com.grad.beauty.dto.Reqs;
import com.grad.beauty.entity.ConvertCorrection;
import com.grad.beauty.entity.ConvertRule;
import com.grad.beauty.entity.ConvertSnapshot;
import com.grad.beauty.entity.ConvertTrack;
import com.grad.beauty.entity.CosmeticGoods;
import com.grad.beauty.entity.MakeupOrder;
import com.grad.beauty.entity.SampleApply;
import com.grad.beauty.entity.SampleSku;
import com.grad.beauty.entity.SkinProfile;
import com.grad.beauty.entity.TrialReport;
import com.grad.beauty.mapper.ConvertCorrectionMapper;
import com.grad.beauty.mapper.ConvertRuleMapper;
import com.grad.beauty.mapper.ConvertSnapshotMapper;
import com.grad.beauty.mapper.ConvertTrackMapper;
import com.grad.beauty.mapper.CosmeticGoodsMapper;
import com.grad.beauty.mapper.MakeupOrderMapper;
import com.grad.beauty.mapper.SampleApplyMapper;
import com.grad.beauty.mapper.SampleSkuMapper;
import com.grad.beauty.mapper.SkinProfileMapper;
import com.grad.beauty.mapper.TrialReportMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

/**
 * 创新点：试用转化概率与跟进优先级（需求第 8 节）。
 *
 * 转化概率分 = Σ(单项归一化得分 × 权重) / 100，五项权重合计必须为 100%：
 *   ① 肤质与商品适配度 30%（完全匹配 100 / 部分匹配 60 / 不匹配 0 / 无档案 0）
 *   ② 历史试用领取与报告率 25%（近 180 天报告数 / 申领通过数；首次申领按 60 分）
 *   ③ 试用报告完整度 20%（天数 25 + 两项评分 50 + 字数 15 + 图片 10；未提交 0 分）
 *   ④ 正装详情浏览时长 15%（browse_min × 1.6 + cart_times × 6，上限 100；不足 1 分钟 0 分）
 *   ⑤ 正装价格与客单匹配度 10%（100 - |1 - 客单价/售价| × 80，区间 [0,100]）
 * 概率分 ≥75 高意向、50-74 中意向、<50 低意向。
 *
 * 每次计算都落 convert_snapshot：规则版本、五因素原始值与得分、总分、等级、结论、未满足项，
 * 保证相同输入 + 相同规则版本得到相同结果，且历史计算不受新规则影响。
 */
@Service
@RequiredArgsConstructor
public class ConvertService {

    private final ConvertTrackMapper trackMapper;
    private final ConvertRuleMapper ruleMapper;
    private final ConvertSnapshotMapper snapMapper;
    private final ConvertCorrectionMapper corrMapper;
    private final SampleApplyMapper applyMapper;
    private final SampleSkuMapper skuMapper;
    private final CosmeticGoodsMapper goodsMapper;
    private final SkinProfileMapper profileMapper;
    private final TrialReportMapper reportMapper;
    private final MakeupOrderMapper orderMapper;
    private final TrialService trialService;

    // ==================== 规则配置 ====================

    public ConvertRule currentRule() {
        ConvertRule r = ruleMapper.selectOne(new LambdaQueryWrapper<ConvertRule>()
                .eq(ConvertRule::getStatus, "生效").orderByDesc(ConvertRule::getId).last("limit 1"));
        if (r == null) {
            throw new BizException(5000, "尚未配置生效中的转化规则，请先发布规则");
        }
        return r;
    }

    public List<ConvertRule> ruleList() {
        return ruleMapper.selectList(new LambdaQueryWrapper<ConvertRule>()
                .orderByDesc(ConvertRule::getId));
    }

    /** 保存规则：权重合计必须等于 100%，保存后旧版本转历史，新版本生效 */
    @Transactional
    public ConvertRule saveRule(Reqs.RuleSave req) {
        BigDecimal sum = req.wSkin().add(req.wHistory()).add(req.wReport())
                .add(req.wBrowse()).add(req.wOrder());
        if (sum.compareTo(new BigDecimal("100")) != 0) {
            throw new BizException(4000, "权重合计必须等于 100%，当前为 " + sum.stripTrailingZeros().toPlainString() + "%");
        }
        for (BigDecimal w : List.of(req.wSkin(), req.wHistory(), req.wReport(), req.wBrowse(), req.wOrder())) {
            if (w.compareTo(BigDecimal.ZERO) < 0) {
                throw new BizException(4000, "权重不能为负数");
            }
        }
        BigDecimal high = req.highThreshold() == null ? new BigDecimal("75") : req.highThreshold();
        BigDecimal mid = req.midThreshold() == null ? new BigDecimal("50") : req.midThreshold();
        if (mid.compareTo(high) >= 0) {
            throw new BizException(4000, "中意向阈值必须小于高意向阈值");
        }
        ConvertRule last = ruleMapper.selectOne(new LambdaQueryWrapper<ConvertRule>()
                .orderByDesc(ConvertRule::getId).last("limit 1"));
        int next = 1;
        if (last != null && last.getRuleVersion().startsWith("V")) {
            next = Integer.parseInt(last.getRuleVersion().substring(1)) + 1;
        }
        // 旧生效版本转历史，历史计算不受影响（快照里已存 rule_version）
        ruleMapper.selectList(new LambdaQueryWrapper<ConvertRule>().eq(ConvertRule::getStatus, "生效"))
                .forEach(old -> {
                    old.setStatus("历史");
                    ruleMapper.updateById(old);
                });
        ConvertRule r = new ConvertRule();
        r.setRuleNo("GZ" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyMMdd"))
                + String.format("%04d", ThreadLocalRandom.current().nextInt(1, 9999)));
        r.setRuleName(req.ruleName());
        r.setRuleVersion("V" + next);
        r.setWSkin(req.wSkin());
        r.setWHistory(req.wHistory());
        r.setWReport(req.wReport());
        r.setWBrowse(req.wBrowse());
        r.setWOrder(req.wOrder());
        r.setHighThreshold(high);
        r.setMidThreshold(mid);
        r.setStatus("生效");
        r.setEffectTime(LocalDateTime.now());
        r.setRemark("权重合计 100%");
        r.setCreateBy(UserContext.userId());
        ruleMapper.insert(r);
        trialService.operLog("规则配置", "新增", r.getRuleNo(),
                "发布 " + r.getRuleVersion() + "，权重 "
                        + req.wSkin() + "/" + req.wHistory() + "/" + req.wReport() + "/"
                        + req.wBrowse() + "/" + req.wOrder());
        return r;
    }

    // ==================== 计算 ====================

    /** 计算并落快照，返回完整结果（含五因素明细与未满足项） */
    @Transactional
    public Map<String, Object> compute(Long trackId) {
        ConvertTrack t = trackMapper.selectById(trackId);
        if (t == null) {
            throw new BizException(4000, "转化跟踪记录不存在");
        }
        ConvertRule rule = currentRule();
        SampleApply a = t.getApplyId() == null ? null : applyMapper.selectById(t.getApplyId());
        SampleSku s = a == null ? null : skuMapper.selectById(a.getSampleId());
        CosmeticGoods g = s == null ? null : goodsMapper.selectById(s.getGoodsId());

        // ① 肤质适配度
        SkinProfile p = profileMapper.selectOne(new LambdaQueryWrapper<SkinProfile>()
                .eq(SkinProfile::getUserId, t.getUserId()).eq(SkinProfile::getStatus, 1).last("limit 1"));
        double skinScore;
        String match;
        if (p == null) {
            skinScore = 0;
            match = "无档案";
        } else if (g == null) {
            skinScore = 0;
            match = "不匹配";
        } else {
            List<String> goodsSkins = Arrays.asList(g.getSkinType().split(","));
            if (goodsSkins.contains(p.getSkinType())) {
                skinScore = 100;
                match = "完全匹配";
            } else if (goodsSkins.stream().anyMatch(x -> x.equals("中性") || x.equals(p.getSkinType()))) {
                skinScore = 60;
                match = "部分匹配";
            } else {
                skinScore = 0;
                match = "不匹配";
            }
        }

        // ② 历史领取与报告率（近 180 天）
        List<SampleApply> mine = applyMapper.selectList(new LambdaQueryWrapper<SampleApply>()
                .eq(SampleApply::getUserId, t.getUserId())
                .in(SampleApply::getStatus, List.of(TrialService.ST_SENT,
                        TrialService.ST_TO_REPORT, TrialService.ST_DONE))
                .ge(SampleApply::getCreateTime, LocalDateTime.now().minusDays(180)));
        long reported = 0;
        for (SampleApply x : mine) {
            Long c = reportMapper.selectCount(new LambdaQueryWrapper<TrialReport>()
                    .eq(TrialReport::getApplyId, x.getId())
                    .eq(TrialReport::getStatus, "已通过"));
            if (c != null && c > 0) {
                reported++;
            }
        }
        double histRate;
        double histScore;
        if (mine.isEmpty()) {
            histRate = 60;
            histScore = 60;
        } else {
            histRate = Math.round(reported * 10000.0 / mine.size()) / 100.0;
            histScore = histRate;
        }

        // ③ 报告完整度
        TrialReport rp = a == null ? null : reportMapper.selectOne(new LambdaQueryWrapper<TrialReport>()
                .eq(TrialReport::getApplyId, a.getId()).last("limit 1"));
        double reportScore = 0;
        if (rp != null) {
            double comp = 0;
            comp += rp.getUseDays() != null && rp.getUseDays() >= 7 ? 25 : 15;
            comp += rp.getAbsorbScore() != null && rp.getAbsorbScore() >= 4 ? 25 : 15;
            comp += rp.getMildScore() != null && rp.getMildScore() >= 4 ? 25 : 15;
            comp += rp.getContent() != null && rp.getContent().length() >= 60 ? 15 : 8;
            comp += rp.getImageUrls() != null && !rp.getImageUrls().isBlank() ? 10 : 0;
            reportScore = Math.min(100, comp);
        }

        // ④ 浏览与加购
        int browse = t.getBrowseMin() == null ? 0 : t.getBrowseMin();
        int cart = t.getCartTimes() == null ? 0 : t.getCartTimes();
        double browseScore = browse < 1 ? 0 : Math.min(100, browse * 1.6 + cart * 6);

        // ⑤ 客单匹配度
        List<MakeupOrder> hisOrders = orderMapper.selectList(new LambdaQueryWrapper<MakeupOrder>()
                .eq(MakeupOrder::getUserId, t.getUserId())
                .ne(MakeupOrder::getStatus, "已取消"));
        double avgAmount;
        if (hisOrders.isEmpty()) {
            // 无历史订单：取平台同品类客单价中位数
            List<MakeupOrder> sameType = orderMapper.selectList(new LambdaQueryWrapper<MakeupOrder>()
                    .ne(MakeupOrder::getStatus, "已取消"));
            List<Double> vals = new ArrayList<>();
            for (MakeupOrder o : sameType) {
                CosmeticGoods og = goodsMapper.selectById(o.getGoodsId());
                if (og != null && g != null && og.getGoodsType().equals(g.getGoodsType())) {
                    vals.add(o.getPayAmount().doubleValue());
                }
            }
            vals.sort(Double::compare);
            avgAmount = vals.isEmpty() ? (g == null ? 0 : g.getSalePrice().doubleValue())
                    : vals.get(vals.size() / 2);
        } else {
            avgAmount = hisOrders.stream().mapToDouble(o -> o.getPayAmount().doubleValue()).average().orElse(0);
        }
        double price = g == null || g.getSalePrice().doubleValue() == 0 ? 0 : g.getSalePrice().doubleValue();
        double orderScore = price == 0 ? 60
                : Math.max(0, Math.min(100, 100 - Math.abs(1 - avgAmount / price) * 80));

        double total = (skinScore * rule.getWSkin().doubleValue()
                + histScore * rule.getWHistory().doubleValue()
                + reportScore * rule.getWReport().doubleValue()
                + browseScore * rule.getWBrowse().doubleValue()
                + orderScore * rule.getWOrder().doubleValue()) / 100.0;
        total = Math.round(total * 100) / 100.0;
        String level = total >= rule.getHighThreshold().doubleValue() ? "高意向"
                : (total >= rule.getMidThreshold().doubleValue() ? "中意向" : "低意向");

        List<String> unmet = new ArrayList<>();
        if ("无档案".equals(match)) {
            unmet.add("缺少肤质档案，该项记 0 分，建议先完成自测问卷");
        }
        if (reportScore == 0) {
            unmet.add("试用报告未提交，完整度记 0 分，补齐后预计提升 " + rule.getWReport() + " 分以内");
        }
        if (browseScore < 40) {
            unmet.add("正装详情浏览不足 1 分钟或加购偏少，可推送成分测评内容");
        }
        if (orderScore < 60) {
            unmet.add("历史客单价与本品价格带偏差较大，建议推小规格或组合装");
        }
        String conclusion = switch (level) {
            case "高意向" -> "优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送正装组合券";
            case "中意向" -> "常规培育：3 天内推送使用教程与真实测评，7 天未下单转常规触达";
            default -> "低成本触达：仅保留站内消息，不单独发券，避免营销成本浪费";
        };

        ConvertSnapshot snap = new ConvertSnapshot();
        snap.setSnapNo("KP" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyMMdd"))
                + String.format("%06d", ThreadLocalRandom.current().nextInt(1, 999999)));
        snap.setTrackId(trackId);
        snap.setApplyId(t.getApplyId());
        snap.setUserId(t.getUserId());
        snap.setGoodsId(g == null ? null : g.getId());
        snap.setRuleId(rule.getId());
        snap.setRuleVersion(rule.getRuleVersion());
        snap.setSkinMatch(match);
        snap.setSkinScore(bd(skinScore));
        snap.setHistoryRate(bd(histRate));
        snap.setHistoryScore(bd(histScore));
        snap.setReportComplete(bd(reportScore));
        snap.setReportScore(bd(reportScore));
        snap.setBrowseMin(browse);
        snap.setCartTimes(cart);
        snap.setBrowseScore(bd(browseScore));
        snap.setAvgAmount(BigDecimal.valueOf(avgAmount).setScale(2, RoundingMode.HALF_UP));
        snap.setOrderScore(bd(orderScore));
        snap.setTotalScore(bd(total));
        snap.setConvertLevel(level);
        snap.setConclusion(conclusion);
        snap.setUnmet(unmet.isEmpty() ? null : String.join("；", unmet));
        snap.setCalcTime(LocalDateTime.now());
        snapMapper.insert(snap);

        // 回写跟踪表的分数与等级（客服台按分数排序）
        t.setConvertScore(bd(total));
        t.setConvertLevel(level);
        trackMapper.updateById(t);

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("snapId", snap.getId());
        res.put("snapNo", snap.getSnapNo());
        res.put("trackId", trackId);
        res.put("ruleVersion", rule.getRuleVersion());
        res.put("totalScore", total);
        res.put("level", level);
        res.put("conclusion", conclusion);
        res.put("unmet", unmet);
        res.put("match", match);
        res.put("factors", List.of(
                factor("肤质与商品适配度", rule.getWSkin().doubleValue(), skinScore, skinScore * rule.getWSkin().doubleValue() / 100,
                        "肤质 " + (p == null ? "无档案" : p.getSkinType()) + " / 商品适用 " + (g == null ? "-" : g.getSkinType()) + " → " + match),
                factor("历史领取与报告率", rule.getWHistory().doubleValue(), histScore, histScore * rule.getWHistory().doubleValue() / 100,
                        "近 180 天 " + mine.size() + " 单已发放，报告通过 " + reported + " 份，报告率 " + histRate + "%"),
                factor("试用报告完整度", rule.getWReport().doubleValue(), reportScore, reportScore * rule.getWReport().doubleValue() / 100,
                        rp == null ? "尚未提交报告" : "使用 " + rp.getUseDays() + " 天 / 评分 " + rp.getAbsorbScore() + "·" + rp.getMildScore()
                                + " / 字数 " + (rp.getContent() == null ? 0 : rp.getContent().length())
                                + " / 图片 " + (rp.getImageUrls() == null ? 0 : rp.getImageUrls().split(",").length) + " 张"),
                factor("正装详情浏览时长", rule.getWBrowse().doubleValue(), browseScore, browseScore * rule.getWBrowse().doubleValue() / 100,
                        "浏览 " + browse + " 分钟，加购 " + cart + " 次"),
                factor("正装价格与客单匹配度", rule.getWOrder().doubleValue(), orderScore, orderScore * rule.getWOrder().doubleValue() / 100,
                        "历史客单价 ¥" + String.format("%.2f", avgAmount) + " / 售价 ¥" + String.format("%.2f", price))));
        return res;
    }

    private Map<String, Object> factor(String name, double weight, double score, double weighted, String detail) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("name", name);
        m.put("weight", weight);
        m.put("score", Math.round(score * 100) / 100.0);
        m.put("weighted", Math.round(weighted * 100) / 100.0);
        m.put("detail", detail);
        return m;
    }

    private BigDecimal bd(double v) {
        return BigDecimal.valueOf(v).setScale(2, RoundingMode.HALF_UP);
    }

    /** 人工修正：必须填不少于 5 字原因，原始快照保留不被覆盖 */
    @Transactional
    public void correct(Long trackId, Reqs.Correction req) {
        if (req.reason() == null || req.reason().trim().length() < 5) {
            throw new BizException(4000, "人工修正必须填写不少于 5 字的原因");
        }
        ConvertTrack t = trackMapper.selectById(trackId);
        if (t == null) {
            throw new BizException(4000, "转化跟踪记录不存在");
        }
        ConvertSnapshot snap = snapMapper.selectOne(new LambdaQueryWrapper<ConvertSnapshot>()
                .eq(ConvertSnapshot::getTrackId, trackId)
                .orderByDesc(ConvertSnapshot::getCalcTime).last("limit 1"));
        if (snap == null) {
            throw new BizException(4001, "该记录尚无计算结果，请先执行一次计算");
        }
        ConvertCorrection c = new ConvertCorrection();
        c.setSnapId(snap.getId());
        c.setTrackId(trackId);
        c.setBeforeScore(snap.getTotalScore());
        c.setBeforeLevel(snap.getConvertLevel());
        c.setAfterLevel(req.afterLevel());
        c.setReason(req.reason().trim());
        c.setOperId(UserContext.userId());
        c.setOperName(UserContext.realName());
        c.setOperTime(LocalDateTime.now());
        corrMapper.insert(c);
        // 原始快照只打标记，不改分数
        snap.setCorrectionFlag(1);
        snapMapper.updateById(snap);
        t.setConvertLevel(req.afterLevel());
        trackMapper.updateById(t);
        trialService.operLog("人工修正", "修正", t.getTrackNo(),
                snap.getTotalScore() + " " + snap.getConvertLevel() + " → " + req.afterLevel()
                        + "，原因：" + req.reason().trim());
    }

    // ==================== 查询 ====================

    public PageResult<Map<String, Object>> trackPage(Map<String, Object> q) {
        long page = num(q.get("page"), 1), size = Math.min(num(q.get("size"), 10), 100);
        LambdaQueryWrapper<ConvertTrack> w = new LambdaQueryWrapper<ConvertTrack>()
                .orderByDesc(ConvertTrack::getConvertScore);
        if (!str(q.get("level")).isEmpty()) {
            w.eq(ConvertTrack::getConvertLevel, str(q.get("level")));
        }
        if (!str(q.get("followStatus")).isEmpty()) {
            w.eq(ConvertTrack::getFollowStatus, str(q.get("followStatus")));
        }
        String kw = str(q.get("keyword"));
        if (!kw.isEmpty()) {
            w.like(ConvertTrack::getTrackNo, kw);
        }
        if ("window".equals(str(q.get("window")))) {
            w.ge(ConvertTrack::getAttributionEnd, LocalDate.now());
        } else if ("expired".equals(str(q.get("window")))) {
            w.lt(ConvertTrack::getAttributionEnd, LocalDate.now());
        }
        Page<ConvertTrack> p = trackMapper.selectPage(new Page<>(page, size), w);
        List<Map<String, Object>> rows = p.getRecords().stream().map(this::trackVo)
                .collect(Collectors.toList());
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    public Map<String, Object> trackVo(ConvertTrack t) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", t.getId());
        m.put("trackNo", t.getTrackNo());
        m.put("applyId", t.getApplyId());
        SampleApply a = t.getApplyId() == null ? null : applyMapper.selectById(t.getApplyId());
        if (a != null) {
            m.put("applyNo", a.getApplyNo());
            SampleSku s = skuMapper.selectById(a.getSampleId());
            CosmeticGoods g = s == null ? null : goodsMapper.selectById(s.getGoodsId());
            m.put("goodsName", g == null ? "" : g.getGoodsName());
            m.put("goodsCover", g == null ? null : g.getCoverImage());
            m.put("goodsId", g == null ? null : g.getId());
            m.put("sendTime", a.getSendTime());
        }
        m.put("userId", t.getUserId());
        m.put("userName", userName(t.getUserId()));
        m.put("browseMin", t.getBrowseMin());
        m.put("cartTimes", t.getCartTimes());
        m.put("convertScore", t.getConvertScore());
        m.put("convertLevel", t.getConvertLevel());
        m.put("orderId", t.getOrderId());
        m.put("attributionEnd", t.getAttributionEnd());
        m.put("inWindow", t.getAttributionEnd() != null && !t.getAttributionEnd().isBefore(LocalDate.now()));
        m.put("followStatus", t.getFollowStatus());
        m.put("createTime", t.getCreateTime());
        return m;
    }

    /** 最新一次计算快照，用于结果解释页 */
    public Map<String, Object> latestSnapshot(Long trackId) {
        ConvertSnapshot s = snapMapper.selectOne(new LambdaQueryWrapper<ConvertSnapshot>()
                .eq(ConvertSnapshot::getTrackId, trackId)
                .orderByDesc(ConvertSnapshot::getCalcTime).last("limit 1"));
        if (s == null) {
            return compute(trackId);
        }
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("snapId", s.getId());
        m.put("snapNo", s.getSnapNo());
        m.put("ruleVersion", s.getRuleVersion());
        m.put("totalScore", s.getTotalScore());
        m.put("level", s.getConvertLevel());
        m.put("conclusion", s.getConclusion());
        m.put("unmet", s.getUnmet() == null ? List.of() : Arrays.asList(s.getUnmet().split("；")));
        m.put("match", s.getSkinMatch());
        m.put("correctionFlag", s.getCorrectionFlag());
        m.put("calcTime", s.getCalcTime());
        m.put("input", Map.of("skinMatch", s.getSkinMatch(), "historyRate", s.getHistoryRate(),
                "reportComplete", s.getReportComplete(), "browseMin", s.getBrowseMin(),
                "cartTimes", s.getCartTimes(), "avgAmount", s.getAvgAmount()));
        m.put("factors", List.of(
                factor("肤质与商品适配度", 30, s.getSkinScore().doubleValue(), s.getSkinScore().doubleValue() * 0.3, s.getSkinMatch()),
                factor("历史领取与报告率", 25, s.getHistoryScore().doubleValue(), s.getHistoryScore().doubleValue() * 0.25,
                        "报告率 " + s.getHistoryRate() + "%"),
                factor("试用报告完整度", 20, s.getReportScore().doubleValue(), s.getReportScore().doubleValue() * 0.2,
                        "报告完整度 " + s.getReportComplete()),
                factor("正装详情浏览时长", 15, s.getBrowseScore().doubleValue(), s.getBrowseScore().doubleValue() * 0.15,
                        s.getBrowseMin() + " 分钟 / " + s.getCartTimes() + " 次加购"),
                factor("正装价格与客单匹配度", 10, s.getOrderScore().doubleValue(), s.getOrderScore().doubleValue() * 0.1,
                        "客单价 ¥" + s.getAvgAmount())));
        List<ConvertCorrection> cs = corrMapper.selectList(new LambdaQueryWrapper<ConvertCorrection>()
                .eq(ConvertCorrection::getTrackId, trackId).orderByDesc(ConvertCorrection::getOperTime));
        m.put("corrections", cs);
        return m;
    }

    /** 跟进登记；关联订单后归因 */
    @Transactional
    public void follow(Long trackId, Reqs.Follow req) {
        ConvertTrack t = trackMapper.selectById(trackId);
        if (t == null) {
            throw new BizException(4000, "转化跟踪记录不存在");
        }
        List<String> allowed = List.of("未跟进", "已触达", "已下单", "已放弃");
        if (!allowed.contains(req.followStatus())) {
            throw new BizException(4000, "跟进状态不合法");
        }
        t.setFollowStatus(req.followStatus());
        if (req.orderNo() != null && !req.orderNo().isBlank()) {
            MakeupOrder o = orderMapper.selectOne(new LambdaQueryWrapper<MakeupOrder>()
                    .eq(MakeupOrder::getOrderNo, req.orderNo().trim()).last("limit 1"));
            if (o == null) {
                throw new BizException(4000, "订单号不存在：" + req.orderNo());
            }
            t.setOrderId(o.getId());
        }
        trackMapper.updateById(t);
        trialService.operLog("用户跟进", "登记", t.getTrackNo(),
                "跟进结果：" + req.followStatus() + (req.remark() == null ? "" : "，" + req.remark()));
    }

    /** 转化看板：三档人数 + 漏斗 + 分布 */
    public Map<String, Object> board() {
        List<ConvertTrack> all = trackMapper.selectList(new LambdaQueryWrapper<>());
        long high = all.stream().filter(t -> "高意向".equals(t.getConvertLevel())).count();
        long mid = all.stream().filter(t -> "中意向".equals(t.getConvertLevel())).count();
        long low = all.stream().filter(t -> "低意向".equals(t.getConvertLevel())).count();
        long pending = all.stream().filter(t -> "待评估".equals(t.getConvertLevel())).count();
        long ordered = all.stream().filter(t -> t.getOrderId() != null).count();

        Map<String, Object> m = new LinkedHashMap<>();
        m.put("high", high);
        m.put("mid", mid);
        m.put("low", low);
        m.put("pending", pending);
        m.put("total", all.size());
        m.put("ordered", ordered);
        m.put("highToTouch", all.stream().filter(t -> "高意向".equals(t.getConvertLevel())
                && "未跟进".equals(t.getFollowStatus())).count());
        List<Map<String, Object>> dist = new ArrayList<>();
        int[] buckets = {0, 0, 0, 0, 0};
        for (ConvertTrack t : all) {
            double s = t.getConvertScore() == null ? 0 : t.getConvertScore().doubleValue();
            if (s < 25) {
                buckets[0]++;
            } else if (s < 50) {
                buckets[1]++;
            } else if (s < 75) {
                buckets[2]++;
            } else if (s < 90) {
                buckets[3]++;
            } else {
                buckets[4]++;
            }
        }
        String[] labels = {"0-24", "25-49", "50-74", "75-89", "90-100"};
        for (int i = 0; i < 5; i++) {
            dist.add(Map.of("label", labels[i], "value", buckets[i]));
        }
        m.put("dist", dist);
        // 漏斗：已发放 → 浏览 → 加购 → 下单 → 支付
        long sent = all.size();
        long viewed = all.stream().filter(t -> t.getBrowseMin() != null && t.getBrowseMin() >= 1).count();
        long carted = all.stream().filter(t -> t.getCartTimes() != null && t.getCartTimes() >= 1).count();
        m.put("funnel", List.of(
                Map.of("label", "已发放", "value", sent),
                Map.of("label", "浏览正装", "value", viewed),
                Map.of("label", "加入购物车", "value", carted),
                Map.of("label", "下单", "value", ordered),
                Map.of("label", "支付完成", "value", all.stream().filter(t -> t.getOrderId() != null).count())));
        // 规则运行情况
        ConvertRule rule = currentRule();
        m.put("ruleVersion", rule.getRuleVersion());
        m.put("ruleEffectTime", rule.getEffectTime());
        long corrected = snapMapper.selectCount(new LambdaQueryWrapper<ConvertSnapshot>()
                .eq(ConvertSnapshot::getCorrectionFlag, 1));
        long totalSnap = snapMapper.selectCount(new LambdaQueryWrapper<>());
        m.put("correctionRate", totalSnap == 0 ? 0 : Math.round(corrected * 1000.0 / totalSnap) / 10.0);
        m.put("adoptRate", sent == 0 ? 0 : Math.round(ordered * 1000.0 / sent) / 10.0);
        return m;
    }

    private String userName(Long userId) {
        if (userId == null) {
            return "";
        }
        return userMapper == null ? "" : nameOf(userId);
    }

    @org.springframework.beans.factory.annotation.Autowired
    private com.grad.beauty.mapper.SysUserMapper userMapper;

    private String nameOf(Long userId) {
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
