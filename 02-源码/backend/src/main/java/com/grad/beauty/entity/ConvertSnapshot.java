package com.grad.beauty.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 
 * 表 convert_snapshot，字段由 sql/init.sql 解析生成，与 DDL 保持一致。
 */
@Data
@TableName("convert_snapshot")
public class ConvertSnapshot {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 快照编号 */
    private String snapNo;

    /** 关联 convert_track.id */
    private Long trackId;

    private Long applyId;

    private Long userId;

    private Long goodsId;

    /** 关联 convert_rule.id */
    private Long ruleId;

    /** 计算时规则版本 */
    private String ruleVersion;

    /** 肤质匹配：完全/部分/不匹配/无档案 */
    private String skinMatch;

    private BigDecimal skinScore;

    /** 近180天报告率 */
    private BigDecimal historyRate;

    private BigDecimal historyScore;

    /** 报告完整度得分 */
    private BigDecimal reportComplete;

    private BigDecimal reportScore;

    private Integer browseMin;

    private Integer cartTimes;

    private BigDecimal browseScore;

    /** 用户历史客单价 */
    private BigDecimal avgAmount;

    private BigDecimal orderScore;

    private BigDecimal totalScore;

    private String convertLevel;

    /** 推荐结论 */
    private String conclusion;

    /** 未满足条件 / 可改进项 */
    private String unmet;

    /** 1 已被人工修正 */
    private Integer correctionFlag;

    private LocalDateTime calcTime;

    private LocalDateTime createTime;

    private Integer deleted;
}
