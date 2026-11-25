package com.grad.beauty.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 主键
 * 表 sys_user，字段由 sql/init.sql 解析生成，与 DDL 保持一致。
 */
@Data
@TableName("sys_user")
public class SysUser {

    /** 主键 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 登录账号 */
    private String username;

    /** BCrypt 密码 */
    private String password;

    /** 姓名/昵称 */
    private String realName;

    /** 手机号，前台脱敏 */
    private String phone;

    /** 邮箱 */
    private String email;

    /** 头像相对路径 */
    private String avatar;

    /** 部门ID */
    private Long deptId;

    /** 部门名称 */
    private String deptName;

    /** 主角色ID */
    private Long roleId;

    /** 信用分，爽约扣分 */
    private Integer creditScore;

    /** 1正常 0停用 */
    private Integer status;

    private Long createBy;

    private LocalDateTime createTime;

    private Long updateBy;

    private LocalDateTime updateTime;

    private Integer deleted;

    private Integer version;
}
