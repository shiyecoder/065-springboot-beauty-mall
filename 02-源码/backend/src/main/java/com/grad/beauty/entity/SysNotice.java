package com.grad.beauty.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 
 * 表 sys_notice，字段由 sql/init.sql 解析生成，与 DDL 保持一致。
 */
@Data
@TableName("sys_notice")
public class SysNotice {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String title;

    private String content;

    private LocalDateTime publishTime;

    /** 草稿/已发布/已下线 */
    private String status;

    private Long createBy;

    private LocalDateTime createTime;

    private Integer deleted;
}
