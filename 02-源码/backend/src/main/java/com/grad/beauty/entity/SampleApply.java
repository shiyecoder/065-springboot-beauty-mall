package com.grad.beauty.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 主键
 * 表 sample_apply，字段由 sql/init.sql 解析生成，与 DDL 保持一致。
 */
@Data
@TableName("sample_apply")
public class SampleApply {

    /** 主键 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 规则 SQ+yyMMdd+6位序号，全局唯一 */
    private String applyNo;

    /** 关联 sample_sku.id，须为可派发状态 */
    private Long sampleId;

    /** 关联 sys_user.id，同一试用装30天一次 */
    private Long userId;

    /** 关联 skin_profile.id，提交时快照肤质类型 */
    private Long skinProfileId;

    /** 不少于15字，说明当前肌肤问题 */
    private String applyReason;

    /** 2至20字 */
    private String receiverName;

    /** 11位，前台脱敏展示 */
    private String receiverPhone;

    /** 文字描述到门牌，不接地图 */
    private String addressDesc;

    /** 驳回时必填，不少于5字 */
    private String auditRemark;

    /** 发放时手工登记，同号不可重复使用 */
    private String expressNo;

    /** 登记快递单号时写入，作为报告期限起点 */
    private LocalDateTime sendTime;

    /** 待审核/已驳回/待发放/已发放/待提交报告/已完成 */
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
