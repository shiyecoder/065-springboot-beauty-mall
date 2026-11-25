package com.grad.beauty.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 主键
 * 表 sys_role，字段由 sql/init.sql 解析生成，与 DDL 保持一致。
 */
@Data
@TableName("sys_role")
public class SysRole {

    /** 主键 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 角色名称 */
    private String roleName;

    /** 角色编码，与 JWT 权限一致 */
    private String roleCode;

    /** 数据范围：全部/本部门/本人 */
    private String dataScope;

    /** 1启用 0停用 */
    private Integer status;

    /** 说明 */
    private String remark;

    private Long createBy;

    private LocalDateTime createTime;

    private Long updateBy;

    private LocalDateTime updateTime;

    private Integer deleted;

    private Integer version;
}
