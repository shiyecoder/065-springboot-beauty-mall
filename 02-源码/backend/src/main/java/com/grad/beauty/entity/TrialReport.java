package com.grad.beauty.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 主键
 * 表 trial_report，字段由 sql/init.sql 解析生成，与 DDL 保持一致。
 */
@Data
@TableName("trial_report")
public class TrialReport {

    /** 主键 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 规则 BG+yyMMdd+6位序号，全局唯一 */
    private String reportNo;

    /** 关联 sample_apply.id，一单一报告 */
    private Long applyId;

    /** 关联 sys_user.id，须为申领人本人 */
    private Long userId;

    /** 1至30，不得超过发放至今天数 */
    private Integer useDays;

    /** 1至5星，后端校验范围 */
    private Integer absorbScore;

    /** 1至5星，后端校验范围 */
    private Integer mildScore;

    /** 一定回购/考虑中/不会回购 */
    private String repurchaseWill;

    /** 不少于30字，敏感词过滤 */
    private String content;

    /** 最多6张相对路径，逗号分隔 */
    private String imageUrls;

    /** 0无 1有，为1时必须描述症状 */
    private Integer allergicFlag;

    /** 待审核/已通过/已驳回/已隐藏 */
    private String status;

    /** 关联 sys_user.id */
    private Long createBy;

    /** 记录创建时间 */
    private LocalDateTime createTime;

    /** 关联 sys_user.id */
    private Long updateBy;

    /** 更新时自动刷新 */
    private LocalDateTime updateTime;

    /** 0正常 1删除，查询默认过滤 */
    private Integer deleted;

    /** 乐观锁，更新时校验并加1 */
    private Integer version;
}
