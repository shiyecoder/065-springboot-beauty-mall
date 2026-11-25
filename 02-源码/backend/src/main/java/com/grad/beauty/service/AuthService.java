package com.grad.beauty.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.grad.beauty.common.BizException;
import com.grad.beauty.common.UserContext;
import com.grad.beauty.dto.Reqs;
import com.grad.beauty.entity.SysMenu;
import com.grad.beauty.entity.SysRole;
import com.grad.beauty.entity.SysRoleMenu;
import com.grad.beauty.entity.SysUser;
import com.grad.beauty.mapper.SysDictDataMapper;
import com.grad.beauty.mapper.SysMenuMapper;
import com.grad.beauty.mapper.SysMessageMapper;
import com.grad.beauty.mapper.SysRoleMapper;
import com.grad.beauty.mapper.SysRoleMenuMapper;
import com.grad.beauty.mapper.SysUserMapper;
import com.grad.beauty.common.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 认证服务：登录、当前用户信息、按角色动态取菜单树、改资料与改密码。
 * 菜单权限三层（目录/菜单/按钮）由 sys_role_menu 决定，登录响应直接带上菜单树，
 * 前端只渲染后端返回的结果，避免前端硬编码侧边栏。
 */
@Service
@RequiredArgsConstructor
public class AuthService {

    private final SysUserMapper userMapper;
    private final SysRoleMapper roleMapper;
    private final SysMenuMapper menuMapper;
    private final SysRoleMenuMapper roleMenuMapper;
    private final SysDictDataMapper dictDataMapper;
    private final SysMessageMapper messageMapper;
    private final PasswordEncoder encoder;
    private final JwtUtil jwtUtil;

    /** 登录：校验密码、状态，签发 JWT，返回用户信息 + 菜单树 + 未读数 */
    public Map<String, Object> login(Reqs.Login req) {
        SysUser user = userMapper.selectOne(new LambdaQueryWrapper<SysUser>()
                .eq(SysUser::getUsername, req.username()));
        if (user == null || !encoder.matches(req.password(), user.getPassword())) {
            throw new BizException(4000, "账号或密码错误");
        }
        if (user.getStatus() != null && user.getStatus() == 0) {
            throw new BizException(4000, "账号已停用，请联系管理员");
        }
        SysRole role = roleMapper.selectById(user.getRoleId());
        if (role == null) {
            throw new BizException(4000, "账号未分配角色");
        }
        UserContext.CurrentUser cu = new UserContext.CurrentUser(user.getId(), user.getUsername(),
                user.getRealName(), role.getRoleCode(), role.getId(),
                user.getDeptName() == null ? "" : user.getDeptName(), role.getDataScope());
        String token = jwtUtil.create(cu);

        Map<String, Object> data = new HashMap<>();
        data.put("token", token);
        data.put("user", userVo(user, role));
        data.put("menus", menusOf(role.getId()));
        data.put("unread", unreadCount(user.getId()));
        data.put("dicts", dictMap());
        return data;
    }

    public Map<String, Object> me() {
        SysUser user = userMapper.selectById(UserContext.userId());
        if (user == null) {
            throw new BizException(4010, "登录状态已失效");
        }
        SysRole role = roleMapper.selectById(user.getRoleId());
        Map<String, Object> data = new HashMap<>();
        data.put("user", userVo(user, role));
        data.put("menus", menusOf(role == null ? null : role.getId()));
        data.put("unread", unreadCount(user.getId()));
        data.put("dicts", dictMap());
        return data;
    }

    /** 用户信息脱敏：手机号中间四位打码（需求 7.3 详情接口要做脱敏） */
    private Map<String, Object> userVo(SysUser u, SysRole role) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", u.getId());
        m.put("username", u.getUsername());
        m.put("realName", u.getRealName());
        m.put("phone", mask(u.getPhone()));
        m.put("email", u.getEmail());
        m.put("avatar", u.getAvatar());
        m.put("deptName", u.getDeptName());
        m.put("creditScore", u.getCreditScore());
        m.put("roleCode", role == null ? "" : role.getRoleCode());
        m.put("roleName", role == null ? "" : role.getRoleName());
        m.put("dataScope", role == null ? "本人" : role.getDataScope());
        return m;
    }

    public static String mask(String phone) {
        if (phone == null || phone.length() < 7) {
            return phone;
        }
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
    }

    /** 菜单树：只返回 visible=1 的目录与菜单，按钮不进树但权限校验仍用 perms */
    public List<Map<String, Object>> menusOf(Long roleId) {
        List<SysMenu> menus = roleId == null ? List.of()
                : menuMapper.selectList(new LambdaQueryWrapper<SysMenu>()
                .inSql(SysMenu::getId, "select menu_id from sys_role_menu where role_id = " + roleId)
                .eq(SysMenu::getVisible, 1).eq(SysMenu::getStatus, 1)
                .ne(SysMenu::getType, "按钮")
                .orderByAsc(SysMenu::getSortNo));
        // 按 parent_id 组树，两层（目录 + 菜单）
        Map<Long, List<SysMenu>> byParent = new LinkedHashMap<>();
        for (SysMenu m : menus) {
            byParent.computeIfAbsent(m.getParentId(), k -> new ArrayList<>()).add(m);
        }
        List<Map<String, Object>> roots = new ArrayList<>();
        for (SysMenu root : byParent.getOrDefault(0L, List.of())) {
            Map<String, Object> node = menuVo(root);
            List<Map<String, Object>> children = new ArrayList<>();
            for (SysMenu c : byParent.getOrDefault(root.getId(), List.of())) {
                children.add(menuVo(c));
            }
            node.put("children", children);
            roots.add(node);
        }
        return roots;
    }

    private Map<String, Object> menuVo(SysMenu m) {
        Map<String, Object> node = new LinkedHashMap<>();
        node.put("id", m.getId());
        node.put("name", m.getMenuName());
        node.put("path", m.getPath());
        node.put("component", m.getComponent());
        node.put("perms", m.getPerms());
        node.put("type", m.getType());
        node.put("icon", m.getIcon());
        return node;
    }

    /** 字典全量，前端登录后一次缓存，下拉统一从这里取，避免各页硬编码枚举 */
    public Map<String, List<Map<String, Object>>> dictMap() {
        Map<String, List<Map<String, Object>>> out = new LinkedHashMap<>();
        dictDataMapper.selectList(new LambdaQueryWrapper<com.grad.beauty.entity.SysDictData>()
                        .eq(com.grad.beauty.entity.SysDictData::getStatus, 1)
                        .orderByAsc(com.grad.beauty.entity.SysDictData::getSortNo))
                .forEach(d -> out.computeIfAbsent(d.getDictType(), k -> new ArrayList<>()).add(
                        Map.of("label", d.getDictLabel(), "value", d.getDictValue(),
                                "style", d.getTagStyle() == null ? "info" : d.getTagStyle())));
        return out;
    }

    public long unreadCount(Long userId) {
        return messageMapper.selectCount(new LambdaQueryWrapper<com.grad.beauty.entity.SysMessage>()
                .eq(com.grad.beauty.entity.SysMessage::getReceiverId, userId)
                .eq(com.grad.beauty.entity.SysMessage::getReadFlag, 0));
    }

    /** 改资料：姓名/手机/邮箱/头像，头像上传后右上角同步显示 */
    public void updateProfile(Reqs.Profile req) {
        SysUser u = userMapper.selectById(UserContext.userId());
        if (u == null) {
            throw new BizException(4010, "登录状态已失效");
        }
        if (req.realName() != null && !req.realName().isBlank()) {
            u.setRealName(req.realName().trim());
        }
        if (req.phone() != null && !req.phone().isBlank()) {
            if (!req.phone().matches("\\d{11}")) {
                throw new BizException(4000, "手机号必须是 11 位数字");
            }
            u.setPhone(req.phone());
        }
        if (req.email() != null) {
            u.setEmail(req.email());
        }
        if (req.avatar() != null && !req.avatar().isBlank()) {
            if (req.avatar().startsWith("http")) {
                throw new BizException(4000, "头像必须是本地上传的相对路径，不支持外链");
            }
            u.setAvatar(req.avatar());
        }
        userMapper.updateById(u);
    }

    public void changePassword(Reqs.ChangePwd req) {
        SysUser u = userMapper.selectById(UserContext.userId());
        if (u == null || !encoder.matches(req.oldPassword(), u.getPassword())) {
            throw new BizException(4000, "原密码不正确");
        }
        if (req.newPassword().length() < 6) {
            throw new BizException(4000, "新密码至少 6 位");
        }
        userMapper.update(null, new LambdaUpdateWrapper<SysUser>()
                .eq(SysUser::getId, u.getId())
                .set(SysUser::getPassword, encoder.encode(req.newPassword()))
                .set(SysUser::getUpdateTime, LocalDateTime.now()));
    }
}
