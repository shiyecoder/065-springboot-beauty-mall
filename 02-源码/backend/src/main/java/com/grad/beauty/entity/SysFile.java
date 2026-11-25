package com.grad.beauty.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 
 * 表 sys_file，字段由 sql/init.sql 解析生成，与 DDL 保持一致。
 */
@Data
@TableName("sys_file")
public class SysFile {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 原始文件名 */
    private String fileName;

    /** 相对路径 /uploads/xx */
    private String filePath;

    private Long fileSize;

    private String fileType;

    /** 业务类型：goods/report/avatar */
    private String bizType;

    private Long bizId;

    private Long uploaderId;

    private LocalDateTime createTime;

    private Integer deleted;
}
