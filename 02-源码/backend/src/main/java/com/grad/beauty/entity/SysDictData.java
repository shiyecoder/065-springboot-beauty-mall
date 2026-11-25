package com.grad.beauty.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 
 * 表 sys_dict_data，字段由 sql/init.sql 解析生成，与 DDL 保持一致。
 */
@Data
@TableName("sys_dict_data")
public class SysDictData {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String dictType;

    private String dictLabel;

    private String dictValue;

    /** 标签样式 success/warning/danger/primary/info */
    private String tagStyle;

    private Integer sortNo;

    private Integer status;

    private LocalDateTime createTime;

    private Integer deleted;
}
