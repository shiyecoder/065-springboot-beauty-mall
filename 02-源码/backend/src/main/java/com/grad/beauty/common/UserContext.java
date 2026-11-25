package com.grad.beauty.common;

/**
 * 当前登录用户上下文。由 JWT 过滤器写入，Controller / Service 只读。
 * 数据范围按需求文档第 2 节三层控制：全部 / 本部门 / 本人。
 */
public class UserContext {

    public record CurrentUser(Long userId, String username, String realName, String roleCode,
                              Long roleId, String orgName, String dataScope) {
    }

    /** 角色编码，与 sys_role.role_code 一致 */
    public static final String ROLE_ADMIN = "admin";        // 系统管理员
    public static final String ROLE_OPERATOR = "operator";  // 品牌运营
    public static final String ROLE_AUDITOR = "auditor";    // 内容审核员
    public static final String ROLE_SERVICE = "service";    // 客服专员
    public static final String ROLE_ANALYST = "analyst";    // 数据分析员
    public static final String ROLE_USER = "user";          // 试用用户

    private static final ThreadLocal<CurrentUser> HOLDER = new ThreadLocal<>();

    public static void set(CurrentUser user) {
        HOLDER.set(user);
    }

    public static CurrentUser get() {
        return HOLDER.get();
    }

    public static Long userId() {
        CurrentUser u = HOLDER.get();
        return u == null ? null : u.userId();
    }

    public static String username() {
        CurrentUser u = HOLDER.get();
        return u == null ? "" : u.username();
    }

    public static String realName() {
        CurrentUser u = HOLDER.get();
        return u == null ? "" : u.realName();
    }

    public static String roleCode() {
        CurrentUser u = HOLDER.get();
        return u == null ? "" : u.roleCode();
    }

    public static Long roleId() {
        CurrentUser u = HOLDER.get();
        return u == null ? null : u.roleId();
    }

    public static String orgName() {
        CurrentUser u = HOLDER.get();
        return u == null ? "" : u.orgName();
    }

    public static String dataScope() {
        CurrentUser u = HOLDER.get();
        return u == null ? "本人" : u.dataScope();
    }

    public static boolean isAdmin() {
        return ROLE_ADMIN.equals(roleCode());
    }

    /** 品牌运营（管理员可兜底） */
    public static boolean isOperator() {
        return ROLE_OPERATOR.equals(roleCode()) || isAdmin();
    }

    public static boolean isAuditor() {
        return ROLE_AUDITOR.equals(roleCode()) || isAdmin();
    }

    public static boolean isService() {
        return ROLE_SERVICE.equals(roleCode()) || isAdmin();
    }

    public static boolean isAnalyst() {
        return ROLE_ANALYST.equals(roleCode()) || isAdmin();
    }

    public static boolean isTrialUser() {
        return ROLE_USER.equals(roleCode());
    }

    /** 管理端角色（有后台侧栏） */
    public static boolean isBackendStaff() {
        return !isTrialUser();
    }

    public static boolean scopeAll() {
        return "全部".equals(dataScope());
    }

    public static boolean scopeDept() {
        return "本部门".equals(dataScope());
    }

    public static void clear() {
        HOLDER.remove();
    }
}
