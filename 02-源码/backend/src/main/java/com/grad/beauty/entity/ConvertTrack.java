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
 * 表 convert_track，字段由 sql/init.sql 解析生成，与 DDL 保持一致。
 */
@Data
@TableName("convert_track")
public class ConvertTrack {

    /** 主键 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 规则 ZH+yyMMdd+6位序号，全局唯一 */
    private String trackNo;

    /** 关联 sample_apply.id，一申领单一条跟踪 */
    private Long applyId;

    /** 关联 sys_user.id */
    private Long userId;

    /** 0至600，按详情页停留累计，单次超30分钟按30计 */
    private Integer browseMin;

    /** 0至20，取消加购不减计数 */
    private Integer cartTimes;

    /** 0至100，每日重算 */
    private BigDecimal convertScore;

    /** 高意向/中意向/低意向/待评估 */
    private String convertLevel;

    /** 关联 makeup_order.id，下单后回填 */
    private Long orderId;

    /** 发放后30天，超窗订单不计入转化 */
    private LocalDate attributionEnd;

    /** 未跟进/已触达/已下单/已放弃 */
    private String followStatus;

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
