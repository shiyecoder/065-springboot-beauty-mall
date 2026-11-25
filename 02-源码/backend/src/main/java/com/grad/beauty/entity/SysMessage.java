package com.grad.beauty.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 
 * 表 sys_message，字段由 sql/init.sql 解析生成，与 DDL 保持一致。
 */
@Data
@TableName("sys_message")
public class SysMessage {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 接收人 */
    private Long receiverId;

    private String title;

    private String content;

    /** 待办/审核/超时/系统通知 */
    private String msgType;

    private String bizType;

    private Long bizId;

    /** 0未读 1已读 */
    private Integer readFlag;

    private LocalDateTime createTime;

    private Integer deleted;
}
