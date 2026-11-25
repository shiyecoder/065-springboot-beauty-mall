package com.grad.beauty.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.grad.beauty.common.BizException;
import com.grad.beauty.common.R;
import com.grad.beauty.common.UserContext;
import com.grad.beauty.dto.Reqs;
import com.grad.beauty.entity.SkinProfile;
import com.grad.beauty.mapper.SkinProfileMapper;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

/**
 * 肤质档案：一人一档，自测提交后覆盖更新（保留问卷版本，历史档案不重算）。
 * 档案是申领与转化评分的前提，未完善时申领按钮置灰、后端直接拒绝。
 */
@RestController
@RequestMapping("/api/skin-profile")
@RequiredArgsConstructor
public class ProfileController {

    private final SkinProfileMapper profileMapper;

    @GetMapping("/mine")
    public R<?> mine() {
        SkinProfile p = profileMapper.selectOne(new LambdaQueryWrapper<SkinProfile>()
                .eq(SkinProfile::getUserId, UserContext.userId())
                .eq(SkinProfile::getStatus, 1).last("limit 1"));
        if (p == null) {
            return R.ok(null);
        }
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", p.getId());
        m.put("profileNo", p.getProfileNo());
        m.put("skinType", p.getSkinType());
        m.put("sensitiveLevel", p.getSensitiveLevel());
        m.put("demandTags", p.getDemandTags());
        m.put("selfTestScore", p.getSelfTestScore());
        m.put("allergyIngredients", p.getAllergyIngredients());
        m.put("paperVersion", p.getPaperVersion());
        m.put("updateDate", p.getUpdateDate());
        return R.ok(m);
    }

    @GetMapping("/page")
    public R<?> page(@RequestParam Map<String, Object> q) {
        var list = profileMapper.selectList(new LambdaQueryWrapper<SkinProfile>()
                .eq(SkinProfile::getStatus, 1).orderByDesc(SkinProfile::getUpdateDate));
        return R.ok(com.grad.beauty.common.PageResult.of(list.size(), 1, list.size(), list));
    }

    @PostMapping
    public R<?> submit(@Valid @RequestBody Reqs.SkinTest req) {
        if (req.selfTestScore() == null || req.selfTestScore() < 0 || req.selfTestScore() > 100) {
            throw new BizException(4000, "自测得分必须在 0-100 之间");
        }
        SkinProfile p = profileMapper.selectOne(new LambdaQueryWrapper<SkinProfile>()
                .eq(SkinProfile::getUserId, UserContext.userId()).last("limit 1"));
        if (p == null) {
            p = new SkinProfile();
            p.setProfileNo("FZ" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyMMdd"))
                    + String.format("%05d", ThreadLocalRandom.current().nextInt(1, 99999)));
            p.setUserId(UserContext.userId());
            p.setPaperVersion(req.paperVersion() == null ? "V2" : req.paperVersion());
            p.setCreateBy(UserContext.userId());
            p.setCreateTime(LocalDateTime.now());
        }
        p.setSkinType(req.skinType());
        p.setSensitiveLevel(req.sensitiveLevel());
        p.setDemandTags(req.demandTags());
        p.setAllergyIngredients(req.allergyIngredients());
        p.setSelfTestScore(java.math.BigDecimal.valueOf(req.selfTestScore()));
        p.setUpdateDate(LocalDate.now());
        p.setStatus(1);
        if (p.getId() == null) {
            profileMapper.insert(p);
        } else {
            profileMapper.updateById(p);
        }
        return R.ok(Map.of("id", p.getId(), "profileNo", p.getProfileNo()));
    }
}
