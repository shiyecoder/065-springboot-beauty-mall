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
 * 表 skin_profile，字段由 sql/init.sql 解析生成，与 DDL 保持一致。
 */
@Data
@TableName("skin_profile")
public class SkinProfile {

    /** 主键 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 规则 FZ+yyMMdd+5位序号，全局唯一 */
    private String profileNo;

    /** 关联 sys_user.id，一人一档 */
    private Long userId;

    /** 干性/油性/混合/敏感/中性 */
    private String skinType;

    /** 不敏感/一般/易敏感/高度敏感 */
    private String sensitiveLevel;

    /** 保湿/控油/美白/抗皱/祛痘，多选逗号分隔 */
    private String demandTags;

    /** 0至100，按问卷选项加权 */
    private BigDecimal selfTestScore;

    /** 如酒精、香精，最多100字 */
    private String allergyIngredients;

    /** 问卷调整后递增，历史档案不重算 */
    private String paperVersion;

    /** 重新提交自测时更新 */
    private LocalDate updateDate;

    /** 1有效 0失效 */
    private Integer status;

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
