package com.grad.beauty.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 主键
 * 表 sample_sku，字段由 sql/init.sql 解析生成，与 DDL 保持一致。
 */
@Data
@TableName("sample_sku")
public class SampleSku {

    /** 主键 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 规则 SY+yyMMdd+4位序号，全局唯一 */
    private String sampleNo;

    /** 关联 cosmetic_goods.id，一个商品可有多个批次 */
    private Long goodsId;

    /** 1至30，不得超过正装规格的三分之一 */
    private Integer specMl;

    /** 0.01至200.00，仅后台可见 */
    private BigDecimal costPrice;

    /** 1至100000，入库后不可直接修改 */
    private Integer totalQty;

    /** 不得超过入库总量，派发时累加 */
    private Integer sentQty;

    /** 等于入库总量减已派发，由系统维护 */
    private Integer remainQty;

    /** 规则 商品ID后4位+yyMMdd */
    private String batchNo;

    /** 不得早于当前日期，过期不可派发 */
    private LocalDate expireDate;

    /** 待上架/可派发/已派完/已过期/已下架 */
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
