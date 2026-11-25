package com.grad.beauty.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * 入参 DTO 集合。用嵌套 record 收拢到一个文件，避免为每个小请求建一个类；
 * 所有校验注解与需求 7.3「写接口必须做参数校验」一一对应。
 */
public class Reqs {

    /** 登录 */
    public record Login(@NotBlank String username, @NotBlank String password) {
    }

    /** 修改密码 */
    public record ChangePwd(@NotBlank String oldPassword, @NotBlank String newPassword) {
    }

    /** 修改个人资料 */
    public record Profile(String realName, String phone, String email, String avatar) {
    }

    /** 新增/修改商品 */
    public record Goods(
            @NotBlank String goodsName,
            @NotBlank String brand,
            @NotBlank String goodsType,
            @NotBlank String skinType,
            @NotBlank String effectTags,
            @NotNull Integer specMl,
            @NotNull BigDecimal salePrice,
            @NotNull Integer stockQty,
            Integer isTrial,
            String status,
            String coverImage,
            Integer version) {
    }

    /** 新增试用装 */
    public record Sample(
            @NotNull Long goodsId,
            @NotNull Integer specMl,
            @NotNull BigDecimal costPrice,
            @NotNull Integer totalQty,
            String batchNo,
            @NotBlank String expireDate,
            String status) {
    }

    /** 出入库登记 */
    public record StockChange(
            @NotNull Long sampleId,
            @NotBlank String changeType,
            @NotNull Integer changeQty,
            String bizNo,
            String remark) {
    }

    /** 提交试用申领 */
    public record ApplyCreate(
            @NotNull Long sampleId,
            @NotBlank String applyReason,
            @NotBlank String receiverName,
            @NotBlank String receiverPhone,
            @NotBlank String addressDesc) {
    }

    /** 审核申领 */
    public record ApplyAudit(boolean pass, String auditRemark, String reason) {
    }

    /** 登记发放 */
    public record ApplySend(@NotBlank String expressNo, String expressCompany) {
    }

    /** 提交试用报告 */
    public record ReportCreate(
            @NotNull Long applyId,
            @NotNull Integer useDays,
            @NotNull Integer absorbScore,
            @NotNull Integer mildScore,
            @NotBlank String repurchaseWill,
            @NotBlank String content,
            List<String> imageUrls,
            Integer allergicFlag,
            String symptom) {
    }

    /** 报告审核 */
    public record ReportAudit(boolean pass, String remark) {
    }

    /** 下单 */
    public record OrderCreate(
            @NotNull Long goodsId,
            @NotNull Integer buyQty,
            String sourceApplyNo,
            @NotBlank String payType,
            String receiverName,
            String receiverPhone,
            String addressDesc) {
    }

    /** 转化规则保存 */
    public record RuleSave(
            @NotBlank String ruleName,
            @NotNull BigDecimal wSkin,
            @NotNull BigDecimal wHistory,
            @NotNull BigDecimal wReport,
            @NotNull BigDecimal wBrowse,
            @NotNull BigDecimal wOrder,
            BigDecimal highThreshold,
            BigDecimal midThreshold) {
    }

    /** 人工修正 */
    public record Correction(@NotBlank String afterLevel, @NotBlank String reason) {
    }

    /** 跟进登记 */
    public record Follow(@NotBlank String followStatus, String orderNo, String remark) {
    }

    /** 肤质自测提交 */
    public record SkinTest(
            @NotBlank String skinType,
            @NotBlank String sensitiveLevel,
            @NotBlank String demandTags,
            String allergyIngredients,
            Integer selfTestScore,
            String paperVersion,
            Map<String, Object> answers) {
    }

    /** 退款 */
    public record Refund(@NotBlank String reason) {
    }
}
