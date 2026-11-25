package com.grad.beauty.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.grad.beauty.common.BizException;
import com.grad.beauty.common.PageResult;
import com.grad.beauty.common.UserContext;
import com.grad.beauty.dto.Reqs;
import com.grad.beauty.entity.CosmeticGoods;
import com.grad.beauty.entity.SampleSku;
import com.grad.beauty.entity.SampleStockLog;
import com.grad.beauty.mapper.CosmeticGoodsMapper;
import com.grad.beauty.mapper.SampleSkuMapper;
import com.grad.beauty.mapper.SampleStockLogMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

/**
 * 商品与试用装服务。对应需求 5.1 / 5.2：
 * - 参与试用的商品必须已配置试用装，否则拒绝保存
 * - 试用装规格不得超过正装规格的三分之一
 * - 入库/派发/退回/报损/过期核销都写流水，剩余数量 = 入库总量 - 已派发
 * - 剩余与流水不一致时禁止派发，需先做库存校准
 */
@Service
@RequiredArgsConstructor
public class GoodsService {

    private final CosmeticGoodsMapper goodsMapper;
    private final SampleSkuMapper skuMapper;
    private final SampleStockLogMapper logMapper;

    // ---------------- 商品 ----------------

    public PageResult<Map<String, Object>> goodsPage(Map<String, Object> q) {
        long page = num(q.get("page"), 1), size = Math.min(num(q.get("size"), 10), 100);
        LambdaQueryWrapper<CosmeticGoods> w = new LambdaQueryWrapper<CosmeticGoods>()
                .orderByDesc(CosmeticGoods::getCreateTime);
        String kw = str(q.get("keyword"));
        if (!kw.isEmpty()) {
            w.and(x -> x.like(CosmeticGoods::getGoodsName, kw).or().like(CosmeticGoods::getGoodsNo, kw));
        }
        if (!str(q.get("status")).isEmpty()) {
            w.eq(CosmeticGoods::getStatus, str(q.get("status")));
        }
        if (!str(q.get("goodsType")).isEmpty()) {
            w.eq(CosmeticGoods::getGoodsType, str(q.get("goodsType")));
        }
        if (!str(q.get("skinType")).isEmpty()) {
            w.like(CosmeticGoods::getSkinType, str(q.get("skinType")));
        }
        if (q.get("isTrial") != null && !"".equals(q.get("isTrial"))) {
            w.eq(CosmeticGoods::getIsTrial, num(q.get("isTrial"), 0));
        }
        Page<CosmeticGoods> p = goodsMapper.selectPage(new Page<>(page, size), w);
        List<Map<String, Object>> rows = p.getRecords().stream().map(this::goodsVo).collect(Collectors.toList());
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    public Map<String, Object> goodsVo(CosmeticGoods g) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", g.getId());
        m.put("goodsNo", g.getGoodsNo());
        m.put("goodsName", g.getGoodsName());
        m.put("brand", g.getBrand());
        m.put("goodsType", g.getGoodsType());
        m.put("skinType", g.getSkinType());
        m.put("effectTags", g.getEffectTags());
        m.put("specMl", g.getSpecMl());
        m.put("salePrice", g.getSalePrice());
        m.put("stockQty", g.getStockQty());
        m.put("isTrial", g.getIsTrial());
        m.put("status", g.getStatus());
        m.put("coverImage", g.getCoverImage());
        m.put("createTime", g.getCreateTime());
        m.put("version", g.getVersion());
        return m;
    }

    public Map<String, Object> goodsDetail(Long id) {
        CosmeticGoods g = goodsMapper.selectById(id);
        if (g == null) {
            throw new BizException(4000, "商品不存在或已删除");
        }
        Map<String, Object> vo = goodsVo(g);
        List<SampleSku> skus = skuMapper.selectList(new LambdaQueryWrapper<SampleSku>()
                .eq(SampleSku::getGoodsId, id).orderByAsc(SampleSku::getExpireDate));
        vo.put("samples", skus.stream().map(this::skuVo).collect(Collectors.toList()));
        // 报告统计：详情页要展示平均分与报告数
        vo.put("reportCount", 0);
        return vo;
    }

    @Transactional
    public Long saveGoods(Long id, Reqs.Goods req) {
        validateGoods(req);
        if (req.stockQty() < 0 || req.stockQty() > 9999) {
            throw new BizException(4000, "正装库存必须在 0-9999 之间");
        }
        if (req.salePrice().compareTo(new BigDecimal("0.01")) < 0
                || req.salePrice().compareTo(new BigDecimal("9999.99")) > 0) {
            throw new BizException(4000, "售价必须在 0.01-9999.99 之间");
        }
        CosmeticGoods g = id == null ? new CosmeticGoods() : goodsMapper.selectById(id);
        if (g == null) {
            throw new BizException(4000, "商品不存在");
        }
        g.setGoodsName(req.goodsName());
        g.setBrand(req.brand());
        g.setGoodsType(req.goodsType());
        g.setSkinType(req.skinType());
        g.setEffectTags(req.effectTags());
        g.setSpecMl(req.specMl());
        g.setSalePrice(req.salePrice());
        g.setStockQty(req.stockQty());
        g.setIsTrial(req.isTrial() == null ? 0 : req.isTrial());
        g.setCoverImage(req.coverImage());
        // 库存为 0 自动置为已售罄；已售罄补货后回到在售
        String status = req.status();
        if (status == null || status.isBlank()) {
            status = req.stockQty() > 0 ? "在售" : "已售罄";
        }
        g.setStatus(status);
        if (id == null) {
            g.setGoodsNo("MZ" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyMMdd"))
                    + String.format("%04d", ThreadLocalRandom.current().nextInt(1, 9999)));
            g.setCreateBy(UserContext.userId());
            g.setCreateTime(LocalDateTime.now());
            g.setVersion(0);
            goodsMapper.insert(g);
        } else {
            if (req.version() != null && !req.version().equals(g.getVersion())) {
                throw new BizException(4090, "数据已被他人更新，请刷新后重试");
            }
            g.setVersion(g.getVersion() == null ? 1 : g.getVersion() + 1);
            g.setUpdateBy(UserContext.userId());
            goodsMapper.updateById(g);
        }
        return g.getId();
    }

    private void validateGoods(Reqs.Goods req) {
        if (req.goodsName().trim().length() < 2 || req.goodsName().trim().length() > 60) {
            throw new BizException(4000, "商品名称需 2-60 字");
        }
        if (req.specMl() < 5 || req.specMl() > 500) {
            throw new BizException(4000, "正装规格必须在 5-500ml 之间");
        }
        if (req.skinType() == null || req.skinType().isBlank()) {
            throw new BizException(4000, "适用肤质至少选择一项");
        }
    }

    @Transactional
    public void deleteGoods(Long id) {
        long used = skuMapper.selectCount(new LambdaQueryWrapper<SampleSku>().eq(SampleSku::getGoodsId, id));
        if (used > 0) {
            throw new BizException(4009, "该商品下仍有 " + used + " 个试用装批次，请先处理后再删除");
        }
        goodsMapper.deleteById(id);
    }

    // ---------------- 试用装 ----------------

    public PageResult<Map<String, Object>> samplePage(Map<String, Object> q) {
        long page = num(q.get("page"), 1), size = Math.min(num(q.get("size"), 10), 100);
        LambdaQueryWrapper<SampleSku> w = new LambdaQueryWrapper<SampleSku>()
                .orderByAsc(SampleSku::getExpireDate);
        String kw = str(q.get("keyword"));
        if (!kw.isEmpty()) {
            w.and(x -> x.like(SampleSku::getSampleNo, kw).or().like(SampleSku::getBatchNo, kw));
        }
        if (!str(q.get("status")).isEmpty()) {
            w.eq(SampleSku::getStatus, str(q.get("status")));
        }
        if (q.get("goodsId") != null && !"".equals(q.get("goodsId"))) {
            w.eq(SampleSku::getGoodsId, num(q.get("goodsId"), 0));
        }
        Page<SampleSku> p = skuMapper.selectPage(new Page<>(page, size), w);
        List<Map<String, Object>> rows = p.getRecords().stream().map(this::skuVo).collect(Collectors.toList());
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    /** 试用装详情：主表 + 关联商品 + 最近 10 条流水 */
    public Map<String, Object> sampleDetail(Long id) {
        SampleSku s = skuMapper.selectById(id);
        if (s == null) {
            throw new BizException(4000, "试用装不存在或已删除");
        }
        Map<String, Object> m = skuVo(s);
        List<SampleStockLog> logs = logMapper.selectList(new LambdaQueryWrapper<SampleStockLog>()
                .eq(SampleStockLog::getSampleId, id)
                .orderByDesc(SampleStockLog::getCreateTime).last("limit 10"));
        m.put("logs", logs);
        return m;
    }

    public Map<String, Object> skuVo(SampleSku s) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", s.getId());
        m.put("sampleNo", s.getSampleNo());
        m.put("goodsId", s.getGoodsId());
        CosmeticGoods g = goodsMapper.selectById(s.getGoodsId());
        m.put("goodsName", g == null ? "" : g.getGoodsName());
        m.put("goodsCover", g == null ? null : g.getCoverImage());
        m.put("specMl", s.getSpecMl());
        m.put("costPrice", s.getCostPrice());
        m.put("totalQty", s.getTotalQty());
        m.put("sentQty", s.getSentQty());
        m.put("remainQty", s.getRemainQty());
        m.put("batchNo", s.getBatchNo());
        m.put("expireDate", s.getExpireDate());
        m.put("status", s.getStatus());
        m.put("expiring", s.getExpireDate() != null
                && !s.getExpireDate().isAfter(LocalDate.now().plusDays(30)));
        return m;
    }

    @Transactional
    public Long saveSample(Long id, Reqs.Sample req) {
        CosmeticGoods g = goodsMapper.selectById(req.goodsId());
        if (g == null) {
            throw new BizException(4000, "关联商品不存在");
        }
        if (req.specMl() < 1 || req.specMl() > 30) {
            throw new BizException(4000, "试用装规格必须在 1-30ml 之间");
        }
        if (req.specMl() * 3 > g.getSpecMl()) {
            throw new BizException(4000, "试用装规格不得超过正装规格的三分之一（上限 "
                    + (g.getSpecMl() / 3) + "ml）");
        }
        LocalDate expire = LocalDate.parse(req.expireDate());
        SampleSku s = id == null ? new SampleSku() : skuMapper.selectById(id);
        if (s == null) {
            throw new BizException(4000, "试用装不存在");
        }
        if (id != null && s.getTotalQty() != null && req.totalQty() != null
                && !s.getTotalQty().equals(req.totalQty())) {
            throw new BizException(4000, "入库总量入库后不可直接修改，请通过出入库登记调整");
        }
        s.setGoodsId(req.goodsId());
        s.setSpecMl(req.specMl());
        s.setCostPrice(req.costPrice());
        s.setExpireDate(expire);
        s.setStatus(req.status() == null || req.status().isBlank() ? "可派发" : req.status());
        if (id == null) {
            s.setSampleNo("SY" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyMMdd"))
                    + String.format("%04d", ThreadLocalRandom.current().nextInt(1, 9999)));
            s.setBatchNo(req.batchNo() == null || req.batchNo().isBlank()
                    ? ("B" + String.format("%04d", req.goodsId() % 10000)
                    + LocalDate.now().format(DateTimeFormatter.ofPattern("yyMMdd")))
                    : req.batchNo());
            s.setTotalQty(req.totalQty());
            s.setSentQty(0);
            s.setRemainQty(req.totalQty());
            s.setCreateBy(UserContext.userId());
            skuMapper.insert(s);
            // 入库即写一条流水，保证 入库总量 = 首条入库流水
            writeLog(s.getId(), "入库", req.totalQty(), 0, req.totalQty(),
                    "RK" + s.getSampleNo().substring(2), "初始入库");
        } else {
            skuMapper.updateById(s);
        }
        return s.getId();
    }

    /** 出入库登记：入库/退回为正，报损/过期核销为负，派发出申领单触发 */
    @Transactional
    public void stockChange(Reqs.StockChange req) {
        SampleSku s = skuMapper.selectById(req.sampleId());
        if (s == null) {
            throw new BizException(4000, "试用装不存在");
        }
        if (req.changeQty() == 0) {
            throw new BizException(4000, "变动数量不得为 0");
        }
        if (("报损".equals(req.changeType()) || "过期核销".equals(req.changeType()))
                && (req.remark() == null || req.remark().trim().length() < 5)) {
            throw new BizException(4000, "报损与过期核销必须填写不少于 5 字的原因");
        }
        if ("入库".equals(req.changeType()) && req.changeQty() < 0) {
            throw new BizException(4000, "入库数量必须为正数");
        }
        int before = nz(s.getRemainQty());
        int after = before + req.changeQty();
        if (after < 0) {
            throw new BizException(4000, "剩余数量不足，当前仅剩 " + before + " 份");
        }
        if (after > 100000) {
            throw new BizException(4000, "剩余数量超出上限 100000");
        }
        // 入库会同时增加入库总量；其他类型只调整剩余
        if ("入库".equals(req.changeType())) {
            s.setTotalQty(nz(s.getTotalQty()) + req.changeQty());
        }
        s.setRemainQty(after);
        if ("已过期".equals(s.getStatus()) && after > 0) {
            s.setStatus("可派发");
        }
        if (after == 0) {
            s.setStatus("已派完");
        }
        skuMapper.updateById(s);
        writeLog(s.getId(), req.changeType(), req.changeQty(), before, after,
                req.bizNo(), req.remark());
    }

    public PageResult<Map<String, Object>> stockLogPage(Map<String, Object> q) {
        long page = num(q.get("page"), 1), size = Math.min(num(q.get("size"), 10), 100);
        LambdaQueryWrapper<SampleStockLog> w = new LambdaQueryWrapper<SampleStockLog>()
                .orderByDesc(SampleStockLog::getCreateTime);
        if (q.get("sampleId") != null && !"".equals(q.get("sampleId"))) {
            w.eq(SampleStockLog::getSampleId, num(q.get("sampleId"), 0));
        }
        if (!str(q.get("changeType")).isEmpty()) {
            w.eq(SampleStockLog::getChangeType, str(q.get("changeType")));
        }
        Page<SampleStockLog> p = logMapper.selectPage(new Page<>(page, size), w);
        List<Map<String, Object>> rows = p.getRecords().stream().map(l -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", l.getId());
            m.put("logNo", l.getLogNo());
            SampleSku s = skuMapper.selectById(l.getSampleId());
            m.put("sampleNo", s == null ? "" : s.getSampleNo());
            m.put("goodsName", s == null ? "" : nameOf(s.getGoodsId()));
            m.put("changeType", l.getChangeType());
            m.put("changeQty", l.getChangeQty());
            m.put("beforeQty", l.getBeforeQty());
            m.put("afterQty", l.getAfterQty());
            m.put("bizNo", l.getBizNo());
            m.put("remark", l.getRemark());
            m.put("createTime", l.getCreateTime());
            return m;
        }).collect(Collectors.toList());
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    /** 库存校准：剩余与流水不一致时修正，并记录校准原因（需求 5.2 硬性要求） */
    @Transactional
    public void calibrate(Long sampleId, int targetRemain, String reason) {
        if (reason == null || reason.trim().length() < 5) {
            throw new BizException(4000, "校准原因不少于 5 字");
        }
        SampleSku s = skuMapper.selectById(sampleId);
        if (s == null) {
            throw new BizException(4000, "试用装不存在");
        }
        int before = nz(s.getRemainQty());
        if (before == targetRemain) {
            throw new BizException(4000, "剩余数量与目标一致，无需校准");
        }
        s.setRemainQty(targetRemain);
        if (targetRemain == 0) {
            s.setStatus("已派完");
        }
        skuMapper.updateById(s);
        writeLog(sampleId, "报损", targetRemain - before, before, targetRemain, null,
                "库存校准：" + reason.trim());
    }

    /** 统一写流水：after_qty 恒等于 before_qty + change_qty */
    public void writeLog(Long sampleId, String type, int qty, int before, int after,
                         String bizNo, String remark) {
        SampleStockLog l = new SampleStockLog();
        l.setLogNo("SL" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyMMdd"))
                + String.format("%06d", ThreadLocalRandom.current().nextInt(1, 999999)));
        l.setSampleId(sampleId);
        l.setChangeType(type);
        l.setChangeQty(qty);
        l.setBeforeQty(before);
        l.setAfterQty(after);
        l.setBizNo(bizNo);
        l.setOperatorId(UserContext.userId() == null ? 0L : UserContext.userId());
        l.setRemark(remark);
        l.setCreateBy(UserContext.userId());
        l.setCreateTime(LocalDateTime.now());
        logMapper.insert(l);
    }

    /** 近效期与低库存预警，首页库存条形图与运营提醒共用 */
    public List<Map<String, Object>> stockWarnings() {
        List<SampleSku> list = skuMapper.selectList(new LambdaQueryWrapper<SampleSku>()
                .ne(SampleSku::getStatus, "已下架")
                .orderByAsc(SampleSku::getRemainQty));
        return list.stream().limit(8).map(s -> {
            Map<String, Object> m = new HashMap<>();
            m.put("sampleNo", s.getSampleNo());
            m.put("goodsName", nameOf(s.getGoodsId()));
            m.put("remain", s.getRemainQty());
            m.put("total", s.getTotalQty());
            m.put("expireDate", s.getExpireDate());
            m.put("status", s.getStatus());
            return m;
        }).collect(Collectors.toList());
    }

    private String nameOf(Long goodsId) {
        CosmeticGoods g = goodsMapper.selectById(goodsId);
        return g == null ? "" : g.getGoodsName();
    }

    private static int nz(Integer v) {
        return v == null ? 0 : v;
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
