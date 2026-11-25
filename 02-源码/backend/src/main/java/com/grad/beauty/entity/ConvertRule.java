package com.grad.beauty.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 
 * 表 convert_rule，字段由 sql/init.sql 解析生成，与 DDL 保持一致。
 */
@Data
@TableName("convert_rule")
public class ConvertRule {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 规则编号 GZ+yyMMdd+4位 */
    private String ruleNo;

    /** 规则名称 */
    private String ruleName;

    /** 版本号 V1/V2... */
    private String ruleVersion;

    /** 肤质适配度权重 */
    private BigDecimal wSkin;

    /** 历史报告率权重 */
    private BigDecimal wHistory;

    /** 报告完整度权重 */
    private BigDecimal wReport;

    /** 浏览加购权重 */
    private BigDecimal wBrowse;

    /** 客单匹配权重 */
    private BigDecimal wOrder;

    /** 高意向阈值 */
    private BigDecimal highThreshold;

    /** 中意向阈值 */
    private BigDecimal midThreshold;

    /** 草稿/生效/历史 */
    private String status;

    /** 生效时间 */
    private LocalDateTime effectTime;

    private String remark;

    private Long createBy;

    private LocalDateTime createTime;

    private Long updateBy;

    private LocalDateTime updateTime;

    private Integer deleted;

    private Integer version;
}
