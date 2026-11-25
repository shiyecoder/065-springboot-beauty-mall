package com.grad.beauty.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 
 * 表 convert_correction，字段由 sql/init.sql 解析生成，与 DDL 保持一致。
 */
@Data
@TableName("convert_correction")
public class ConvertCorrection {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 关联 convert_snapshot.id，原快照不被覆盖 */
    private Long snapId;

    private Long trackId;

    private BigDecimal beforeScore;

    private String beforeLevel;

    private String afterLevel;

    /** 不少于5字 */
    private String reason;

    private Long operId;

    private String operName;

    private LocalDateTime operTime;

    private LocalDateTime createTime;

    private Integer deleted;
}
