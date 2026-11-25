package com.grad.beauty.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 
 * 表 sys_oper_log，字段由 sql/init.sql 解析生成，与 DDL 保持一致。
 */
@Data
@TableName("sys_oper_log")
public class SysOperLog {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 业务模块 */
    private String module;

    /** 操作类型 */
    private String operType;

    /** 业务单号 */
    private String bizNo;

    private String content;

    private Long operId;

    private String operName;

    private LocalDateTime operTime;

    private String ip;
}
