package com.grad.beauty.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 主键
 * 表 makeup_order，字段由 sql/init.sql 解析生成，与 DDL 保持一致。
 */
@Data
@TableName("makeup_order")
public class MakeupOrder {

    /** 主键 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 规则 ZD+yyMMdd+6位序号，全局唯一 */
    private String orderNo;

    /** 关联 sys_user.id，单商品30天内最多5件 */
    private Long userId;

    /** 关联 cosmetic_goods.id */
    private Long goodsId;

    /** 1至10，后端复核限购 */
    private Integer buyQty;

    /** 售价乘件数合计 */
    private BigDecimal goodsAmount;

    /** 不超过商品金额 */
    private BigDecimal discountAmount;

    /** 商品金额减优惠，不得为负 */
    private BigDecimal payAmount;

    /** 关联 sample_apply.id，用于转化归因 */
    private Long sourceApplyId;

    /** 微信/支付宝/储值卡，仅登记 */
    private String payType;

    /** 未支付/已支付/已退款 */
    private String payStatus;

    /** 待支付/待发货/已发货/已完成/已退款/已取消 */
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
