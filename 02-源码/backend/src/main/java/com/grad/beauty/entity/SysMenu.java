package com.grad.beauty.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 
 * 表 sys_menu，字段由 sql/init.sql 解析生成，与 DDL 保持一致。
 */
@Data
@TableName("sys_menu")
public class SysMenu {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 上级菜单，0为根 */
    private Long parentId;

    private String menuName;

    /** 路由地址 */
    private String path;

    /** 组件路径 */
    private String component;

    /** 权限标识 */
    private String perms;

    /** 目录/菜单/按钮 */
    private String type;

    private String icon;

    private Integer sortNo;

    /** 1显示 0隐藏 */
    private Integer visible;

    private Integer status;

    private LocalDateTime createTime;

    private Integer deleted;
}
