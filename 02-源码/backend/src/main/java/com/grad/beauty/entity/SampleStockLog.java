package com.grad.beauty.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 主键
 * 表 sample_stock_log，字段由 sql/init.sql 解析生成，与 DDL 保持一致。
 */
@Data
@TableName("sample_stock_log")
public class SampleStockLog {

    /** 主键 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 规则 SL+yyMMdd+6位序号，全局唯一 */
    private String logNo;

    /** 关联 sample_sku.id */
    private Long sampleId;

    /** 入库/派发/退回/报损/过期核销 */
    private String changeType;

    /** 正数增加、负数减少，不得为0 */
    private Integer changeQty;

    /** 0至100000 */
    private Integer beforeQty;

    /** 必须等于变动前数量加变动数量 */
    private Integer afterQty;

    /** 关联申领编号或入库单号 */
    private String bizNo;

    /** 关联 sys_user.id，须为品牌运营或库管 */
    private Long operatorId;

    /** 报损与过期核销必填原因，不少于5字 */
    private String remark;

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
