package com.grad.beauty.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.grad.beauty.common.BizException;
import com.grad.beauty.common.PageResult;
import com.grad.beauty.common.UserContext;
import com.grad.beauty.entity.SysDictData;
import com.grad.beauty.entity.SysDictType;
import com.grad.beauty.entity.SysMenu;
import com.grad.beauty.entity.SysMessage;
import com.grad.beauty.entity.SysNotice;
import com.grad.beauty.entity.SysOperLog;
import com.grad.beauty.entity.SysRole;
import com.grad.beauty.entity.SysRoleMenu;
import com.grad.beauty.entity.SysUser;
import com.grad.beauty.mapper.SysDictDataMapper;
import com.grad.beauty.mapper.SysDictTypeMapper;
import com.grad.beauty.mapper.SysMenuMapper;
import com.grad.beauty.mapper.SysMessageMapper;
import com.grad.beauty.mapper.SysNoticeMapper;
import com.grad.beauty.mapper.SysOperLogMapper;
import com.grad.beauty.mapper.SysRoleMapper;
import com.grad.beauty.mapper.SysRoleMenuMapper;
import com.grad.beauty.mapper.SysUserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 系统管理：用户、角色与分配菜单、菜单树、字典、操作日志、站内消息。
 * 「菜单管理」与「分配菜单」本身不出现在菜单树里（需求硬性第 12 条）。
 */
@Service
@RequiredArgsConstructor
public class SystemService {

    private final SysUserMapper userMapper;
    private final SysRoleMapper roleMapper;
    private final SysRoleMenuMapper roleMenuMapper;
    private final SysMenuMapper menuMapper;
    private final SysDictTypeMapper dictTypeMapper;
    private final SysDictDataMapper dictDataMapper;
    private final SysOperLogMapper logMapper;
    private final SysMessageMapper messageMapper;
    private final SysNoticeMapper noticeMapper;
    private final PasswordEncoder encoder;

    // ---------------- 用户 ----------------
    public PageResult<Map<String, Object>> userPage(Map<String, Object> q) {
        long page = num(q.get("page"), 1), size = Math.min(num(q.get("size"), 10), 100);
        LambdaQueryWrapper<SysUser> w = new LambdaQueryWrapper<SysUser>().orderByDesc(SysUser::getId);
        String kw = str(q.get("keyword"));
        if (!kw.isEmpty()) {
            w.and(x -> x.like(SysUser::getUsername, kw).or().like(SysUser::getRealName, kw));
        }
        if (q.get("roleId") != null && !"".equals(q.get("roleId"))) {
            w.eq(SysUser::getRoleId, num(q.get("roleId"), 0));
        }
        if (q.get("status") != null && !"".equals(q.get("status"))) {
            w.eq(SysUser::getStatus, num(q.get("status"), 1));
        }
        Page<SysUser> p = userMapper.selectPage(new Page<>(page, size), w);
        List<Map<String, Object>> rows = p.getRecords().stream().map(u -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", u.getId());
            m.put("username", u.getUsername());
            m.put("realName", u.getRealName());
            m.put("phone", AuthService.mask(u.getPhone()));
            m.put("avatar", u.getAvatar());
            m.put("deptName", u.getDeptName());
            SysRole r = roleMapper.selectById(u.getRoleId());
            m.put("roleId", u.getRoleId());
            m.put("roleName", r == null ? "" : r.getRoleName());
            m.put("creditScore", u.getCreditScore());
            m.put("status", u.getStatus());
            m.put("createTime", u.getCreateTime());
            return m;
        }).collect(Collectors.toList());
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    @Transactional
    public Long saveUser(Map<String, Object> body) {
        Long id = body.get("id") == null ? null : Long.valueOf(str(body.get("id")));
        SysUser u = id == null ? new SysUser() : userMapper.selectById(id);
        if (u == null) {
            throw new BizException(4000, "用户不存在");
        }
        String username = str(body.get("username"));
        if (id == null) {
            if (username.length() < 3) {
                throw new BizException(4000, "账号至少 3 位");
            }
            Long dup = userMapper.selectCount(new LambdaQueryWrapper<SysUser>()
                    .eq(SysUser::getUsername, username));
            if (dup != null && dup > 0) {
                throw new BizException(4009, "账号已存在");
            }
            u.setUsername(username);
            u.setPassword(encoder.encode(str(body.get("password")).isEmpty()
                    ? "123456" : str(body.get("password"))));
            u.setCreateTime(LocalDateTime.now());
        }
        u.setRealName(str(body.get("realName")));
        String phone = str(body.get("phone"));
        if (!phone.matches("\\d{11}")) {
            throw new BizException(4000, "手机号必须是 11 位数字");
        }
        u.setPhone(phone);
        u.setEmail(str(body.get("email")));
        u.setAvatar(str(body.get("avatar")));
        u.setDeptName(str(body.get("deptName")));
        u.setRoleId(Long.valueOf(str(body.get("roleId")).isEmpty() ? "6" : str(body.get("roleId"))));
        u.setStatus(str(body.get("status")).isEmpty() ? 1 : Integer.parseInt(str(body.get("status"))));
        if (id == null) {
            userMapper.insert(u);
        } else {
            userMapper.updateById(u);
        }
        return u.getId();
    }

    @Transactional
    public void resetPassword(Long id) {
        userMapper.update(null, new LambdaUpdateWrapper<SysUser>().eq(SysUser::getId, id)
                .set(SysUser::getPassword, encoder.encode("123456")));
    }

    // ---------------- 角色 ----------------
    public List<Map<String, Object>> roleList() {
        return roleMapper.selectList(new LambdaQueryWrapper<SysRole>().orderByAsc(SysRole::getId))
                .stream().map(r -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("id", r.getId());
                    m.put("roleName", r.getRoleName());
                    m.put("roleCode", r.getRoleCode());
                    m.put("dataScope", r.getDataScope());
                    m.put("status", r.getStatus());
                    m.put("remark", r.getRemark());
                    m.put("userCount", userMapper.selectCount(new LambdaQueryWrapper<SysUser>()
                            .eq(SysUser::getRoleId, r.getId())));
                    m.put("menuIds", roleMenuMapper.selectList(new LambdaQueryWrapper<SysRoleMenu>()
                                    .eq(SysRoleMenu::getRoleId, r.getId()))
                            .stream().map(SysRoleMenu::getMenuId).collect(Collectors.toList()));
                    return m;
                }).collect(Collectors.toList());
    }

    /** 为角色分配菜单：先清空再插入，按钮权限一并写入 */
    @Transactional
    public void assignMenus(Long roleId, List<Long> menuIds) {
        SysRole role = roleMapper.selectById(roleId);
        if (role == null) {
            throw new BizException(4000, "角色不存在");
        }
        if ("admin".equals(role.getRoleCode())) {
            throw new BizException(4030, "系统管理员的菜单权限不可调整");
        }
        roleMenuMapper.delete(new LambdaQueryWrapper<SysRoleMenu>().eq(SysRoleMenu::getRoleId, roleId));
        for (Long mid : menuIds) {
            SysRoleMenu rm = new SysRoleMenu();
            rm.setRoleId(roleId);
            rm.setMenuId(mid);
            roleMenuMapper.insert(rm);
        }
    }

    /** 菜单树（含按钮），但隐藏「菜单管理」与「分配菜单」 */
    public List<Map<String, Object>> menuTree() {
        List<SysMenu> all = menuMapper.selectList(new LambdaQueryWrapper<SysMenu>()
                .eq(SysMenu::getStatus, 1).orderByAsc(SysMenu::getSortNo));
        Map<Long, List<SysMenu>> byParent = new LinkedHashMap<>();
        for (SysMenu m : all) {
            if (m.getMenuName().contains("菜单管理") || m.getMenuName().contains("分配菜单")) {
                continue;
            }
            byParent.computeIfAbsent(m.getParentId(), k -> new ArrayList<>()).add(m);
        }
        List<Map<String, Object>> roots = new ArrayList<>();
        for (SysMenu r : byParent.getOrDefault(0L, List.of())) {
            Map<String, Object> node = new LinkedHashMap<>();
            node.put("id", r.getId());
            node.put("name", r.getMenuName());
            node.put("path", r.getPath());
            node.put("type", r.getType());
            node.put("perms", r.getPerms());
            node.put("sortNo", r.getSortNo());
            List<Map<String, Object>> children = new ArrayList<>();
            for (SysMenu c : byParent.getOrDefault(r.getId(), List.of())) {
                Map<String, Object> cn = new LinkedHashMap<>();
                cn.put("id", c.getId());
                cn.put("name", c.getMenuName());
                cn.put("path", c.getPath());
                cn.put("type", c.getType());
                cn.put("perms", c.getPerms());
                cn.put("sortNo", c.getSortNo());
                children.add(cn);
            }
            node.put("children", children);
            roots.add(node);
        }
        return roots;
    }

    // ---------------- 字典 ----------------
    public List<Map<String, Object>> dictList() {
        List<SysDictType> types = dictTypeMapper.selectList(new LambdaQueryWrapper<SysDictType>()
                .orderByAsc(SysDictType::getId));
        List<Map<String, Object>> out = new ArrayList<>();
        for (SysDictType t : types) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", t.getId());
            m.put("dictType", t.getDictType());
            m.put("dictName", t.getDictName());
            m.put("items", dictDataMapper.selectList(new LambdaQueryWrapper<SysDictData>()
                            .eq(SysDictData::getDictType, t.getDictType())
                            .orderByAsc(SysDictData::getSortNo))
                    .stream().map(d -> {
                        Map<String, Object> dm = new LinkedHashMap<>();
                        dm.put("id", d.getId());
                        dm.put("label", d.getDictLabel());
                        dm.put("value", d.getDictValue());
                        dm.put("style", d.getTagStyle());
                        dm.put("sortNo", d.getSortNo());
                        dm.put("status", d.getStatus());
                        return dm;
                    }).collect(Collectors.toList()));
            out.add(m);
        }
        return out;
    }

    // ---------------- 日志 / 消息 / 公告 ----------------
    public PageResult<Map<String, Object>> logPage(Map<String, Object> q) {
        long page = num(q.get("page"), 1), size = Math.min(num(q.get("size"), 10), 100);
        LambdaQueryWrapper<SysOperLog> w = new LambdaQueryWrapper<SysOperLog>()
                .orderByDesc(SysOperLog::getOperTime);
        if (!str(q.get("module")).isEmpty()) {
            w.eq(SysOperLog::getModule, str(q.get("module")));
        }
        String kw = str(q.get("keyword"));
        if (!kw.isEmpty()) {
            w.and(x -> x.like(SysOperLog::getOperName, kw).or().like(SysOperLog::getBizNo, kw));
        }
        Page<SysOperLog> p = logMapper.selectPage(new Page<>(page, size), w);
        return PageResult.of(p.getTotal(), page, size, p.getRecords().stream().map(l -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", l.getId());
            m.put("module", l.getModule());
            m.put("operType", l.getOperType());
            m.put("bizNo", l.getBizNo());
            m.put("content", l.getContent());
            m.put("operName", l.getOperName());
            m.put("operTime", l.getOperTime());
            m.put("ip", l.getIp());
            return m;
        }).collect(Collectors.toList()));
    }

    public List<Map<String, Object>> myMessages() {
        return messageMapper.selectList(new LambdaQueryWrapper<SysMessage>()
                        .eq(SysMessage::getReceiverId, UserContext.userId())
                        .orderByDesc(SysMessage::getCreateTime).last("limit 50"))
                .stream().map(m -> {
                    Map<String, Object> v = new LinkedHashMap<>();
                    v.put("id", m.getId());
                    v.put("title", m.getTitle());
                    v.put("content", m.getContent());
                    v.put("msgType", m.getMsgType());
                    v.put("bizType", m.getBizType());
                    v.put("bizId", m.getBizId());
                    v.put("readFlag", m.getReadFlag());
                    v.put("createTime", m.getCreateTime());
                    return v;
                }).collect(Collectors.toList());
    }

    public void readMessage(Long id) {
        messageMapper.update(null, new LambdaUpdateWrapper<SysMessage>()
                .eq(SysMessage::getId, id)
                .eq(SysMessage::getReceiverId, UserContext.userId())
                .set(SysMessage::getReadFlag, 1));
    }

    public void readAll() {
        messageMapper.update(null, new LambdaUpdateWrapper<SysMessage>()
                .eq(SysMessage::getReceiverId, UserContext.userId())
                .set(SysMessage::getReadFlag, 1));
    }

    public List<SysNotice> notices() {
        return noticeMapper.selectList(new LambdaQueryWrapper<SysNotice>()
                .eq(SysNotice::getStatus, "已发布").orderByDesc(SysNotice::getPublishTime));
    }

    private static long num(Object o, long def) {
        if (o == null || "".equals(o)) {
            return def;
        }
        try {
            return Long.parseLong(String.valueOf(o));
        } catch (NumberFormatException e) {
            return def;
        }
    }

    private static String str(Object o) {
        return o == null ? "" : String.valueOf(o).trim();
    }
}
