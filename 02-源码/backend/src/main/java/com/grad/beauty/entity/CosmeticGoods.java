package com.grad.beauty.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 主键
 * 表 cosmetic_goods，字段由 sql/init.sql 解析生成，与 DDL 保持一致。
 */
@Data
@TableName("cosmetic_goods")
public class CosmeticGoods {

    /** 主键 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 规则 MZ+yyMMdd+4位序号，全局唯一 */
    private String goodsNo;

    /** 2至60字，含品牌与系列 */
    private String goodsName;

    /** 须在品牌字典中存在 */
    private String brand;

    /** 精华/面霜/洁面/防晒/彩妆/面膜 */
    private String goodsType;

    /** 干性/油性/混合/敏感/中性，多选逗号分隔 */
    private String skinType;

    /** 保湿/美白/抗皱/控油/舒缓，多选逗号分隔 */
    private String effectTags;

    /** 5至500，单位毫升 */
    private Integer specMl;

    /** 0.01至9999.99，后端校验 */
    private BigDecimal salePrice;

    /** 0至9999，下单扣减、退款回补 */
    private Integer stockQty;

    /** 0否 1是，为1时必须已配置试用装 */
    private Integer isTrial;

    /** 待上架/在售/已售罄/已下架 */
    private String status;

    /** 封面图相对路径，扩展字段 */
    private String coverImage;

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
