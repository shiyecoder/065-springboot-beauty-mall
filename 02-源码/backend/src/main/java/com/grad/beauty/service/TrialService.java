package com.grad.beauty.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.grad.beauty.common.BizException;
import com.grad.beauty.common.PageResult;
import com.grad.beauty.common.UserContext;
import com.grad.beauty.dto.Reqs;
import com.grad.beauty.entity.CosmeticGoods;
import com.grad.beauty.entity.SampleApply;
import com.grad.beauty.entity.SampleSku;
import com.grad.beauty.entity.SkinProfile;
import com.grad.beauty.entity.SysMessage;
import com.grad.beauty.entity.SysOperLog;
import com.grad.beauty.entity.TrialReport;
import com.grad.beauty.mapper.CosmeticGoodsMapper;
import com.grad.beauty.mapper.SampleApplyMapper;
import com.grad.beauty.mapper.SampleSkuMapper;
import com.grad.beauty.mapper.SkinProfileMapper;
import com.grad.beauty.mapper.SysMessageMapper;
import com.grad.beauty.mapper.SysOperLogMapper;
import com.grad.beauty.mapper.TrialReportMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

/**
 * 试用申领与报告服务。状态机（需求第 4 节）：
 * 待审核 → 待发放 → 已发放 → 待提交报告 → 已完成；待审核 → 已驳回
 *
 * 所有流转统一走 transition 校验：先判断当前状态是否允许目标状态，
 * 再校验操作人/必填原因，最后在同一事务内更新业务表 + 写状态流水 + 发站内消息。
 * 前端不允许直接提交 status 字段绕过流转。
 */
@Service
@RequiredArgsConstructor
public class TrialService {

    private final SampleApplyMapper applyMapper;
    private final SampleSkuMapper skuMapper;
    private final TrialReportMapper reportMapper;
    private final SkinProfileMapper profileMapper;
    private final CosmeticGoodsMapper goodsMapper;
    private final SysMessageMapper messageMapper;
    private final SysOperLogMapper logMapper;
    private final GoodsService goodsService;

    public static final String ST_PENDING = "待审核";
    public static final String ST_REJECTED = "已驳回";
    public static final String ST_TO_SEND = "待发放";
    public static final String ST_SENT = "已发放";
    public static final String ST_TO_REPORT = "待提交报告";
    public static final String ST_DONE = "已完成";

    /** 状态机：当前状态 → 允许的下一状态（禁止越级） */
    private static final Map<String, List<String>> FLOW = Map.of(
            ST_PENDING, List.of(ST_TO_SEND, ST_REJECTED),
            ST_TO_SEND, List.of(ST_SENT, ST_PENDING),
            ST_SENT, List.of(ST_TO_REPORT, ST_DONE),
            ST_TO_REPORT, List.of(ST_DONE, ST_SENT),
            ST_DONE, List.of(),
            ST_REJECTED, List.of(ST_PENDING));

    // ==================== 申领 ====================

    public PageResult<Map<String, Object>> applyPage(Map<String, Object> q) {
        long page = num(q.get("page"), 1), size = Math.min(num(q.get("size"), 10), 100);
        LambdaQueryWrapper<SampleApply> w = new LambdaQueryWrapper<SampleApply>()
                .orderByDesc(SampleApply::getCreateTime);
        // 数据范围：试用用户只能看自己的；运营/审核员按全部
        if (UserContext.isTrialUser()) {
            w.eq(SampleApply::getUserId, UserContext.userId());
        }
        String kw = str(q.get("keyword"));
        if (!kw.isEmpty()) {
            w.and(x -> x.like(SampleApply::getApplyNo, kw).or()
                    .like(SampleApply::getReceiverName, kw));
        }
        if (!str(q.get("status")).isEmpty()) {
            w.eq(SampleApply::getStatus, str(q.get("status")));
        }
        if (q.get("sampleId") != null && !"".equals(q.get("sampleId"))) {
            w.eq(SampleApply::getSampleId, num(q.get("sampleId"), 0));
        }
        Page<SampleApply> p = applyMapper.selectPage(new Page<>(page, size), w);
        List<Map<String, Object>> rows = p.getRecords().stream().map(this::applyVo)
                .collect(Collectors.toList());
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    public Map<String, Object> applyVo(SampleApply a) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", a.getId());
        m.put("applyNo", a.getApplyNo());
        SampleSku s = skuMapper.selectById(a.getSampleId());
        CosmeticGoods g = s == null ? null : goodsMapper.selectById(s.getGoodsId());
        m.put("sampleId", a.getSampleId());
        m.put("sampleNo", s == null ? "" : s.getSampleNo());
        m.put("sampleSpec", s == null ? null : s.getSpecMl());
        m.put("goodsId", g == null ? null : g.getId());
        m.put("goodsName", g == null ? "" : g.getGoodsName());
        m.put("goodsCover", g == null ? null : g.getCoverImage());
        m.put("brand", g == null ? "" : g.getBrand());
        m.put("userId", a.getUserId());
        m.put("userName", userName(a.getUserId()));
        m.put("skinType", skinTypeOf(a.getSkinProfileId()));
        m.put("applyReason", a.getApplyReason());
        m.put("receiverName", a.getReceiverName());
        m.put("receiverPhone", AuthService.mask(a.getReceiverPhone()));
        m.put("addressDesc", a.getAddressDesc());
        m.put("auditRemark", a.getAuditRemark());
        m.put("expressNo", a.getExpressNo());
        m.put("sendTime", a.getSendTime());
        m.put("status", a.getStatus());
        m.put("createTime", a.getCreateTime());
        Long reportId = reportOfApply(a.getId());
        m.put("reportId", reportId);
        // 报告期限：发放后 15 天
        if (a.getSendTime() != null) {
            LocalDate deadline = a.getSendTime().toLocalDate().plusDays(15);
            m.put("reportDeadline", deadline);
            m.put("daysLeft", ChronoUnit.DAYS.between(LocalDate.now(), deadline));
        }
        return m;
    }

    private Long reportOfApply(Long applyId) {
        TrialReport r = reportMapper.selectOne(new LambdaQueryWrapper<TrialReport>()
                .eq(TrialReport::getApplyId, applyId).last("limit 1"));
        return r == null ? null : r.getId();
    }

    /** 详情：主表 + 肤质快照 + 报告 + 库存情况 + 可执行操作按钮 */
    public Map<String, Object> applyDetail(Long id) {
        SampleApply a = applyMapper.selectById(id);
        if (a == null) {
            throw new BizException(4000, "申领单不存在");
        }
        if (UserContext.isTrialUser() && !a.getUserId().equals(UserContext.userId())) {
            throw new BizException(4003, "无权查看他人申领单");
        }
        Map<String, Object> vo = applyVo(a);
        SkinProfile p = profileMapper.selectById(a.getSkinProfileId());
        if (p != null) {
            Map<String, Object> pv = new LinkedHashMap<>();
            pv.put("skinType", p.getSkinType());
            pv.put("sensitiveLevel", p.getSensitiveLevel());
            pv.put("demandTags", p.getDemandTags());
            pv.put("allergyIngredients", p.getAllergyIngredients());
            pv.put("selfTestScore", p.getSelfTestScore());
            pv.put("paperVersion", p.getPaperVersion());
            pv.put("updateDate", p.getUpdateDate());
            vo.put("profile", pv);
        }
        TrialReport r = reportMapper.selectOne(new LambdaQueryWrapper<TrialReport>()
                .eq(TrialReport::getApplyId, id).last("limit 1"));
        if (r != null) {
            Map<String, Object> rv = new LinkedHashMap<>();
            rv.put("id", r.getId());
            rv.put("reportNo", r.getReportNo());
            rv.put("useDays", r.getUseDays());
            rv.put("absorbScore", r.getAbsorbScore());
            rv.put("mildScore", r.getMildScore());
            rv.put("repurchaseWill", r.getRepurchaseWill());
            rv.put("content", r.getContent());
            rv.put("imageUrls", r.getImageUrls());
            rv.put("allergicFlag", r.getAllergicFlag());
            rv.put("status", r.getStatus());
            vo.put("report", rv);
        }
        SampleSku s = skuMapper.selectById(a.getSampleId());
        if (s != null) {
            vo.put("stockRemain", s.getRemainQty());
            vo.put("expireDate", s.getExpireDate());
        }
        // 可执行操作：由状态机 + 角色决定，前端按此渲染按钮（后端仍需复核）
        List<String> actions = new ArrayList<>();
        if (ST_PENDING.equals(a.getStatus()) && UserContext.isOperator()) {
            actions.add("audit");
        }
        if (ST_TO_SEND.equals(a.getStatus()) && UserContext.isOperator()) {
            actions.add("send");
        }
        if ((ST_SENT.equals(a.getStatus()) || ST_TO_REPORT.equals(a.getStatus()))
                && a.getUserId().equals(UserContext.userId())) {
            actions.add("report");
        }
        if (ST_DONE.equals(a.getStatus())) {
            actions.add("viewReport");
        }
        vo.put("actions", actions);
        return vo;
    }

    /**
     * 提交申领：校验肤质档案、30 天重复申领、试用装可派发与有效期。
     * 通过后固定写 待审核，编号由后端生成（忽略前端传值）。
     */
    @Transactional
    public Map<String, Object> createApply(Reqs.ApplyCreate req) {
        if (req.applyReason().trim().length() < 15) {
            throw new BizException(4000, "申领理由不少于 15 字，请说明当前肌肤问题");
        }
        if (req.receiverName().trim().length() < 2) {
            throw new BizException(4000, "收货人姓名 2-20 字");
        }
        if (!req.receiverPhone().matches("\\d{11}")) {
            throw new BizException(4000, "收货电话必须是 11 位手机号");
        }
        if (req.addressDesc().trim().length() < 8) {
            throw new BizException(4000, "收货地址请填写到门牌号");
        }
        SkinProfile profile = profileMapper.selectOne(new LambdaQueryWrapper<SkinProfile>()
                .eq(SkinProfile::getUserId, UserContext.userId())
                .eq(SkinProfile::getStatus, 1).last("limit 1"));
        if (profile == null) {
            throw new BizException(4000, "请先完成肤质自测，档案未完善时不允许申领");
        }
        SampleSku s = skuMapper.selectById(req.sampleId());
        if (s == null) {
            throw new BizException(4000, "试用装不存在");
        }
        if (!"可派发".equals(s.getStatus())) {
            throw new BizException(4001, "该试用装当前状态为「" + s.getStatus() + "」，不可申领");
        }
        if (s.getExpireDate() != null && s.getExpireDate().isBefore(LocalDate.now())) {
            throw new BizException(4001, "该批次已过期，不可派发");
        }
        if (s.getRemainQty() == null || s.getRemainQty() <= 0) {
            throw new BizException(4009, "该试用装已派完，下次补货后再来");
        }
        // 同一用户同一试用装 30 天内只能一条申领单
        SampleApply exist = applyMapper.selectOne(new LambdaQueryWrapper<SampleApply>()
                .eq(SampleApply::getUserId, UserContext.userId())
                .eq(SampleApply::getSampleId, req.sampleId())
                .ge(SampleApply::getCreateTime, LocalDateTime.now().minusDays(30))
                .orderByDesc(SampleApply::getCreateTime).last("limit 1"));
        if (exist != null) {
            LocalDate next = exist.getCreateTime().toLocalDate().plusDays(30);
            throw new BizException(4009, "你已申领过该试用装，单号 " + exist.getApplyNo()
                    + "，下次可申领日期 " + next);
        }
        SampleApply a = new SampleApply();
        a.setApplyNo("SQ" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyMMdd"))
                + String.format("%06d", ThreadLocalRandom.current().nextInt(1, 999999)));
        a.setSampleId(req.sampleId());
        a.setUserId(UserContext.userId());
        a.setSkinProfileId(profile.getId());
        a.setApplyReason(req.applyReason().trim());
        a.setReceiverName(req.receiverName().trim());
        a.setReceiverPhone(req.receiverPhone());
        a.setAddressDesc(req.addressDesc().trim());
        a.setStatus(ST_PENDING);
        a.setCreateBy(UserContext.userId());
        a.setCreateTime(LocalDateTime.now());
        applyMapper.insert(a);
        notify(a.getUserId(), "试用申领已提交", "申领单 " + a.getApplyNo() + " 已提交，等待品牌运营审核。",
                "待办", "sample_apply", a.getId());
        operLog("申领提交", "新增", a.getApplyNo(), "提交申领，状态 待审核");
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("id", a.getId());
        r.put("applyNo", a.getApplyNo());
        r.put("status", a.getStatus());
        return r;
    }

    /** 审核：通过转 待发放；驳回必须填写不少于 5 字原因 */
    @Transactional
    public Map<String, Object> auditApply(Long id, Reqs.ApplyAudit req) {
        SampleApply a = mustGet(id);
        if (!ST_PENDING.equals(a.getStatus())) {
            throw new BizException(4001, "当前状态「" + a.getStatus() + "」不允许审核，请刷新详情");
        }
        if (!req.pass()) {
            String remark = req.auditRemark() != null && !req.auditRemark().isBlank()
                    ? req.auditRemark() : req.reason();
            if (remark == null || remark.trim().length() < 5) {
                throw new BizException(4000, "驳回必须选择原因并填写不少于 5 字说明");
            }
            transition(a, ST_REJECTED);
            a.setAuditRemark(remark.trim());
            applyMapper.updateById(a);
            notify(a.getUserId(), "试用申领被驳回",
                    "申领单 " + a.getApplyNo() + " 已驳回：" + remark.trim() + "；7 天后可重新申领。",
                    "审核", "sample_apply", a.getId());
            operLog("申领审核", "驳回", a.getApplyNo(), "驳回原因：" + remark.trim());
        } else {
            transition(a, ST_TO_SEND);
            applyMapper.updateById(a);
            notify(a.getUserId(), "试用申领已通过",
                    "申领单 " + a.getApplyNo() + " 审核通过，仓库将尽快发货。",
                    "审核", "sample_apply", a.getId());
            operLog("申领审核", "通过", a.getApplyNo(), "状态 待审核 → 待发放");
        }
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("id", id);
        r.put("status", a.getStatus());
        return r;
    }

    /**
     * 登记发放：扣减库存 + 写流水 + 转 已发放，三步同一事务。
     * 库存不足时整单退回 待审核 并提示运营补货（需求 4、5.3）。
     */
    @Transactional
    public Map<String, Object> sendApply(Long id, Reqs.ApplySend req) {
        SampleApply a = mustGet(id);
        if (!ST_TO_SEND.equals(a.getStatus())) {
            throw new BizException(4001, "当前状态「" + a.getStatus() + "」不允许发放");
        }
        if (req.expressNo().trim().length() < 6) {
            throw new BizException(4000, "快递单号至少 6 位");
        }
        Long dup = applyMapper.selectCount(new LambdaQueryWrapper<SampleApply>()
                .eq(SampleApply::getExpressNo, req.expressNo().trim())
                .ne(SampleApply::getId, id));
        if (dup != null && dup > 0) {
            throw new BizException(4009, "该快递单号已被使用，请核对后重新登记");
        }
        SampleSku s = skuMapper.selectById(a.getSampleId());
        if (s == null) {
            throw new BizException(4000, "关联试用装不存在");
        }
        if (s.getRemainQty() == null || s.getRemainQty() <= 0) {
            // 整单退回待审核并提示补货，不允许负库存
            transition(a, ST_PENDING);
            a.setAuditRemark("库存不足，已退回待审核，请补货后重新审核");
            applyMapper.updateById(a);
            notify(a.getUserId(), "试用装暂时缺货",
                    "申领单 " + a.getApplyNo() + " 因试用装缺货已退回，补货后会重新审核。",
                    "超时", "sample_apply", a.getId());
            throw new BizException(4009, "试用装库存不足，已整单退回待审核并提示运营补货");
        }
        int before = s.getRemainQty();
        int after = before - 1;
        s.setRemainQty(after);
        s.setSentQty(nvl(s.getSentQty()) + 1);
        if (after == 0) {
            s.setStatus("已派完");
        }
        skuMapper.updateById(s);
        goodsService.writeLog(s.getId(), "派发", -1, before, after, a.getApplyNo(), null);

        transition(a, ST_SENT);
        a.setExpressNo(req.expressNo().trim());
        a.setSendTime(LocalDateTime.now());
        applyMapper.updateById(a);
        notify(a.getUserId(), "试用装已发出",
                "申领单 " + a.getApplyNo() + " 已发货，快递单号 " + a.getExpressNo()
                        + "，请在 15 天内提交试用报告。", "系统通知", "sample_apply", a.getId());
        operLog("申领发放", "发放", a.getApplyNo(),
                "登记快递 " + a.getExpressNo() + "，扣减库存 " + before + " → " + after);
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("id", id);
        r.put("status", a.getStatus());
        r.put("remainQty", after);
        return r;
    }

    /** 要求补充肤质档案：退回待审核并记录原因 */
    @Transactional
    public void requireProfile(Long id, String reason) {
        SampleApply a = mustGet(id);
        if (!ST_PENDING.equals(a.getStatus())) {
            throw new BizException(4001, "只有待审核的申领单可以要求补充档案");
        }
        a.setAuditRemark(reason == null || reason.isBlank()
                ? "请先完成肤质自测并完善档案后重新提交" : reason.trim());
        applyMapper.updateById(a);
        notify(a.getUserId(), "请补充肤质档案",
                "申领单 " + a.getApplyNo() + "：" + a.getAuditRemark(), "待办",
                "sample_apply", a.getId());
        operLog("申领审核", "要求补充", a.getApplyNo(), a.getAuditRemark());
    }

    private void transition(SampleApply a, String target) {
        List<String> allowed = FLOW.getOrDefault(a.getStatus(), List.of());
        if (!allowed.contains(target)) {
            throw new BizException(4001, "状态不允许从「" + a.getStatus() + "」流转到「" + target + "」");
        }
        a.setStatus(target);
    }

    private SampleApply mustGet(Long id) {
        SampleApply a = applyMapper.selectById(id);
        if (a == null) {
            throw new BizException(4000, "申领单不存在");
        }
        return a;
    }

    // ==================== 报告 ====================

    public PageResult<Map<String, Object>> reportPage(Map<String, Object> q) {
        long page = num(q.get("page"), 1), size = Math.min(num(q.get("size"), 10), 100);
        LambdaQueryWrapper<TrialReport> w = new LambdaQueryWrapper<TrialReport>()
                .orderByDesc(TrialReport::getCreateTime);
        if (UserContext.isTrialUser()) {
            w.eq(TrialReport::getUserId, UserContext.userId());
        }
        if (!str(q.get("status")).isEmpty()) {
            w.eq(TrialReport::getStatus, str(q.get("status")));
        }
        String kw = str(q.get("keyword"));
        if (!kw.isEmpty()) {
            w.and(x -> x.like(TrialReport::getReportNo, kw));
        }
        if (q.get("hasImage") != null && !"".equals(q.get("hasImage"))) {
            if ("1".equals(str(q.get("hasImage")))) {
                w.isNotNull(TrialReport::getImageUrls);
            } else {
                w.isNull(TrialReport::getImageUrls);
            }
        }
        Page<TrialReport> p = reportMapper.selectPage(new Page<>(page, size), w);
        List<Map<String, Object>> rows = p.getRecords().stream().map(this::reportVo)
                .collect(Collectors.toList());
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    public Map<String, Object> reportVo(TrialReport r) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", r.getId());
        m.put("reportNo", r.getReportNo());
        m.put("applyId", r.getApplyId());
        SampleApply a = applyMapper.selectById(r.getApplyId());
        if (a != null) {
            SampleSku s = skuMapper.selectById(a.getSampleId());
            CosmeticGoods g = s == null ? null : goodsMapper.selectById(s.getGoodsId());
            m.put("applyNo", a.getApplyNo());
            m.put("goodsName", g == null ? "" : g.getGoodsName());
            m.put("sendTime", a.getSendTime());
        }
        m.put("userId", r.getUserId());
        m.put("userName", userName(r.getUserId()));
        m.put("useDays", r.getUseDays());
        m.put("absorbScore", r.getAbsorbScore());
        m.put("mildScore", r.getMildScore());
        m.put("avgScore", Math.round(((r.getAbsorbScore() + r.getMildScore()) / 2.0) * 10) / 10.0);
        m.put("repurchaseWill", r.getRepurchaseWill());
        m.put("content", r.getContent());
        m.put("contentLength", r.getContent() == null ? 0 : r.getContent().length());
        m.put("imageUrls", r.getImageUrls());
        m.put("allergicFlag", r.getAllergicFlag());
        m.put("status", r.getStatus());
        m.put("createTime", r.getCreateTime());
        return m;
    }

    /**
     * 提交报告：一单一报告；使用天数不得超过发放至今天数；
     * 过敏必须补充症状；被驳回后允许修改重提一次并保留首次提交时间。
     */
    @Transactional
    public Map<String, Object> createReport(Reqs.ReportCreate req) {
        SampleApply a = mustGet(req.applyId());
        if (!a.getUserId().equals(UserContext.userId())) {
            throw new BizException(4003, "只能为自己申领的试用装提交报告");
        }
        if (!ST_SENT.equals(a.getStatus()) && !ST_TO_REPORT.equals(a.getStatus())
                && !ST_DONE.equals(a.getStatus())) {
            throw new BizException(4001, "当前状态「" + a.getStatus() + "」不允许提交报告，请先确认收到");
        }
        if (a.getSendTime() == null) {
            throw new BizException(4001, "该申领单尚未发放，无法提交报告");
        }
        long daysSinceSend = ChronoUnit.DAYS.between(a.getSendTime().toLocalDate(), LocalDate.now());
        if (req.useDays() < 1 || req.useDays() > 30) {
            throw new BizException(4000, "使用天数必须在 1-30 天之间");
        }
        if (req.useDays() > daysSinceSend) {
            throw new BizException(4000, "使用天数不得超过发放至今天数（当前 " + daysSinceSend + " 天）");
        }
        if (req.absorbScore() < 1 || req.absorbScore() > 5
                || req.mildScore() < 1 || req.mildScore() > 5) {
            throw new BizException(4000, "吸收感与温和度评分必须在 1-5 星之间");
        }
        if (req.content().trim().length() < 30) {
            throw new BizException(4000, "报告内容不少于 30 字，请描述真实使用感受");
        }
        int allergic = req.allergicFlag() == null ? 0 : req.allergicFlag();
        if (allergic == 1) {
            String sym = req.symptom();
            if ((sym == null || sym.trim().length() < 5)
                    && req.content().trim().length() < 45) {
                throw new BizException(4000, "出现过敏必须补充症状描述（不少于 5 字）");
            }
        }
        TrialReport exist = reportMapper.selectOne(new LambdaQueryWrapper<TrialReport>()
                .eq(TrialReport::getApplyId, a.getId()).last("limit 1"));
        if (exist != null) {
            if ("已驳回".equals(exist.getStatus())) {
                // 驳回后允许修改重提一次，保留首次提交时间
                exist.setUseDays(req.useDays());
                exist.setAbsorbScore(req.absorbScore());
                exist.setMildScore(req.mildScore());
                exist.setRepurchaseWill(req.repurchaseWill());
                exist.setContent(req.content().trim());
                exist.setImageUrls(joinImages(req.imageUrls()));
                exist.setAllergicFlag(allergic);
                exist.setStatus("待审核");
                exist.setUpdateBy(UserContext.userId());
                reportMapper.updateById(exist);
                if (ST_SENT.equals(a.getStatus()) || ST_DONE.equals(a.getStatus())) {
                    a.setStatus(ST_TO_REPORT);
                    applyMapper.updateById(a);
                }
                operLog("报告提交", "重提", exist.getReportNo(), "驳回后修改重提");
                Map<String, Object> r = new LinkedHashMap<>();
                r.put("id", exist.getId());
                r.put("reportNo", exist.getReportNo());
                r.put("status", exist.getStatus());
                r.put("resubmit", true);
                return r;
            }
            throw new BizException(4009, "该申领单已提交过报告（" + exist.getReportNo()
                    + "），一单只允许一份有效报告");
        }
        TrialReport r = new TrialReport();
        r.setReportNo("BG" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyMMdd"))
                + String.format("%06d", ThreadLocalRandom.current().nextInt(1, 999999)));
        r.setApplyId(a.getId());
        r.setUserId(UserContext.userId());
        r.setUseDays(req.useDays());
        r.setAbsorbScore(req.absorbScore());
        r.setMildScore(req.mildScore());
        r.setRepurchaseWill(req.repurchaseWill());
        r.setContent(req.content().trim());
        r.setImageUrls(joinImages(req.imageUrls()));
        r.setAllergicFlag(allergic);
        r.setStatus("待审核");
        r.setCreateBy(UserContext.userId());
        reportMapper.insert(r);
        // 只有「已发放」需要推进到「待提交报告」；已在待提交报告或已完成则保持原状态
        if (ST_SENT.equals(a.getStatus())) {
            transition(a, ST_TO_REPORT);
            applyMapper.updateById(a);
        }
        operLog("报告提交", "新增", r.getReportNo(), "提交试用报告，等待内容审核");
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("id", r.getId());
        res.put("reportNo", r.getReportNo());
        res.put("status", r.getStatus());
        return res;
    }

    /** 报告审核：通过后申领单转已完成并发放正装券；隐藏需通知用户 */
    @Transactional
    public Map<String, Object> auditReport(Long id, Reqs.ReportAudit req) {
        TrialReport r = reportMapper.selectById(id);
        if (r == null) {
            throw new BizException(4000, "报告不存在");
        }
        if (!"待审核".equals(r.getStatus())) {
            throw new BizException(4001, "当前报告状态「" + r.getStatus() + "」不允许审核");
        }
        if (r.getUserId().equals(UserContext.userId())) {
            throw new BizException(4030, "审核人不得审核本人提交的内容");
        }
        SampleApply a = applyMapper.selectById(r.getApplyId());
        if (req.pass()) {
            r.setStatus("已通过");
            reportMapper.updateById(r);
            if (a != null) {
                if (ST_TO_REPORT.equals(a.getStatus()) || ST_SENT.equals(a.getStatus())) {
                    a.setStatus(ST_DONE);
                }
                applyMapper.updateById(a);
                notify(a.getUserId(), "试用报告已通过",
                        "报告 " + r.getReportNo() + " 审核通过，已发放 60 元正装优惠券，"
                                + "可在「我的试用」中使用。", "审核", "trial_report", r.getId());
            }
            operLog("报告审核", "通过", r.getReportNo(), "计入转化统计");
        } else {
            String remark = req.remark();
            if (remark == null || remark.trim().length() < 5) {
                throw new BizException(4000, "驳回报告必须填写不少于 5 字的说明");
            }
            r.setStatus("已驳回");
            reportMapper.updateById(r);
            if (a != null) {
                notify(a.getUserId(), "试用报告被驳回",
                        "报告 " + r.getReportNo() + " 被驳回：" + remark.trim() + "，可修改后重提一次。",
                        "审核", "trial_report", r.getId());
            }
            operLog("报告审核", "驳回", r.getReportNo(), remark.trim());
        }
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("id", id);
        res.put("status", r.getStatus());
        return res;
    }

    private String joinImages(List<String> urls) {
        if (urls == null || urls.isEmpty()) {
            return null;
        }
        List<String> clean = urls.stream().filter(u -> u != null && !u.isBlank())
                .map(String::trim).limit(6).collect(Collectors.toList());
        for (String u : clean) {
            if (u.startsWith("http")) {
                throw new BizException(4000, "图片必须是本地上传的相对路径，不支持外链");
            }
        }
        return clean.isEmpty() ? null : String.join(",", clean);
    }

    // ==================== 通用 ====================

    private String userName(Long userId) {
        return userMapperName(userId);
    }

    @org.springframework.beans.factory.annotation.Autowired
    private com.grad.beauty.mapper.SysUserMapper sysUserMapper;

    private String userMapperName(Long userId) {
        if (userId == null) {
            return "";
        }
        var u = sysUserMapper.selectById(userId);
        return u == null ? "" : u.getRealName();
    }

    private String skinTypeOf(Long profileId) {
        if (profileId == null) {
            return "";
        }
        SkinProfile p = profileMapper.selectById(profileId);
        return p == null ? "" : p.getSkinType();
    }

    public void notify(Long receiverId, String title, String content, String type,
                       String bizType, Long bizId) {
        SysMessage m = new SysMessage();
        m.setReceiverId(receiverId);
        m.setTitle(title);
        m.setContent(content);
        m.setMsgType(type);
        m.setBizType(bizType);
        m.setBizId(bizId);
        m.setReadFlag(0);
        m.setCreateTime(LocalDateTime.now());
        messageMapper.insert(m);
    }

    public void operLog(String module, String type, String bizNo, String content) {
        SysOperLog l = new SysOperLog();
        l.setModule(module);
        l.setOperType(type);
        l.setBizNo(bizNo);
        l.setContent(content);
        l.setOperId(UserContext.userId());
        l.setOperName(UserContext.realName());
        l.setOperTime(LocalDateTime.now());
        l.setIp("127.0.0.1");
        logMapper.insert(l);
    }

    private static int nvl(Integer v) {
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
