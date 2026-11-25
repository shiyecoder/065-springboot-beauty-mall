-- ============================================================
-- NEW-065 美妆护肤商城与试用装派发系统 初始化脚本
-- 生成时间：2026-11-02 09:00:00　｜　可重复执行（DROP + CREATE）
-- 表：8 业务 + 11 系统 + 3 创新点 = 22 张
-- ============================================================
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
DROP DATABASE IF EXISTS `new_065`;
CREATE DATABASE `new_065` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `new_065`;

-- ---------------- 业务表（取自需求文档 6.5） ----------------
-- 1. cosmetic_goods 美妆商品
CREATE TABLE `cosmetic_goods` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `goods_no` varchar(32) NOT NULL COMMENT '规则 MZ+yyMMdd+4位序号，全局唯一',
  `goods_name` varchar(100) NOT NULL COMMENT '2至60字，含品牌与系列',
  `brand` varchar(40) NOT NULL COMMENT '须在品牌字典中存在',
  `goods_type` varchar(20) NOT NULL COMMENT '精华/面霜/洁面/防晒/彩妆/面膜',
  `skin_type` varchar(40) NOT NULL COMMENT '干性/油性/混合/敏感/中性，多选逗号分隔',
  `effect_tags` varchar(60) NOT NULL COMMENT '保湿/美白/抗皱/控油/舒缓，多选逗号分隔',
  `spec_ml` int NOT NULL DEFAULT 30 COMMENT '5至500，单位毫升',
  `sale_price` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT '0.01至9999.99，后端校验',
  `stock_qty` int NOT NULL DEFAULT 0 COMMENT '0至9999，下单扣减、退款回补',
  `is_trial` tinyint NOT NULL DEFAULT 0 COMMENT '0否 1是，为1时必须已配置试用装',
  `status` varchar(20) NOT NULL DEFAULT '待上架' COMMENT '待上架/在售/已售罄/已下架',
  `cover_image` varchar(200) DEFAULT NULL COMMENT '封面图相对路径，扩展字段',
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_cosmetic_goods_no` (`goods_no`),
  KEY `idx_type_status` (`goods_type`, `status`),
  KEY `idx_skin_trial` (`skin_type`, `is_trial`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='美妆商品';

-- 2. sample_sku 试用装
CREATE TABLE `sample_sku` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `sample_no` varchar(32) NOT NULL COMMENT '规则 SY+yyMMdd+4位序号，全局唯一',
  `goods_id` bigint NOT NULL COMMENT '关联 cosmetic_goods.id，一个商品可有多个批次',
  `spec_ml` int NOT NULL DEFAULT 5 COMMENT '1至30，不得超过正装规格的三分之一',
  `cost_price` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT '0.01至200.00，仅后台可见',
  `total_qty` int NOT NULL DEFAULT 0 COMMENT '1至100000，入库后不可直接修改',
  `sent_qty` int NOT NULL DEFAULT 0 COMMENT '不得超过入库总量，派发时累加',
  `remain_qty` int NOT NULL DEFAULT 0 COMMENT '等于入库总量减已派发，由系统维护',
  `batch_no` varchar(30) NOT NULL COMMENT '规则 商品ID后4位+yyMMdd',
  `expire_date` date NOT NULL COMMENT '不得早于当前日期，过期不可派发',
  `status` varchar(20) NOT NULL DEFAULT '待上架' COMMENT '待上架/可派发/已派完/已过期/已下架',
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sample_no` (`sample_no`),
  KEY `idx_goods_status` (`goods_id`, `status`),
  KEY `idx_expire_date` (`expire_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='试用装';

-- 3. sample_apply 试用申领
CREATE TABLE `sample_apply` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `apply_no` varchar(32) NOT NULL COMMENT '规则 SQ+yyMMdd+6位序号，全局唯一',
  `sample_id` bigint NOT NULL COMMENT '关联 sample_sku.id，须为可派发状态',
  `user_id` bigint NOT NULL COMMENT '关联 sys_user.id，同一试用装30天一次',
  `skin_profile_id` bigint NOT NULL COMMENT '关联 skin_profile.id，提交时快照肤质类型',
  `apply_reason` varchar(200) NOT NULL COMMENT '不少于15字，说明当前肌肤问题',
  `receiver_name` varchar(30) NOT NULL COMMENT '2至20字',
  `receiver_phone` varchar(20) NOT NULL COMMENT '11位，前台脱敏展示',
  `address_desc` varchar(200) NOT NULL COMMENT '文字描述到门牌，不接地图',
  `audit_remark` varchar(200) DEFAULT NULL COMMENT '驳回时必填，不少于5字',
  `express_no` varchar(64) DEFAULT NULL COMMENT '发放时手工登记，同号不可重复使用',
  `send_time` datetime DEFAULT NULL COMMENT '登记快递单号时写入，作为报告期限起点',
  `status` varchar(20) NOT NULL DEFAULT '待审核' COMMENT '待审核/已驳回/待发放/已发放/待提交报告/已完成',
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_apply_no` (`apply_no`),
  KEY `idx_user_sample` (`user_id`, `sample_id`),
  KEY `idx_status_create` (`status`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='试用申领';

-- 4. trial_report 试用报告
CREATE TABLE `trial_report` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `report_no` varchar(32) NOT NULL COMMENT '规则 BG+yyMMdd+6位序号，全局唯一',
  `apply_id` bigint NOT NULL COMMENT '关联 sample_apply.id，一单一报告',
  `user_id` bigint NOT NULL COMMENT '关联 sys_user.id，须为申领人本人',
  `use_days` int NOT NULL DEFAULT 1 COMMENT '1至30，不得超过发放至今天数',
  `absorb_score` tinyint NOT NULL DEFAULT 5 COMMENT '1至5星，后端校验范围',
  `mild_score` tinyint NOT NULL DEFAULT 5 COMMENT '1至5星，后端校验范围',
  `repurchase_will` varchar(20) NOT NULL DEFAULT '考虑中' COMMENT '一定回购/考虑中/不会回购',
  `content` varchar(1000) NOT NULL COMMENT '不少于30字，敏感词过滤',
  `image_urls` varchar(1000) DEFAULT NULL COMMENT '最多6张相对路径，逗号分隔',
  `allergic_flag` tinyint NOT NULL DEFAULT 0 COMMENT '0无 1有，为1时必须描述症状',
  `status` varchar(20) NOT NULL DEFAULT '待审核' COMMENT '待审核/已通过/已驳回/已隐藏',
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_report_no` (`report_no`),
  UNIQUE KEY `uk_apply_report` (`apply_id`),
  KEY `idx_status_create` (`status`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='试用报告';

-- 5. makeup_order 正装订单
CREATE TABLE `makeup_order` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_no` varchar(32) NOT NULL COMMENT '规则 ZD+yyMMdd+6位序号，全局唯一',
  `user_id` bigint NOT NULL COMMENT '关联 sys_user.id，单商品30天内最多5件',
  `goods_id` bigint NOT NULL COMMENT '关联 cosmetic_goods.id',
  `buy_qty` int NOT NULL DEFAULT 1 COMMENT '1至10，后端复核限购',
  `goods_amount` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT '售价乘件数合计',
  `discount_amount` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT '不超过商品金额',
  `pay_amount` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT '商品金额减优惠，不得为负',
  `source_apply_id` bigint DEFAULT NULL COMMENT '关联 sample_apply.id，用于转化归因',
  `pay_type` varchar(20) NOT NULL COMMENT '微信/支付宝/储值卡，仅登记',
  `pay_status` varchar(20) NOT NULL DEFAULT '未支付' COMMENT '未支付/已支付/已退款',
  `status` varchar(20) NOT NULL DEFAULT '待支付' COMMENT '待支付/待发货/已发货/已完成/已退款/已取消',
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_makeup_order_no` (`order_no`),
  KEY `idx_user_status` (`user_id`, `status`),
  KEY `idx_source_apply` (`source_apply_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='正装订单';

-- 6. skin_profile 肤质档案
CREATE TABLE `skin_profile` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `profile_no` varchar(32) NOT NULL COMMENT '规则 FZ+yyMMdd+5位序号，全局唯一',
  `user_id` bigint NOT NULL COMMENT '关联 sys_user.id，一人一档',
  `skin_type` varchar(20) NOT NULL COMMENT '干性/油性/混合/敏感/中性',
  `sensitive_level` varchar(20) NOT NULL DEFAULT '一般' COMMENT '不敏感/一般/易敏感/高度敏感',
  `demand_tags` varchar(60) NOT NULL COMMENT '保湿/控油/美白/抗皱/祛痘，多选逗号分隔',
  `self_test_score` decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '0至100，按问卷选项加权',
  `allergy_ingredients` varchar(200) DEFAULT NULL COMMENT '如酒精、香精，最多100字',
  `paper_version` varchar(10) NOT NULL DEFAULT 'V1' COMMENT '问卷调整后递增，历史档案不重算',
  `update_date` date NOT NULL COMMENT '重新提交自测时更新',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '1有效 0失效',
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_profile_no` (`profile_no`),
  UNIQUE KEY `uk_user_profile` (`user_id`),
  KEY `idx_skin_type` (`skin_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='肤质档案';

-- 7. convert_track 转化跟踪
CREATE TABLE `convert_track` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `track_no` varchar(32) NOT NULL COMMENT '规则 ZH+yyMMdd+6位序号，全局唯一',
  `apply_id` bigint NOT NULL COMMENT '关联 sample_apply.id，一申领单一条跟踪',
  `user_id` bigint NOT NULL COMMENT '关联 sys_user.id',
  `browse_min` int NOT NULL DEFAULT 0 COMMENT '0至600，按详情页停留累计，单次超30分钟按30计',
  `cart_times` int NOT NULL DEFAULT 0 COMMENT '0至20，取消加购不减计数',
  `convert_score` decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '0至100，每日重算',
  `convert_level` varchar(20) NOT NULL DEFAULT '待评估' COMMENT '高意向/中意向/低意向/待评估',
  `order_id` bigint DEFAULT NULL COMMENT '关联 makeup_order.id，下单后回填',
  `attribution_end` date NOT NULL COMMENT '发放后30天，超窗订单不计入转化',
  `follow_status` varchar(20) NOT NULL DEFAULT '未跟进' COMMENT '未跟进/已触达/已下单/已放弃',
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_track_no` (`track_no`),
  UNIQUE KEY `uk_apply_track` (`apply_id`),
  KEY `idx_level_follow` (`convert_level`, `follow_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='转化跟踪';

-- 8. sample_stock_log 试用装出入库流水
CREATE TABLE `sample_stock_log` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `log_no` varchar(32) NOT NULL COMMENT '规则 SL+yyMMdd+6位序号，全局唯一',
  `sample_id` bigint NOT NULL COMMENT '关联 sample_sku.id',
  `change_type` varchar(20) NOT NULL COMMENT '入库/派发/退回/报损/过期核销',
  `change_qty` int NOT NULL DEFAULT 0 COMMENT '正数增加、负数减少，不得为0',
  `before_qty` int NOT NULL DEFAULT 0 COMMENT '0至100000',
  `after_qty` int NOT NULL DEFAULT 0 COMMENT '必须等于变动前数量加变动数量',
  `biz_no` varchar(32) DEFAULT NULL COMMENT '关联申领编号或入库单号',
  `operator_id` bigint NOT NULL COMMENT '关联 sys_user.id，须为品牌运营或库管',
  `remark` varchar(200) DEFAULT NULL COMMENT '报损与过期核销必填原因，不少于5字',
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sample_log_no` (`log_no`),
  KEY `idx_sample_create` (`sample_id`, `create_time`),
  KEY `idx_biz_no` (`biz_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='试用装出入库流水';


-- ---------------- 系统表与创新点表 ----------------
-- ============================================================
-- NEW-065 美妆护肤商城与试用装派发系统 · 系统表 + 创新点表
-- 8 张业务表见 ddl_business.sql（直接取自需求文档 6.5）
-- ============================================================

-- 9. sys_role 角色表
CREATE TABLE `sys_role` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `role_name` varchar(40) NOT NULL COMMENT '角色名称',
  `role_code` varchar(40) NOT NULL COMMENT '角色编码，与 JWT 权限一致',
  `data_scope` varchar(20) NOT NULL DEFAULT '本人' COMMENT '数据范围：全部/本部门/本人',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '1启用 0停用',
  `remark` varchar(200) DEFAULT NULL COMMENT '说明',
  `create_by` bigint DEFAULT NULL,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_by` bigint DEFAULT NULL,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted` tinyint NOT NULL DEFAULT 0,
  `version` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_role_code` (`role_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色表';

-- 10. sys_user 用户表
CREATE TABLE `sys_user` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` varchar(50) NOT NULL COMMENT '登录账号',
  `password` varchar(100) NOT NULL COMMENT 'BCrypt 密码',
  `real_name` varchar(40) NOT NULL COMMENT '姓名/昵称',
  `phone` varchar(20) NOT NULL COMMENT '手机号，前台脱敏',
  `email` varchar(80) DEFAULT NULL COMMENT '邮箱',
  `avatar` varchar(200) DEFAULT NULL COMMENT '头像相对路径',
  `dept_id` bigint DEFAULT NULL COMMENT '部门ID',
  `dept_name` varchar(40) DEFAULT NULL COMMENT '部门名称',
  `role_id` bigint NOT NULL COMMENT '主角色ID',
  `credit_score` int NOT NULL DEFAULT 100 COMMENT '信用分，爽约扣分',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '1正常 0停用',
  `create_by` bigint DEFAULT NULL,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_by` bigint DEFAULT NULL,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted` tinyint NOT NULL DEFAULT 0,
  `version` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  KEY `idx_role_status` (`role_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 11. sys_user_role 用户角色表
CREATE TABLE `sys_user_role` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `role_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_role` (`user_id`, `role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户角色表';

-- 12. sys_menu 菜单权限表
CREATE TABLE `sys_menu` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `parent_id` bigint NOT NULL DEFAULT 0 COMMENT '上级菜单，0为根',
  `menu_name` varchar(40) NOT NULL,
  `path` varchar(80) DEFAULT NULL COMMENT '路由地址',
  `component` varchar(120) DEFAULT NULL COMMENT '组件路径',
  `perms` varchar(80) DEFAULT NULL COMMENT '权限标识',
  `type` varchar(10) NOT NULL DEFAULT '菜单' COMMENT '目录/菜单/按钮',
  `icon` varchar(40) DEFAULT NULL,
  `sort_no` int NOT NULL DEFAULT 0,
  `visible` tinyint NOT NULL DEFAULT 1 COMMENT '1显示 0隐藏',
  `status` tinyint NOT NULL DEFAULT 1,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted` tinyint NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_parent` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='菜单权限表';

-- 13. sys_role_menu 角色菜单表
CREATE TABLE `sys_role_menu` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `role_id` bigint NOT NULL,
  `menu_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_role_menu` (`role_id`, `menu_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色菜单表';

-- 14. sys_dict_type 字典类型表
CREATE TABLE `sys_dict_type` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `dict_name` varchar(40) NOT NULL,
  `dict_type` varchar(40) NOT NULL,
  `status` tinyint NOT NULL DEFAULT 1,
  `remark` varchar(200) DEFAULT NULL,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted` tinyint NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_dict_type` (`dict_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='字典类型表';

-- 15. sys_dict_data 字典数据表
CREATE TABLE `sys_dict_data` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `dict_type` varchar(40) NOT NULL,
  `dict_label` varchar(40) NOT NULL,
  `dict_value` varchar(40) NOT NULL,
  `tag_style` varchar(20) DEFAULT NULL COMMENT '标签样式 success/warning/danger/primary/info',
  `sort_no` int NOT NULL DEFAULT 0,
  `status` tinyint NOT NULL DEFAULT 1,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted` tinyint NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_dict_type` (`dict_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='字典数据表';

-- 16. sys_file 文件表
CREATE TABLE `sys_file` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `file_name` varchar(120) NOT NULL COMMENT '原始文件名',
  `file_path` varchar(200) NOT NULL COMMENT '相对路径 /uploads/xx',
  `file_size` bigint NOT NULL DEFAULT 0,
  `file_type` varchar(40) DEFAULT NULL,
  `biz_type` varchar(40) DEFAULT NULL COMMENT '业务类型：goods/report/avatar',
  `biz_id` bigint DEFAULT NULL,
  `uploader_id` bigint DEFAULT NULL,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted` tinyint NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_biz` (`biz_type`, `biz_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文件表';

-- 17. sys_notice 公告表
CREATE TABLE `sys_notice` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `title` varchar(120) NOT NULL,
  `content` text NOT NULL,
  `publish_time` datetime NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT '已发布' COMMENT '草稿/已发布/已下线',
  `create_by` bigint DEFAULT NULL,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted` tinyint NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='公告表';

-- 18. sys_message 站内消息表
CREATE TABLE `sys_message` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `receiver_id` bigint NOT NULL COMMENT '接收人',
  `title` varchar(120) NOT NULL,
  `content` varchar(500) NOT NULL,
  `msg_type` varchar(20) NOT NULL DEFAULT '系统通知' COMMENT '待办/审核/超时/系统通知',
  `biz_type` varchar(40) DEFAULT NULL,
  `biz_id` bigint DEFAULT NULL,
  `read_flag` tinyint NOT NULL DEFAULT 0 COMMENT '0未读 1已读',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted` tinyint NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_receiver` (`receiver_id`, `read_flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='站内消息表';

-- 19. sys_oper_log 操作日志表
CREATE TABLE `sys_oper_log` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `module` varchar(40) NOT NULL COMMENT '业务模块',
  `oper_type` varchar(20) NOT NULL COMMENT '操作类型',
  `biz_no` varchar(32) DEFAULT NULL COMMENT '业务单号',
  `content` varchar(500) DEFAULT NULL,
  `oper_id` bigint DEFAULT NULL,
  `oper_name` varchar(40) DEFAULT NULL,
  `oper_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ip` varchar(40) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_oper_time` (`oper_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='操作日志表';

-- ============================================================
-- 创新点：转化概率规则版本 / 计算留痕 / 人工修正
-- ============================================================

-- 20. convert_rule 转化概率规则
CREATE TABLE `convert_rule` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `rule_no` varchar(32) NOT NULL COMMENT '规则编号 GZ+yyMMdd+4位',
  `rule_name` varchar(60) NOT NULL COMMENT '规则名称',
  `rule_version` varchar(10) NOT NULL COMMENT '版本号 V1/V2...',
  `w_skin` decimal(5,2) NOT NULL DEFAULT 30.00 COMMENT '肤质适配度权重',
  `w_history` decimal(5,2) NOT NULL DEFAULT 25.00 COMMENT '历史报告率权重',
  `w_report` decimal(5,2) NOT NULL DEFAULT 20.00 COMMENT '报告完整度权重',
  `w_browse` decimal(5,2) NOT NULL DEFAULT 15.00 COMMENT '浏览加购权重',
  `w_order` decimal(5,2) NOT NULL DEFAULT 10.00 COMMENT '客单匹配权重',
  `high_threshold` decimal(5,2) NOT NULL DEFAULT 75.00 COMMENT '高意向阈值',
  `mid_threshold` decimal(5,2) NOT NULL DEFAULT 50.00 COMMENT '中意向阈值',
  `status` varchar(20) NOT NULL DEFAULT '草稿' COMMENT '草稿/生效/历史',
  `effect_time` datetime DEFAULT NULL COMMENT '生效时间',
  `remark` varchar(200) DEFAULT NULL,
  `create_by` bigint DEFAULT NULL,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_by` bigint DEFAULT NULL,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted` tinyint NOT NULL DEFAULT 0,
  `version` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_rule_no` (`rule_no`),
  UNIQUE KEY `uk_rule_version` (`rule_version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='转化概率规则';

-- 21. convert_snapshot 转化计算留痕
CREATE TABLE `convert_snapshot` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `snap_no` varchar(32) NOT NULL COMMENT '快照编号',
  `track_id` bigint NOT NULL COMMENT '关联 convert_track.id',
  `apply_id` bigint DEFAULT NULL,
  `user_id` bigint NOT NULL,
  `goods_id` bigint DEFAULT NULL,
  `rule_id` bigint NOT NULL COMMENT '关联 convert_rule.id',
  `rule_version` varchar(10) NOT NULL COMMENT '计算时规则版本',
  `skin_match` varchar(20) DEFAULT NULL COMMENT '肤质匹配：完全/部分/不匹配/无档案',
  `skin_score` decimal(5,2) NOT NULL DEFAULT 0.00,
  `history_rate` decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '近180天报告率',
  `history_score` decimal(5,2) NOT NULL DEFAULT 0.00,
  `report_complete` decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '报告完整度得分',
  `report_score` decimal(5,2) NOT NULL DEFAULT 0.00,
  `browse_min` int NOT NULL DEFAULT 0,
  `cart_times` int NOT NULL DEFAULT 0,
  `browse_score` decimal(5,2) NOT NULL DEFAULT 0.00,
  `avg_amount` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT '用户历史客单价',
  `order_score` decimal(5,2) NOT NULL DEFAULT 0.00,
  `total_score` decimal(5,2) NOT NULL DEFAULT 0.00,
  `convert_level` varchar(20) NOT NULL DEFAULT '待评估',
  `conclusion` varchar(500) DEFAULT NULL COMMENT '推荐结论',
  `unmet` varchar(500) DEFAULT NULL COMMENT '未满足条件 / 可改进项',
  `correction_flag` tinyint NOT NULL DEFAULT 0 COMMENT '1 已被人工修正',
  `calc_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted` tinyint NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_snap_no` (`snap_no`),
  KEY `idx_track_time` (`track_id`, `calc_time`),
  KEY `idx_rule` (`rule_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='转化计算留痕';

-- 22. convert_correction 转化结果人工修正
CREATE TABLE `convert_correction` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `snap_id` bigint NOT NULL COMMENT '关联 convert_snapshot.id，原快照不被覆盖',
  `track_id` bigint NOT NULL,
  `before_score` decimal(5,2) NOT NULL DEFAULT 0.00,
  `before_level` varchar(20) NOT NULL,
  `after_level` varchar(20) NOT NULL,
  `reason` varchar(200) NOT NULL COMMENT '不少于5字',
  `oper_id` bigint DEFAULT NULL,
  `oper_name` varchar(40) DEFAULT NULL,
  `oper_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted` tinyint NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_track` (`track_id`),
  KEY `idx_snap` (`snap_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='转化结果人工修正';


-- ============================================================
-- 初始化数据
-- ============================================================
SET NAMES utf8mb4;

-- 角色
INSERT INTO sys_role (id, role_name, role_code, data_scope, status, remark) VALUES (1, '系统管理员', 'admin', '全部', 1, '管理用户、角色、菜单、字典、参数与操作日志');
INSERT INTO sys_role (id, role_name, role_code, data_scope, status, remark) VALUES (2, '品牌运营', 'operator', '全部', 1, '维护商品与肤质标签、配置试用活动、审核申领、登记发放');
INSERT INTO sys_role (id, role_name, role_code, data_scope, status, remark) VALUES (3, '内容审核员', 'auditor', '本部门', 1, '审核试用报告与晒图内容、处理违规与广告内容');
INSERT INTO sys_role (id, role_name, role_code, data_scope, status, remark) VALUES (4, '客服专员', 'service', '本人', 1, '跟进高意向用户、解答试用咨询、受理正装售后');
INSERT INTO sys_role (id, role_name, role_code, data_scope, status, remark) VALUES (5, '数据分析员', 'analyst', '全部', 1, '查看转化漏斗、维护转化概率规则与归因窗口');
INSERT INTO sys_role (id, role_name, role_code, data_scope, status, remark) VALUES (6, '试用用户', 'user', '本人', 1, '完善肤质档案、申领试用装、提交试用报告、下单正装');

-- 账号（admin/123456、其余 123456，BCrypt 存储）
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (1, 'admin', '$2a$10$v.uwr.w94qqCgVcOmcb1/OdcN2XJ870cTMkpD.r1v8jlFysMgfAJC', '系统管理员', '13800000001', 'admin@luma-beauty.com', '/uploads/seed/avatar/02.jpg', 1, '信息技术部', 1, 100, 1, '2026-05-02 09:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (2, 'operator', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '林佳', '13862014488', 'operator@luma-beauty.com', '/uploads/seed/avatar/03.jpg', 2, '市场部', 2, 100, 1, '2026-05-03 09:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (3, 'operator02', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '何知微', '13862014599', 'operator02@luma-beauty.com', '/uploads/seed/avatar/04.jpg', 2, '市场部', 2, 100, 1, '2026-05-04 09:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (4, 'auditor01', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '沈砚', '13862016611', 'auditor01@luma-beauty.com', '/uploads/seed/avatar/05.jpg', 3, '内容部', 3, 100, 1, '2026-05-05 09:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (5, 'auditor02', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '陆时', '13862016622', 'auditor02@luma-beauty.com', '/uploads/seed/avatar/06.jpg', 3, '内容部', 3, 100, 1, '2026-05-06 09:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (6, 'service01', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '陈亦然', '13862017733', 'service01@luma-beauty.com', '/uploads/seed/avatar/07.jpg', 4, '客服部', 4, 100, 1, '2026-05-07 09:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (7, 'service02', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '周语桐', '13862017744', 'service02@luma-beauty.com', '/uploads/seed/avatar/08.jpg', 4, '客服部', 4, 100, 1, '2026-05-08 09:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (8, 'analyst01', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '许清和', '13862018855', 'analyst01@luma-beauty.com', '/uploads/seed/avatar/01.jpg', 5, '数据部', 5, 100, 1, '2026-05-09 09:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (9, 'analyst02', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '叶南乔', '13862018866', 'analyst02@luma-beauty.com', '/uploads/seed/avatar/02.jpg', 5, '数据部', 5, 100, 1, '2026-05-10 09:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (10, 'user', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '苏念', '13910000000', 'user@example.com', '/uploads/seed/avatar/01.jpg', NULL, NULL, 6, 100, 1, '2026-05-02 19:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (11, 'user01', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '陈亦然', '13910000137', 'user01@example.com', '/uploads/seed/avatar/02.jpg', NULL, NULL, 6, 96, 1, '2026-05-07 11:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (12, 'user02', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '周语桐', '13910000274', 'user02@example.com', '/uploads/seed/avatar/03.jpg', NULL, NULL, 6, 92, 1, '2026-05-12 14:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (13, 'user03', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '林见夏', '13910000411', 'user03@example.com', '/uploads/seed/avatar/04.jpg', NULL, NULL, 6, 100, 1, '2026-05-17 19:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (14, 'user04', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '许清和', '13910000548', 'user04@example.com', '/uploads/seed/avatar/05.jpg', NULL, NULL, 6, 96, 1, '2026-05-22 18:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (15, 'user05', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '何知微', '13910000685', 'user05@example.com', '/uploads/seed/avatar/06.jpg', NULL, NULL, 6, 92, 1, '2026-05-27 18:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (16, 'user06', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '沈栖迟', '13910000822', 'user06@example.com', '/uploads/seed/avatar/07.jpg', NULL, NULL, 6, 100, 1, '2026-06-01 16:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (17, 'user07', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '叶南乔', '13910000959', 'user07@example.com', '/uploads/seed/avatar/08.jpg', NULL, NULL, 6, 96, 1, '2026-06-06 11:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (18, 'user08', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '秦笺', '13910001096', 'user08@example.com', '/uploads/seed/avatar/01.jpg', NULL, NULL, 6, 92, 1, '2026-06-11 14:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (19, 'user09', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '顾青禾', '13910001233', 'user09@example.com', '/uploads/seed/avatar/02.jpg', NULL, NULL, 6, 100, 1, '2026-06-16 19:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (20, 'user10', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '温言', '13910001370', 'user10@example.com', '/uploads/seed/avatar/03.jpg', NULL, NULL, 6, 96, 1, '2026-06-21 12:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (21, 'user11', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '裴宁', '13910001507', 'user11@example.com', '/uploads/seed/avatar/04.jpg', NULL, NULL, 6, 92, 1, '2026-06-26 14:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (22, 'user12', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '南乔', '13910001644', 'user12@example.com', '/uploads/seed/avatar/05.jpg', NULL, NULL, 6, 100, 1, '2026-07-01 15:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (23, 'user13', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '程锦', '13910001781', 'user13@example.com', '/uploads/seed/avatar/06.jpg', NULL, NULL, 6, 96, 1, '2026-07-06 11:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (24, 'user14', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '姜屿', '13910001918', 'user14@example.com', '/uploads/seed/avatar/07.jpg', NULL, NULL, 6, 92, 1, '2026-07-11 17:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (25, 'user15', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '方知有', '13910002055', 'user15@example.com', '/uploads/seed/avatar/08.jpg', NULL, NULL, 6, 100, 1, '2026-07-16 10:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (26, 'user16', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '闻莺', '13910002192', 'user16@example.com', '/uploads/seed/avatar/01.jpg', NULL, NULL, 6, 96, 1, '2026-07-21 17:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (27, 'user17', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '李知遥', '13910002329', 'user17@example.com', '/uploads/seed/avatar/02.jpg', NULL, NULL, 6, 92, 1, '2026-07-26 12:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (28, 'user18', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '宋祁', '13910002466', 'user18@example.com', '/uploads/seed/avatar/03.jpg', NULL, NULL, 6, 100, 1, '2026-07-31 15:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (29, 'user19', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '白露', '13910002603', 'user19@example.com', '/uploads/seed/avatar/04.jpg', NULL, NULL, 6, 96, 1, '2026-08-05 15:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (30, 'user20', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '江晚', '13910002740', 'user20@example.com', '/uploads/seed/avatar/05.jpg', NULL, NULL, 6, 92, 1, '2026-08-10 18:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (31, 'user21', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '沐晴', '13910002877', 'user21@example.com', '/uploads/seed/avatar/06.jpg', NULL, NULL, 6, 100, 1, '2026-08-15 16:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (32, 'user22', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '施南', '13910003014', 'user22@example.com', '/uploads/seed/avatar/07.jpg', NULL, NULL, 6, 96, 1, '2026-08-20 12:00:00');
INSERT INTO sys_user (id, username, password, real_name, phone, email, avatar, dept_id, dept_name, role_id, credit_score, status, create_time) VALUES (33, 'user23', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '余温', '13910003151', 'user23@example.com', '/uploads/seed/avatar/08.jpg', NULL, NULL, 6, 92, 1, '2026-08-25 16:00:00');

-- 用户角色
INSERT INTO sys_user_role (user_id, role_id) VALUES (1, 1);
INSERT INTO sys_user_role (user_id, role_id) VALUES (2, 2);
INSERT INTO sys_user_role (user_id, role_id) VALUES (3, 2);
INSERT INTO sys_user_role (user_id, role_id) VALUES (4, 3);
INSERT INTO sys_user_role (user_id, role_id) VALUES (5, 3);
INSERT INTO sys_user_role (user_id, role_id) VALUES (6, 4);
INSERT INTO sys_user_role (user_id, role_id) VALUES (7, 4);
INSERT INTO sys_user_role (user_id, role_id) VALUES (8, 5);
INSERT INTO sys_user_role (user_id, role_id) VALUES (9, 5);
INSERT INTO sys_user_role (user_id, role_id) VALUES (10, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (11, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (12, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (13, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (14, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (15, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (16, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (17, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (18, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (19, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (20, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (21, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (22, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (23, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (24, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (25, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (26, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (27, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (28, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (29, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (30, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (31, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (32, 6);
INSERT INTO sys_user_role (user_id, role_id) VALUES (33, 6);

-- 菜单（目录/菜单/按钮三级；菜单管理与分配菜单不在树中展示）
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (1, 0, '经营看板', '/dashboard', 'Layout', NULL, '目录', 'dashboard', 1, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (11, 1, '数据看板', 'dashboard', 'dashboard/index', 'dashboard:view', '菜单', 'chart', 1, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (12, 1, '转化看板', 'convert-board', 'convert/board', 'convert:board', '菜单', 'target', 2, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (13, 1, '试用效果报表', 'stat-report', 'stat/report', 'stat:report', '菜单', 'report', 3, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (2, 0, '商品与试用装', '/goods', 'Layout', NULL, '目录', 'shop', 2, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (21, 2, '商品管理', 'goods-list', 'goods/list', 'goods:list', '菜单', 'shop', 1, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (2101, 21, '新增商品', NULL, NULL, 'goods:add', '按钮', NULL, 1, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (2102, 21, '编辑商品', NULL, NULL, 'goods:edit', '按钮', NULL, 2, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (2103, 21, '删除商品', NULL, NULL, 'goods:delete', '按钮', NULL, 3, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (22, 2, '肤质标签配置', 'skin-tag', 'goods/skinTag', 'goods:skin', '菜单', 'skin', 2, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (23, 2, '试用装管理', 'sample-list', 'sample/list', 'sample:list', '菜单', 'box', 3, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (2301, 23, '新增试用装', NULL, NULL, 'sample:add', '按钮', NULL, 1, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (24, 2, '出入库登记', 'sample-stock', 'sample/stock', 'sample:stock', '菜单', 'truck', 4, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (2401, 24, '登记出入库', NULL, NULL, 'sample:stock:add', '按钮', NULL, 1, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (3, 0, '申领与发放', '/trial', 'Layout', NULL, '目录', 'order', 3, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (31, 3, '申领列表', 'apply-list', 'apply/list', 'apply:list', '菜单', 'order', 1, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (32, 3, '申领审核台', 'apply-audit', 'apply/audit', 'apply:audit', '菜单', 'gavel', 2, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (3201, 32, '审核通过', NULL, NULL, 'apply:audit:pass', '按钮', NULL, 1, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (3202, 32, '审核驳回', NULL, NULL, 'apply:audit:reject', '按钮', NULL, 2, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (33, 3, '发放登记', 'apply-send', 'apply/send', 'apply:send', '菜单', 'gift', 3, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (3301, 33, '登记快递', NULL, NULL, 'apply:send:submit', '按钮', NULL, 1, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (4, 0, '报告与订单', '/biz', 'Layout', NULL, '目录', 'report', 4, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (41, 4, '报告审核', 'report-list', 'report/list', 'report:audit', '菜单', 'report', 1, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (4101, 41, '通过报告', NULL, NULL, 'report:pass', '按钮', NULL, 1, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (4102, 41, '驳回报告', NULL, NULL, 'report:reject', '按钮', NULL, 2, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (42, 4, '正装订单', 'order-list', 'order/list', 'order:list', '菜单', 'cart', 2, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (4201, 42, '登记退款', NULL, NULL, 'order:refund', '按钮', NULL, 1, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (5, 0, '转化与规则', '/convert', 'Layout', NULL, '目录', 'level', 5, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (51, 5, '用户跟进', 'convert-follow', 'convert/follow', 'convert:follow', '菜单', 'level', 1, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (5101, 51, '登记跟进', NULL, NULL, 'convert:follow:add', '按钮', NULL, 1, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (52, 5, '转化规则配置', 'convert-rule', 'convert/rule', 'convert:rule', '菜单', 'rule', 2, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (5201, 52, '保存规则', NULL, NULL, 'convert:rule:save', '按钮', NULL, 1, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (53, 5, '转化计算留痕', 'convert-calc', 'convert/calc', 'convert:calc', '菜单', 'calc', 3, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (5301, 53, '人工修正', NULL, NULL, 'convert:calc:fix', '按钮', NULL, 1, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (6, 0, '系统管理', '/system', 'Layout', NULL, '目录', 'menu', 6, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (61, 6, '用户管理', 'user', 'system/user', 'system:user', '菜单', 'user', 1, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (62, 6, '角色管理', 'role', 'system/role', 'system:role', '菜单', 'role', 2, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (63, 6, '字典管理', 'dict', 'system/dict', 'system:dict', '菜单', 'dict', 3, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (64, 6, '操作日志', 'log', 'system/log', 'system:log', '菜单', 'log', 4, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (7, 0, '个人', '/me', 'Layout', NULL, '目录', 'message', 7, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (71, 7, '站内消息', 'message', 'me/message', 'me:message', '菜单', 'message', 1, 1, 1);
INSERT INTO sys_menu (id, parent_id, menu_name, path, component, perms, type, icon, sort_no, visible, status) VALUES (72, 7, '个人中心', 'profile', 'me/profile', 'me:profile', '菜单', 'user', 2, 1, 1);

-- 角色菜单
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (1, 1),(1, 11),(1, 12),(1, 13),(1, 2),(1, 21),(1, 2101),(1, 2102),(1, 2103),(1, 22),(1, 23),(1, 2301),(1, 24),(1, 2401),(1, 3),(1, 31),(1, 32),(1, 3201),(1, 3202),(1, 33),(1, 3301),(1, 4),(1, 41),(1, 4101),(1, 4102),(1, 42),(1, 4201),(1, 5),(1, 51),(1, 5101);
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (1, 52),(1, 5201),(1, 53),(1, 5301),(1, 6),(1, 61),(1, 62),(1, 63),(1, 64),(1, 7),(1, 71),(1, 72),(2, 1),(2, 11),(2, 12),(2, 13),(2, 2),(2, 21),(2, 2101),(2, 2102),(2, 22),(2, 23),(2, 2301),(2, 24),(2, 2401),(2, 3),(2, 31),(2, 32),(2, 3201),(2, 3202);
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (2, 33),(2, 3301),(2, 4),(2, 42),(2, 5),(2, 51),(2, 52),(2, 53),(2, 7),(2, 71),(2, 72),(3, 1),(3, 11),(3, 4),(3, 41),(3, 4101),(3, 4102),(3, 7),(3, 71),(3, 72),(4, 1),(4, 11),(4, 12),(4, 5),(4, 51),(4, 5101),(4, 53),(4, 5301),(4, 4),(4, 42);
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (4, 7),(4, 71),(4, 72),(5, 1),(5, 11),(5, 12),(5, 13),(5, 5),(5, 51),(5, 52),(5, 5201),(5, 53),(5, 7),(5, 71),(5, 72),(6, 7),(6, 71),(6, 72);

-- 字典
INSERT INTO sys_dict_type (id, dict_name, dict_type, status) VALUES (1, '申领状态', 'apply_status', 1);
INSERT INTO sys_dict_type (id, dict_name, dict_type, status) VALUES (2, '商品状态', 'goods_status', 1);
INSERT INTO sys_dict_type (id, dict_name, dict_type, status) VALUES (3, '试用装状态', 'sample_status', 1);
INSERT INTO sys_dict_type (id, dict_name, dict_type, status) VALUES (4, '订单状态', 'order_status', 1);
INSERT INTO sys_dict_type (id, dict_name, dict_type, status) VALUES (5, '报告状态', 'report_status', 1);
INSERT INTO sys_dict_type (id, dict_name, dict_type, status) VALUES (6, '转化等级', 'convert_level', 1);
INSERT INTO sys_dict_type (id, dict_name, dict_type, status) VALUES (7, '肤质类型', 'skin_type', 1);
INSERT INTO sys_dict_type (id, dict_name, dict_type, status) VALUES (8, '功效标签', 'effect_tag', 1);
INSERT INTO sys_dict_type (id, dict_name, dict_type, status) VALUES (9, '商品品类', 'goods_type', 1);
INSERT INTO sys_dict_type (id, dict_name, dict_type, status) VALUES (10, '支付方式', 'pay_type', 1);
INSERT INTO sys_dict_type (id, dict_name, dict_type, status) VALUES (11, '跟进状态', 'follow_status', 1);
INSERT INTO sys_dict_type (id, dict_name, dict_type, status) VALUES (12, '库存变动类型', 'change_type', 1);
INSERT INTO sys_dict_type (id, dict_name, dict_type, status) VALUES (13, '回购意愿', 'repurchase_will', 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (1, 'apply_status', '待审核', 'PENDING', 'warning', 1, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (2, 'apply_status', '已驳回', 'REJECTED', 'danger', 2, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (3, 'apply_status', '待发放', 'TO_SEND', 'primary', 3, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (4, 'apply_status', '已发放', 'SENT', 'primary', 4, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (5, 'apply_status', '待提交报告', 'TO_REPORT', 'warning', 5, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (6, 'apply_status', '已完成', 'FINISHED', 'success', 6, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (7, 'goods_status', '待上架', 'DRAFT', 'info', 1, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (8, 'goods_status', '在售', 'ON_SALE', 'success', 2, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (9, 'goods_status', '已售罄', 'SOLD_OUT', 'danger', 3, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (10, 'goods_status', '已下架', 'OFF', 'info', 4, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (11, 'sample_status', '待上架', 'DRAFT', 'info', 1, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (12, 'sample_status', '可派发', 'AVAILABLE', 'success', 2, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (13, 'sample_status', '已派完', 'EMPTY', 'danger', 3, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (14, 'sample_status', '已过期', 'EXPIRED', 'info', 4, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (15, 'sample_status', '已下架', 'OFF', 'info', 5, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (16, 'order_status', '待支付', 'UNPAID', 'warning', 1, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (17, 'order_status', '待发货', 'TO_SHIP', 'primary', 2, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (18, 'order_status', '已发货', 'SHIPPED', 'primary', 3, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (19, 'order_status', '已完成', 'FINISHED', 'success', 4, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (20, 'order_status', '已退款', 'REFUNDED', 'danger', 5, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (21, 'order_status', '已取消', 'CANCELED', 'info', 6, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (22, 'report_status', '待审核', 'PENDING', 'warning', 1, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (23, 'report_status', '已通过', 'PASSED', 'success', 2, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (24, 'report_status', '已驳回', 'REJECTED', 'danger', 3, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (25, 'report_status', '已隐藏', 'HIDDEN', 'info', 4, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (26, 'convert_level', '高意向', 'HIGH', 'success', 1, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (27, 'convert_level', '中意向', 'MID', 'warning', 2, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (28, 'convert_level', '低意向', 'LOW', 'info', 3, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (29, 'convert_level', '待评估', 'PENDING', 'info', 4, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (30, 'skin_type', '干性', 'DRY', 'info', 1, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (31, 'skin_type', '油性', 'OILY', 'info', 2, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (32, 'skin_type', '混合', 'MIXED', 'primary', 3, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (33, 'skin_type', '敏感', 'SENSITIVE', 'warning', 4, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (34, 'skin_type', '中性', 'NORMAL', 'success', 5, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (35, 'effect_tag', '保湿', 'MOIST', 'primary', 1, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (36, 'effect_tag', '美白', 'WHITEN', 'primary', 2, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (37, 'effect_tag', '抗皱', 'ANTI_AGE', 'primary', 3, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (38, 'effect_tag', '控油', 'OIL_CTRL', 'primary', 4, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (39, 'effect_tag', '舒缓', 'SOOTHE', 'primary', 5, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (40, 'goods_type', '精华', 'SERUM', 'info', 1, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (41, 'goods_type', '面霜', 'CREAM', 'info', 2, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (42, 'goods_type', '洁面', 'CLEANSER', 'info', 3, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (43, 'goods_type', '防晒', 'SUNSCREEN', 'info', 4, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (44, 'goods_type', '彩妆', 'MAKEUP', 'info', 5, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (45, 'goods_type', '面膜', 'MASK', 'info', 6, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (46, 'pay_type', '微信', 'WX', 'success', 1, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (47, 'pay_type', '支付宝', 'ALI', 'primary', 2, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (48, 'pay_type', '储值卡', 'CARD', 'info', 3, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (49, 'follow_status', '未跟进', 'NONE', 'info', 1, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (50, 'follow_status', '已触达', 'TOUCHED', 'primary', 2, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (51, 'follow_status', '已下单', 'ORDERED', 'success', 3, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (52, 'follow_status', '已放弃', 'GIVE_UP', 'danger', 4, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (53, 'change_type', '入库', 'IN', 'success', 1, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (54, 'change_type', '派发', 'SEND', 'primary', 2, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (55, 'change_type', '退回', 'BACK', 'info', 3, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (56, 'change_type', '报损', 'LOSS', 'danger', 4, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (57, 'change_type', '过期核销', 'EXPIRE', 'warning', 5, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (58, 'repurchase_will', '一定回购', 'YES', 'success', 1, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (59, 'repurchase_will', '考虑中', 'MAYBE', 'warning', 2, 1);
INSERT INTO sys_dict_data (id, dict_type, dict_label, dict_value, tag_style, sort_no, status) VALUES (60, 'repurchase_will', '不会回购', 'NO', 'danger', 3, 1);

-- 美妆商品（26 条，覆盖 4 种状态、6 个品类）
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (1, 'MZ2605010001', '兰蔻小黑瓶精华肌底液', '兰蔻', '精华', '干性,混合,中性', '保湿,舒缓', 30, 780.00, 128, 1, '在售', '/uploads/seed/goods/01.jpg', '2026-05-01 11:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (2, 'MZ2605070002', '雅诗兰黛小棕瓶修护精华', '雅诗兰黛', '精华', '干性,混合', '抗皱,保湿', 50, 920.00, 86, 1, '在售', '/uploads/seed/goods/11.jpg', '2026-05-07 16:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (3, 'MZ2605130003', '珀莱雅双抗精华 3.0', '珀莱雅', '精华', '油性,混合', '抗皱,控油', 30, 289.00, 240, 1, '在售', '/uploads/seed/goods/04.jpg', '2026-05-13 12:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (4, 'MZ2605190004', '修丽可 CE 复合修护精华', '修丽可', '精华', '干性,中性', '美白,抗皱', 30, 1180.00, 42, 1, '在售', '/uploads/seed/goods/10.jpg', '2026-05-19 11:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (5, 'MZ2605250005', '薇诺娜舒敏保湿特护霜', '薇诺娜', '面霜', '敏感,干性', '舒缓,保湿', 50, 268.00, 176, 1, '在售', '/uploads/seed/goods/02.jpg', '2026-05-25 16:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (6, 'MZ2605310006', '玉泽皮肤屏障修护面霜', '玉泽', '面霜', '敏感,干性,中性', '舒缓,保湿', 80, 198.00, 0, 1, '已售罄', '/uploads/seed/goods/12.jpg', '2026-05-31 10:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (7, 'MZ2606060007', '至本特安修护氨基酸洁面', '至本', '洁面', '敏感,油性,混合', '舒缓,控油', 120, 89.00, 320, 1, '在售', '/uploads/seed/goods/03.jpg', '2026-06-06 13:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (8, 'MZ2606120008', '兰蔻轻透防晒乳 SPF50', '兰蔻', '防晒', '干性,中性,混合', '保湿', 30, 460.00, 96, 1, '在售', '/uploads/seed/goods/05.jpg', '2026-06-12 16:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (9, 'MZ2606180009', '雅诗兰黛 DW 持妆粉底液', '雅诗兰黛', '彩妆', '油性,混合', '控油', 30, 460.00, 58, 1, '在售', '/uploads/seed/goods/09.jpg', '2026-06-18 18:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (10, 'MZ2606240010', '珀莱雅红宝石淡纹面膜', '珀莱雅', '面膜', '干性,混合,中性', '抗皱,保湿', 25, 159.00, 0, 1, '已售罄', '/uploads/seed/goods/06.jpg', '2026-06-24 17:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (11, 'MZ2606300011', '修丽可 B5 保湿精华', '修丽可', '精华', '干性,敏感,中性', '保湿,舒缓', 30, 690.00, 64, 1, '在售', '/uploads/seed/goods/08.jpg', '2026-06-30 13:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (12, 'MZ2607060012', '薇诺娜舒敏保湿修护精华', '薇诺娜', '精华', '敏感,干性', '舒缓,保湿', 30, 298.00, 132, 1, '在售', '/uploads/seed/goods/07.jpg', '2026-07-06 12:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (13, 'MZ2607120013', '玉泽屏障修护洁面乳', '玉泽', '洁面', '敏感,干性', '舒缓', 100, 128.00, 210, 1, '在售', '/uploads/seed/goods/05.jpg', '2026-07-12 18:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (14, 'MZ2607180014', '至本倍润修护面霜', '至本', '面霜', '干性,中性', '保湿,抗皱', 50, 168.00, 88, 1, '在售', '/uploads/seed/goods/02.jpg', '2026-07-18 16:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (15, 'MZ2607240015', '兰蔻极光淡斑精华', '兰蔻', '精华', '混合,中性', '美白,保湿', 30, 1080.00, 30, 1, '在售', '/uploads/seed/goods/01.jpg', '2026-07-24 17:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (16, 'MZ2607300016', '雅诗兰黛智妍紧塑面霜', '雅诗兰黛', '面霜', '干性,混合', '抗皱', 50, 1180.00, 46, 1, '在售', '/uploads/seed/goods/12.jpg', '2026-07-30 15:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (17, 'MZ2608050017', '珀莱雅净润氨基酸洁面', '珀莱雅', '洁面', '油性,混合', '控油', 120, 79.00, 190, 1, '在售', '/uploads/seed/goods/03.jpg', '2026-08-05 13:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (18, 'MZ2608110018', '修丽可日光防护乳 SPF50', '修丽可', '防晒', '干性,中性', '保湿', 40, 420.00, 72, 1, '在售', '/uploads/seed/goods/03.jpg', '2026-08-11 18:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (19, 'MZ2608170019', '薇诺娜舒敏保湿面膜', '薇诺娜', '面膜', '敏感,干性', '舒缓,保湿', 25, 199.00, 150, 1, '在售', '/uploads/seed/goods/06.jpg', '2026-08-17 18:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (20, 'MZ2608230020', '玉泽屏障修护面膜', '玉泽', '面膜', '敏感,中性', '舒缓,保湿', 25, 129.00, 0, 1, '已售罄', '/uploads/seed/goods/06.jpg', '2026-08-23 10:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (21, 'MZ2608290021', '至本清透防晒乳 SPF50', '至本', '防晒', '油性,混合', '控油', 50, 108.00, 240, 0, '已售罄', '/uploads/seed/goods/05.jpg', '2026-08-29 11:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (22, 'MZ2609040022', '兰蔻菁纯柔雾唇膏', '兰蔻', '彩妆', '干性,中性', '保湿', 3, 320.00, 66, 0, '已售罄', '/uploads/seed/goods/09.jpg', '2026-09-04 11:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (23, 'MZ2609100023', '雅诗兰黛线雕精华', '雅诗兰黛', '精华', '干性,混合', '抗皱', 30, 980.00, 38, 0, '已售罄', '/uploads/seed/goods/11.jpg', '2026-09-10 11:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (24, 'MZ2609160024', '珀莱雅红宝石面霜', '珀莱雅', '面霜', '干性,混合', '抗皱,保湿', 50, 329.00, 120, 0, '待上架', '/uploads/seed/goods/02.jpg', '2026-09-16 18:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (25, 'MZ2609220025', '修丽可温和洁面凝胶', '修丽可', '洁面', '油性,混合', '控油,舒缓', 200, 260.00, 84, 0, '待上架', '/uploads/seed/goods/05.jpg', '2026-09-22 18:00:00', 2);
INSERT INTO cosmetic_goods (id, goods_no, goods_name, brand, goods_type, skin_type, effect_tags, spec_ml, sale_price, stock_qty, is_trial, status, cover_image, create_time, create_by) VALUES (26, 'MZ2609280026', '薇诺娜清透防晒乳', '薇诺娜', '防晒', '敏感,中性', '舒缓', 50, 218.00, 96, 0, '已下架', '/uploads/seed/goods/03.jpg', '2026-09-28 10:00:00', 2);

-- 试用装（26 个批次，含已过期/已派完/待上架）
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (1, 'SY2605030001', 1, 10, 9.36, 500, 1, 499, 'B000260503', '2027-03-18', '可派发', '2026-05-03 11:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (2, 'SY2605090002', 2, 15, 11.04, 400, 0, 400, 'B001260509', '2027-03-22', '可派发', '2026-05-09 16:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (3, 'SY2605150003', 3, 10, 3.47, 800, 3, 797, 'B002260515', '2027-03-26', '可派发', '2026-05-15 12:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (4, 'SY2605210004', 4, 10, 14.16, 300, -2, 302, 'B003260521', '2027-03-30', '可派发', '2026-05-21 11:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (5, 'SY2605270005', 5, 15, 3.22, 600, 5, 595, 'B004260527', '2027-04-03', '可派发', '2026-05-27 16:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (6, 'SY2606020006', 6, 15, 2.38, 500, 122, 378, 'B005260602', '2026-10-20', '已过期', '2026-06-02 10:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (7, 'SY2606080007', 7, 15, 1.07, 700, 3, 697, 'B006260608', '2027-04-11', '可派发', '2026-06-08 13:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (8, 'SY2606140008', 8, 10, 5.52, 380, 1, 379, 'B007260614', '2027-04-15', '可派发', '2026-06-14 16:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (9, 'SY2606200009', 9, 10, 5.52, 260, 0, 260, 'B008260620', '2027-04-19', '待上架', '2026-06-20 18:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (10, 'SY2606260010', 10, 8, 1.91, 420, 5, 415, 'B009260626', '2027-04-23', '可派发', '2026-06-26 17:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (11, 'SY2607020011', 11, 10, 8.28, 320, 4, 316, 'B010260702', '2027-04-27', '可派发', '2026-07-02 13:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (12, 'SY2607080012', 12, 10, 3.58, 280, -2, 282, 'B011260708', '2027-05-01', '可派发', '2026-07-08 12:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (13, 'SY2607140013', 13, 15, 1.54, 460, 1, 459, 'B012260714', '2027-05-05', '可派发', '2026-07-14 18:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (14, 'SY2607200014', 14, 15, 2.02, 340, 3, 337, 'B013260720', '2027-05-09', '可派发', '2026-07-20 16:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (15, 'SY2607260015', 15, 10, 12.96, 200, 7, 193, 'B014260726', '2027-05-13', '可派发', '2026-07-26 17:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (16, 'SY2608010016', 16, 15, 14.16, 260, -1, 261, 'B015260801', '2027-05-17', '可派发', '2026-08-01 15:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (17, 'SY2608070017', 17, 15, 0.95, 540, 0, 540, 'B016260807', '2027-05-21', '可派发', '2026-08-07 13:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (18, 'SY2608130018', 18, 13, 5.04, 300, 4, 296, 'B017260813', '2027-05-25', '可派发', '2026-08-13 18:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (19, 'SY2608190019', 19, 8, 2.39, 380, 1, 379, 'B018260819', '2027-05-29', '可派发', '2026-08-19 18:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (20, 'SY2608250020', 20, 8, 1.55, 240, 2, 238, 'B019260825', '2027-06-02', '可派发', '2026-08-25 10:00:00', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (21, 'SY2609030021', 1, 10, 8.58, 200, 2, 198, 'B900260903', '2027-06-30', '可派发', '2026-09-03 08:29:22', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (22, 'SY2609110022', 4, 10, 12.98, 150, 1, 149, 'B901260911', '2027-06-20', '可派发', '2026-09-11 17:34:04', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (23, 'SY2609190023', 7, 40, 0.98, 120, 3, 117, 'B902260919', '2027-06-10', '可派发', '2026-09-19 14:54:40', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (24, 'SY2609270024', 10, 8, 1.75, 100, 0, 100, 'B903260927', '2027-05-31', '可派发', '2026-09-27 19:48:38', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (25, 'SY2610050025', 13, 33, 1.41, 80, 4, 76, 'B904261005', '2027-05-21', '可派发', '2026-10-05 09:42:14', 2);
INSERT INTO sample_sku (id, sample_no, goods_id, spec_ml, cost_price, total_qty, sent_qty, remain_qty, batch_no, expire_date, status, create_time, create_by) VALUES (26, 'SY2610130026', 16, 16, 12.98, 60, 2, 58, 'B905261013', '2027-05-11', '可派发', '2026-10-13 18:32:58', 2);

-- 肤质档案（24 份，一人一档）
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (1, 'FZ26050200001', 10, '干性', '不敏感', '保湿', 58.00, '酒精、香精', 'V1', '2026-06-01', 1, '2026-05-02 19:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (2, 'FZ26050700002', 11, '油性', '一般', '控油,祛痘', 65.40, '香精', 'V2', '2026-06-06', 1, '2026-05-07 11:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (3, 'FZ26051200003', 12, '混合', '易敏感', '保湿,抗皱', 72.80, NULL, 'V2', '2026-06-11', 1, '2026-05-12 14:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (4, 'FZ26051700004', 13, '敏感', '高度敏感', '美白,保湿', 79.00, '防腐剂', 'V1', '2026-06-16', 1, '2026-05-17 19:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (5, 'FZ26052200005', 14, '中性', '不敏感', '舒缓,保湿', 86.40, '酒精', 'V2', '2026-06-21', 1, '2026-05-22 18:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (6, 'FZ26052700006', 15, '干性', '一般', '抗皱,美白', 93.80, NULL, 'V2', '2026-06-26', 1, '2026-05-27 18:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (7, 'FZ26060100007', 16, '油性', '易敏感', '保湿,控油', 62.00, '香精、色素', 'V1', '2026-07-01', 1, '2026-06-01 16:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (8, 'FZ26060600008', 17, '混合', '高度敏感', '保湿', 69.40, '酒精、香精', 'V2', '2026-07-06', 1, '2026-06-06 11:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (9, 'FZ26061100009', 18, '敏感', '不敏感', '控油,祛痘', 76.80, '香精', 'V2', '2026-07-11', 1, '2026-06-11 14:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (10, 'FZ26061600010', 19, '中性', '一般', '保湿,抗皱', 83.00, NULL, 'V1', '2026-07-16', 1, '2026-06-16 19:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (11, 'FZ26062100011', 20, '干性', '易敏感', '美白,保湿', 90.40, '防腐剂', 'V2', '2026-07-21', 1, '2026-06-21 12:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (12, 'FZ26062600012', 21, '油性', '高度敏感', '舒缓,保湿', 59.80, '酒精', 'V2', '2026-07-26', 1, '2026-06-26 14:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (13, 'FZ26070100013', 22, '混合', '不敏感', '抗皱,美白', 66.00, NULL, 'V1', '2026-07-31', 1, '2026-07-01 15:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (14, 'FZ26070600014', 23, '敏感', '一般', '保湿,控油', 73.40, '香精、色素', 'V2', '2026-08-05', 1, '2026-07-06 11:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (15, 'FZ26071100015', 24, '中性', '易敏感', '保湿', 80.80, '酒精、香精', 'V2', '2026-08-10', 1, '2026-07-11 17:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (16, 'FZ26071600016', 25, '干性', '高度敏感', '控油,祛痘', 87.00, '香精', 'V1', '2026-08-15', 1, '2026-07-16 10:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (17, 'FZ26072100017', 26, '油性', '不敏感', '保湿,抗皱', 94.40, NULL, 'V2', '2026-08-20', 1, '2026-07-21 17:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (18, 'FZ26072600018', 27, '混合', '一般', '美白,保湿', 63.80, '防腐剂', 'V2', '2026-08-25', 1, '2026-07-26 12:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (19, 'FZ26073100019', 28, '敏感', '易敏感', '舒缓,保湿', 70.00, '酒精', 'V1', '2026-08-30', 1, '2026-07-31 15:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (20, 'FZ26080500020', 29, '中性', '高度敏感', '抗皱,美白', 77.40, NULL, 'V2', '2026-09-04', 1, '2026-08-05 15:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (21, 'FZ26081000021', 30, '干性', '不敏感', '保湿,控油', 84.80, '香精、色素', 'V2', '2026-09-09', 1, '2026-08-10 18:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (22, 'FZ26081500022', 31, '油性', '一般', '保湿', 91.00, '酒精、香精', 'V1', '2026-09-14', 1, '2026-08-15 16:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (23, 'FZ26082000023', 32, '混合', '易敏感', '控油,祛痘', 60.40, '香精', 'V2', '2026-09-19', 1, '2026-08-20 12:00:00');
INSERT INTO skin_profile (id, profile_no, user_id, skin_type, sensitive_level, demand_tags, self_test_score, allergy_ingredients, paper_version, update_date, status, create_time) VALUES (24, 'FZ26082500024', 33, '敏感', '高度敏感', '保湿,抗皱', 67.80, NULL, 'V2', '2026-09-24', 1, '2026-08-25 16:00:00');

-- 试用申领（70 条，覆盖 6 种状态，时间跨 2026-05 ~ 2026-10）
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (1, 'SQ261030000001', 3, 17, 8, '换季后两颊起皮，上妆卡粉，想先试小样看是否闷痘。', '叶南乔', '13910000959', '北京市朝阳区建国路 93 号院 5 号楼 902', NULL, NULL, NULL, '待审核', '2026-10-30 14:57:17', 17);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (2, 'SQ261031000001', 9, 10, 1, '近期熬夜暗沉明显，想先试用小样确认会不会刺痛。', '苏念', '13910000000', '上海市徐汇区漕溪北路 88 号 1506', NULL, NULL, NULL, '待审核', '2026-10-31 12:05:10', 10);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (3, 'SQ261101000001', 9, 32, 23, '一直想买这款但担心不耐受，先领小样在耳后试用。', '施南', '13910003014', '北京市朝阳区建国路 93 号院 5 号楼 902', NULL, NULL, NULL, '待审核', '2026-11-01 20:59:16', 32);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (4, 'SQ261029000001', 15, 25, 16, '换季敏感期，想找一款不刺激的修护产品先试小样。', '方知有', '13910002055', '北京市朝阳区建国路 93 号院 5 号楼 902', NULL, NULL, NULL, '待审核', '2026-10-29 15:04:49', 25);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (5, 'SQ261029000002', 3, 13, 4, 'T 区出油严重但两颊偏干，想试一下这款是否适合混合肌。', '林见夏', '13910000411', '浙江省杭州市滨江区江南大道 588 号 A 座 1201', NULL, NULL, NULL, '待审核', '2026-10-29 10:53:14', 13);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (6, 'SQ261031000002', 6, 15, 6, '换季后两颊起皮，上妆卡粉，想先试小样看是否闷痘。', '何知微', '13910000685', '上海市徐汇区漕溪北路 88 号 1506', NULL, NULL, NULL, '待审核', '2026-10-31 20:49:45', 15);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (7, 'SQ261101000002', 11, 31, 22, '皮肤屏障受损泛红，想用温和的产品做一次小样测试。', '沐晴', '13910002877', '浙江省杭州市滨江区江南大道 588 号 A 座 1201', NULL, NULL, NULL, '待审核', '2026-11-01 12:34:46', 31);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (8, 'SQ261031000003', 14, 26, 17, '换季敏感期，想找一款不刺激的修护产品先试小样。', '闻莺', '13910002192', '北京市朝阳区建国路 93 号院 5 号楼 902', NULL, NULL, NULL, '待审核', '2026-10-31 15:39:42', 26);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (9, 'SQ261030000002', 14, 21, 12, '一直想买这款但担心不耐受，先领小样在耳后试用。', '裴宁', '13910001507', '浙江省杭州市滨江区江南大道 588 号 A 座 1201', NULL, NULL, NULL, '待审核', '2026-10-30 21:35:31', 21);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (10, 'SQ261019000001', 15, 24, 15, '一直想买这款但担心不耐受，先领小样在耳后试用。', '姜屿', '13910001918', '浙江省杭州市滨江区江南大道 588 号 A 座 1201', '肤质档案与商品适用类型不匹配，建议改申其他款。', NULL, NULL, '已驳回', '2026-10-19 19:32:03', 24);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (11, 'SQ261012000001', 9, 22, 13, '皮肤屏障受损泛红，想用温和的产品做一次小样测试。', '南乔', '13910001644', '浙江省杭州市西湖区文三路 199 号 3 幢 802', '30 天内已申领过同款试用装，请下周再来。', NULL, NULL, '已驳回', '2026-10-12 09:36:01', 22);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (12, 'SQ260908000001', 25, 25, 16, '一直想买这款但担心不耐受，先领小样在耳后试用。', '方知有', '13910002055', '浙江省杭州市西湖区文三路 199 号 3 幢 802', '收货地址信息不完整，请补充到门牌号后重提。', NULL, NULL, '已驳回', '2026-09-08 12:21:37', 25);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (13, 'SQ260927000001', 22, 22, 13, '换季敏感期，想找一款不刺激的修护产品先试小样。', '南乔', '13910001644', '广东省深圳市南山区科苑路 15 号 3 栋 1802', '收货地址信息不完整，请补充到门牌号后重提。', NULL, NULL, '已驳回', '2026-09-27 14:40:59', 22);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (14, 'SQ260901000001', 13, 32, 23, '皮肤屏障受损泛红，想用温和的产品做一次小样测试。', '施南', '13910003014', '北京市朝阳区建国路 93 号院 5 号楼 902', '肤质档案与商品适用类型不匹配，建议改申其他款。', NULL, NULL, '已驳回', '2026-09-01 08:05:56', 32);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (15, 'SQ261027000001', 6, 32, 23, '皮肤屏障受损泛红，想用温和的产品做一次小样测试。', '施南', '13910003014', '上海市徐汇区漕溪北路 88 号 1506', '收货地址信息不完整，请补充到门牌号后重提。', NULL, NULL, '已驳回', '2026-10-27 17:20:52', 32);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (16, 'SQ260602000001', 20, 21, 12, 'T 区出油严重但两颊偏干，想试一下这款是否适合混合肌。', '裴宁', '13910001507', '江苏省南京市鼓楼区中山北路 105 号 2 单元 601', '申领理由过于简单，请补充当前肌肤问题描述。', NULL, NULL, '已驳回', '2026-06-02 19:41:28', 21);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (17, 'SQ261026000001', 12, 18, 9, '换季后两颊起皮，上妆卡粉，想先试小样看是否闷痘。', '秦笺', '13910001096', '北京市朝阳区建国路 93 号院 5 号楼 902', NULL, NULL, NULL, '待发放', '2026-10-26 16:13:59', 18);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (18, 'SQ261027000002', 23, 30, 21, '同事推荐，想先试 10ml 小样看质地和味道能否接受。', '江晚', '13910002740', '广东省深圳市南山区科苑路 15 号 3 栋 1802', NULL, NULL, NULL, '待发放', '2026-10-27 15:06:43', 30);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (19, 'SQ261026000002', 19, 32, 23, '换季后两颊起皮，上妆卡粉，想先试小样看是否闷痘。', '施南', '13910003014', '上海市徐汇区漕溪北路 88 号 1506', NULL, NULL, NULL, '待发放', '2026-10-26 16:51:17', 32);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (20, 'SQ261022000001', 12, 32, 23, 'T 区出油严重但两颊偏干，想试一下这款是否适合混合肌。', '施南', '13910003014', '广东省深圳市南山区科苑路 15 号 3 栋 1802', NULL, NULL, NULL, '待发放', '2026-10-22 12:19:48', 32);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (21, 'SQ261030000003', 4, 19, 10, '皮肤屏障受损泛红，想用温和的产品做一次小样测试。', '顾青禾', '13910001233', '上海市徐汇区漕溪北路 88 号 1506', NULL, NULL, NULL, '待发放', '2026-10-30 18:21:53', 19);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (22, 'SQ261022000002', 8, 33, 24, '一直想买这款但担心不耐受，先领小样在耳后试用。', '余温', '13910003151', '北京市朝阳区建国路 93 号院 5 号楼 902', NULL, NULL, NULL, '待发放', '2026-10-22 18:12:06', 33);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (23, 'SQ261101000003', 15, 15, 6, '换季敏感期，想找一款不刺激的修护产品先试小样。', '何知微', '13910000685', '上海市徐汇区漕溪北路 88 号 1506', NULL, NULL, NULL, '待发放', '2026-11-01 15:47:40', 15);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (24, 'SQ261027000003', 12, 11, 2, '皮肤屏障受损泛红，想用温和的产品做一次小样测试。', '陈亦然', '13910000137', '广东省深圳市南山区科苑路 15 号 3 栋 1802', NULL, NULL, NULL, '待发放', '2026-10-27 15:21:58', 11);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (25, 'SQ261026000003', 24, 32, 23, '一直想买这款但担心不耐受，先领小样在耳后试用。', '施南', '13910003014', '浙江省杭州市滨江区江南大道 588 号 A 座 1201', NULL, 'JD000000001016', '2026-10-27 21:31:55', '已发放', '2026-10-26 13:31:55', 32);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (26, 'SQ261030000004', 14, 11, 2, 'T 区出油严重但两颊偏干，想试一下这款是否适合混合肌。', '陈亦然', '13910000137', '北京市朝阳区建国路 93 号院 5 号楼 902', NULL, 'JD000000001021', '2026-11-02 05:00:35', '已发放', '2026-10-30 21:00:35', 11);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (27, 'SQ261026000004', 10, 15, 6, '皮肤屏障受损泛红，想用温和的产品做一次小样测试。', '何知微', '13910000685', '江苏省南京市鼓楼区中山北路 105 号 2 单元 601', NULL, 'JD000000001031', '2026-10-27 18:52:09', '已发放', '2026-10-26 10:52:09', 15);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (28, 'SQ261028000001', 18, 29, 20, '皮肤屏障受损泛红，想用温和的产品做一次小样测试。', '白露', '13910002603', '上海市徐汇区漕溪北路 88 号 1506', NULL, 'SF000000001043', '2026-10-29 20:48:45', '已发放', '2026-10-28 13:48:45', 29);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (29, 'SQ261028000002', 15, 14, 5, 'T 区出油严重但两颊偏干，想试一下这款是否适合混合肌。', '许清和', '13910000548', '江苏省南京市鼓楼区中山北路 105 号 2 单元 601', NULL, 'YT000000001060', '2026-10-31 14:31:45', '已发放', '2026-10-28 12:31:45', 14);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (30, 'SQ261029000003', 15, 28, 19, '一直想买这款但担心不耐受，先领小样在耳后试用。', '宋祁', '13910002466', '浙江省杭州市滨江区江南大道 588 号 A 座 1201', NULL, 'JD000000001066', '2026-10-30 17:25:46', '已发放', '2026-10-29 14:25:46', 28);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (31, 'SQ261025000001', 23, 31, 22, '一直想买这款但担心不耐受，先领小样在耳后试用。', '沐晴', '13910002877', '江苏省南京市鼓楼区中山北路 105 号 2 单元 601', NULL, 'YT000000001072', '2026-10-27 22:27:06', '已发放', '2026-10-25 14:27:06', 31);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (32, 'SQ261030000005', 23, 23, 14, 'T 区出油严重但两颊偏干，想试一下这款是否适合混合肌。', '程锦', '13910001781', '浙江省杭州市滨江区江南大道 588 号 A 座 1201', NULL, 'JD000000001082', '2026-11-02 14:51:54', '已发放', '2026-10-30 12:51:54', 23);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (33, 'SQ261026000005', 7, 23, 14, '换季敏感期，想找一款不刺激的修护产品先试小样。', '程锦', '13910001781', '上海市徐汇区漕溪北路 88 号 1506', NULL, 'YT000000001086', '2026-10-27 21:46:07', '已发放', '2026-10-26 16:46:07', 23);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (34, 'SQ261025000002', 24, 26, 17, '一直想买这款但担心不耐受，先领小样在耳后试用。', '闻莺', '13910002192', '广东省深圳市南山区科苑路 15 号 3 栋 1802', NULL, 'SF000000001098', '2026-10-28 23:27:08', '已发放', '2026-10-25 21:27:08', 26);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (35, 'SQ261014000001', 6, 11, 2, '换季敏感期，想找一款不刺激的修护产品先试小样。', '陈亦然', '13910000137', '上海市徐汇区漕溪北路 88 号 1506', NULL, 'SF000000001105', '2026-10-18 00:54:58', '待提交报告', '2026-10-14 17:54:58', 11);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (36, 'SQ261027000004', 11, 14, 5, 'T 区出油严重但两颊偏干，想试一下这款是否适合混合肌。', '许清和', '13910000548', '北京市朝阳区建国路 93 号院 5 号楼 902', NULL, 'YT000000001113', '2026-10-31 01:23:56', '待提交报告', '2026-10-27 19:23:56', 14);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (37, 'SQ261019000002', 22, 30, 21, 'T 区出油严重但两颊偏干，想试一下这款是否适合混合肌。', '江晚', '13910002740', '上海市徐汇区漕溪北路 88 号 1506', NULL, 'JD000000001124', '2026-10-21 23:17:36', '待提交报告', '2026-10-19 20:17:36', 30);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (38, 'SQ261005000001', 13, 23, 14, '换季敏感期，想找一款不刺激的修护产品先试小样。', '程锦', '13910001781', '浙江省杭州市西湖区文三路 199 号 3 幢 802', NULL, 'YT000000001127', '2026-10-06 22:12:21', '待提交报告', '2026-10-05 19:12:21', 23);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (39, 'SQ261011000001', 10, 32, 23, '同事推荐，想先试 10ml 小样看质地和味道能否接受。', '施南', '13910003014', '浙江省杭州市西湖区文三路 199 号 3 幢 802', NULL, 'YT000000001130', '2026-10-14 16:41:15', '待提交报告', '2026-10-11 11:41:15', 32);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (40, 'SQ261005000002', 21, 26, 17, '一直想买这款但担心不耐受，先领小样在耳后试用。', '闻莺', '13910002192', '江苏省南京市鼓楼区中山北路 105 号 2 单元 601', NULL, 'JD000000001136', '2026-10-07 03:21:56', '待提交报告', '2026-10-05 19:21:56', 26);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (41, 'SQ261005000003', 19, 31, 22, '近期熬夜暗沉明显，想先试用小样确认会不会刺痛。', '沐晴', '13910002877', '江苏省南京市鼓楼区中山北路 105 号 2 单元 601', NULL, 'SF000000001151', '2026-10-07 21:50:43', '待提交报告', '2026-10-05 13:50:43', 31);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (42, 'SQ261021000001', 8, 11, 2, 'T 区出油严重但两颊偏干，想试一下这款是否适合混合肌。', '陈亦然', '13910000137', '上海市徐汇区漕溪北路 88 号 1506', NULL, 'SF000000001163', '2026-10-23 18:23:54', '待提交报告', '2026-10-21 17:23:54', 11);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (43, 'SQ261009000001', 8, 24, 15, 'T 区出油严重但两颊偏干，想试一下这款是否适合混合肌。', '姜屿', '13910001918', '浙江省杭州市滨江区江南大道 588 号 A 座 1201', NULL, 'JD000000001177', '2026-10-12 02:45:22', '待提交报告', '2026-10-09 18:45:22', 24);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (44, 'SQ261024000001', 23, 32, 23, '皮肤屏障受损泛红，想用温和的产品做一次小样测试。', '施南', '13910003014', '浙江省杭州市西湖区文三路 199 号 3 幢 802', NULL, 'JD000000001181', '2026-10-26 23:08:58', '待提交报告', '2026-10-24 17:08:58', 32);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (45, 'SQ261013000001', 26, 11, 2, '换季后两颊起皮，上妆卡粉，想先试小样看是否闷痘。', '陈亦然', '13910000137', '上海市徐汇区漕溪北路 88 号 1506', NULL, 'SF000000001190', '2026-10-16 00:40:24', '待提交报告', '2026-10-13 19:40:24', 11);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (46, 'SQ261023000001', 14, 10, 1, '同事推荐，想先试 10ml 小样看质地和味道能否接受。', '苏念', '13910000000', '江苏省南京市鼓楼区中山北路 105 号 2 单元 601', NULL, 'SF000000001197', '2026-10-25 00:52:58', '待提交报告', '2026-10-23 16:52:58', 10);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (47, 'SQ261024000002', 5, 16, 7, '皮肤屏障受损泛红，想用温和的产品做一次小样测试。', '沈栖迟', '13910000822', '广东省深圳市南山区科苑路 15 号 3 栋 1802', NULL, 'SF000000001202', '2026-10-25 12:24:41', '待提交报告', '2026-10-24 08:24:41', 16);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (48, 'SQ261025000003', 3, 22, 13, '换季敏感期，想找一款不刺激的修护产品先试小样。', '南乔', '13910001644', '上海市徐汇区漕溪北路 88 号 1506', NULL, 'SF000000001205', '2026-10-29 03:47:15', '待提交报告', '2026-10-25 19:47:15', 22);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (49, 'SQ260614000001', 16, 29, 20, '同事推荐，想先试 10ml 小样看质地和味道能否接受。', '白露', '13910002603', '北京市朝阳区建国路 93 号院 5 号楼 902', NULL, 'SF000000001217', '2026-06-16 10:37:58', '已完成', '2026-06-14 08:37:58', 29);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (50, 'SQ260721000001', 5, 11, 2, '同事推荐，想先试 10ml 小样看质地和味道能否接受。', '陈亦然', '13910000137', '北京市朝阳区建国路 93 号院 5 号楼 902', NULL, 'JD000000001228', '2026-07-24 20:57:12', '已完成', '2026-07-21 12:57:12', 11);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (51, 'SQ260620000001', 7, 21, 12, '换季后两颊起皮，上妆卡粉，想先试小样看是否闷痘。', '裴宁', '13910001507', '上海市徐汇区漕溪北路 88 号 1506', NULL, 'SF000000001237', '2026-06-22 16:52:12', '已完成', '2026-06-20 10:52:12', 21);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (52, 'SQ260606000001', 26, 32, 23, '皮肤屏障受损泛红，想用温和的产品做一次小样测试。', '施南', '13910003014', '江苏省南京市鼓楼区中山北路 105 号 2 单元 601', NULL, 'YT000000001242', '2026-06-09 03:41:02', '已完成', '2026-06-06 20:41:02', 32);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (53, 'SQ260607000001', 3, 17, 8, '换季敏感期，想找一款不刺激的修护产品先试小样。', '叶南乔', '13910000959', '江苏省南京市鼓楼区中山北路 105 号 2 单元 601', NULL, 'SF000000001256', '2026-06-10 01:09:58', '已完成', '2026-06-07 17:09:58', 17);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (54, 'SQ260814000001', 15, 15, 6, '一直想买这款但担心不耐受，先领小样在耳后试用。', '何知微', '13910000685', '浙江省杭州市西湖区文三路 199 号 3 幢 802', NULL, 'SF000000001271', '2026-08-16 14:17:50', '已完成', '2026-08-14 09:17:50', 15);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (55, 'SQ260516000001', 7, 28, 19, 'T 区出油严重但两颊偏干，想试一下这款是否适合混合肌。', '宋祁', '13910002466', '广东省深圳市南山区科苑路 15 号 3 栋 1802', NULL, 'YT000000001279', '2026-05-17 18:34:26', '已完成', '2026-05-16 14:34:26', 28);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (56, 'SQ260821000001', 6, 17, 8, 'T 区出油严重但两颊偏干，想试一下这款是否适合混合肌。', '叶南乔', '13910000959', '上海市徐汇区漕溪北路 88 号 1506', NULL, 'SF000000001292', '2026-08-23 17:47:27', '已完成', '2026-08-21 14:47:27', 17);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (57, 'SQ260719000001', 18, 17, 8, '同事推荐，想先试 10ml 小样看质地和味道能否接受。', '叶南乔', '13910000959', '上海市徐汇区漕溪北路 88 号 1506', NULL, 'JD000000001300', '2026-07-20 19:57:27', '已完成', '2026-07-19 16:57:27', 17);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (58, 'SQ260602000002', 11, 24, 15, '皮肤屏障受损泛红，想用温和的产品做一次小样测试。', '姜屿', '13910001918', '江苏省南京市鼓楼区中山北路 105 号 2 单元 601', NULL, 'SF000000001305', '2026-06-04 21:19:04', '已完成', '2026-06-02 19:19:04', 24);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (59, 'SQ261001000001', 11, 10, 1, '换季后两颊起皮，上妆卡粉，想先试小样看是否闷痘。', '苏念', '13910000000', '北京市朝阳区建国路 93 号院 5 号楼 902', NULL, 'YT000000001312', '2026-10-03 18:13:14', '已完成', '2026-10-01 12:13:14', 10);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (60, 'SQ260806000001', 3, 26, 17, '皮肤屏障受损泛红，想用温和的产品做一次小样测试。', '闻莺', '13910002192', '浙江省杭州市西湖区文三路 199 号 3 幢 802', NULL, 'YT000000001319', '2026-08-08 21:59:32', '已完成', '2026-08-06 15:59:32', 26);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (61, 'SQ260620000002', 25, 30, 21, 'T 区出油严重但两颊偏干，想试一下这款是否适合混合肌。', '江晚', '13910002740', '上海市徐汇区漕溪北路 88 号 1506', NULL, 'SF000000001331', '2026-06-22 18:54:28', '已完成', '2026-06-20 13:54:28', 30);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (62, 'SQ260906000001', 18, 25, 16, 'T 区出油严重但两颊偏干，想试一下这款是否适合混合肌。', '方知有', '13910002055', '浙江省杭州市西湖区文三路 199 号 3 幢 802', NULL, 'YT000000001335', '2026-09-10 02:54:45', '已完成', '2026-09-06 18:54:45', 25);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (63, 'SQ260713000001', 14, 14, 5, '换季敏感期，想找一款不刺激的修护产品先试小样。', '许清和', '13910000548', '上海市徐汇区漕溪北路 88 号 1506', NULL, 'JD000000001348', '2026-07-14 18:24:06', '已完成', '2026-07-13 11:24:06', 14);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (64, 'SQ260628000001', 1, 33, 24, 'T 区出油严重但两颊偏干，想试一下这款是否适合混合肌。', '余温', '13910003151', '浙江省杭州市西湖区文三路 199 号 3 幢 802', NULL, 'SF000000001361', '2026-07-01 20:34:55', '已完成', '2026-06-28 12:34:55', 33);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (65, 'SQ260829000001', 15, 33, 24, '皮肤屏障受损泛红，想用温和的产品做一次小样测试。', '余温', '13910003151', '广东省深圳市南山区科苑路 15 号 3 栋 1802', NULL, 'JD000000001368', '2026-08-31 14:58:18', '已完成', '2026-08-29 13:58:18', 33);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (66, 'SQ260721000002', 18, 16, 7, '皮肤屏障受损泛红，想用温和的产品做一次小样测试。', '沈栖迟', '13910000822', '上海市徐汇区漕溪北路 88 号 1506', NULL, 'JD000000001383', '2026-07-24 19:05:36', '已完成', '2026-07-21 11:05:36', 16);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (67, 'SQ260909000001', 20, 15, 6, '皮肤屏障受损泛红，想用温和的产品做一次小样测试。', '何知微', '13910000685', '北京市朝阳区建国路 93 号院 5 号楼 902', NULL, 'SF000000001398', '2026-09-11 11:42:11', '已完成', '2026-09-09 08:42:11', 15);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (68, 'SQ260827000001', 11, 31, 22, '换季后两颊起皮，上妆卡粉，想先试小样看是否闷痘。', '沐晴', '13910002877', '浙江省杭州市西湖区文三路 199 号 3 幢 802', NULL, 'YT000000001401', '2026-08-28 18:40:32', '已完成', '2026-08-27 11:40:32', 31);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (69, 'SQ260522000001', 8, 20, 11, '近期熬夜暗沉明显，想先试用小样确认会不会刺痛。', '温言', '13910001370', '上海市徐汇区漕溪北路 88 号 1506', NULL, 'YT000000001407', '2026-05-23 17:35:30', '已完成', '2026-05-22 16:35:30', 20);
INSERT INTO sample_apply (id, apply_no, sample_id, user_id, skin_profile_id, apply_reason, receiver_name, receiver_phone, address_desc, audit_remark, express_no, send_time, status, create_time, create_by) VALUES (70, 'SQ260704000001', 21, 32, 23, '一直想买这款但担心不耐受，先领小样在耳后试用。', '施南', '13910003014', '浙江省杭州市西湖区文三路 199 号 3 幢 802', NULL, 'YT000000001421', '2026-07-05 20:00:06', '已完成', '2026-07-04 17:00:06', 32);

-- 试用报告（32 份，一申领单一报告）
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (1, 'BG261029000001', 35, 11, 11, 4, 4, '考虑中', '上脸不粘，吸收很快，第二天起来脸颊没有起皮，上妆也更服帖。唯一不太习惯的是味道偏香，敏感期可能会刺激，整体还是会回购正装。', '/uploads/seed/report/02.jpg,/uploads/seed/report/05.jpg', 0, '待审核', '2026-10-29 06:54:58', 11);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (2, 'BG261102000001', 36, 14, 2, 5, 5, '考虑中', '泡沫细腻，洗完不假滑也不紧绷，敏感期用着没有泛红。清洁力对油皮稍弱，夏天可能需要配合洁面仪。', '/uploads/seed/report/03.jpg,/uploads/seed/report/06.jpg', 0, '待审核', '2026-11-02 05:23:56', 14);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (3, 'BG261031000001', 37, 30, 9, 2, 5, '一定回购', '质地清爽，早晚各一次用了两周，脸颊的暗沉淡了一些，早上出油也少了。没有刺痛和搓泥，性价比不错，会考虑回购。', '/uploads/seed/report/04.jpg,/uploads/seed/report/07.jpg', 0, '已隐藏', '2026-10-31 00:17:36', 30);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (4, 'BG261022000001', 38, 23, 16, 4, 5, '考虑中', '味道清淡，延展性好，一泵够全脸。用了十天鼻翼的小颗粒平了不少，但价格偏高，会等大促再买。', '/uploads/seed/report/05.jpg,/uploads/seed/report/08.jpg', 0, '已隐藏', '2026-10-22 23:12:21', 23);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (5, 'BG261101000001', 39, 32, 18, 4, 2, '不会回购', '霜体偏厚但不闷，用了几天两颊的刺痛感明显减轻，晚上厚涂一层第二天不紧绷。白天叠防晒没有搓泥，值得回购。', '/uploads/seed/report/06.jpg,/uploads/seed/report/09.jpg', 0, '待审核', '2026-11-01 18:41:15', 32);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (6, 'BG261025000001', 40, 26, 18, 5, 4, '不会回购', '质地清爽，早晚各一次用了两周，脸颊的暗沉淡了一些，早上出油也少了。没有刺痛和搓泥，性价比不错，会考虑回购。', '/uploads/seed/report/07.jpg,/uploads/seed/report/10.jpg', 0, '待审核', '2026-10-25 09:21:56', 26);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (7, 'BG261023000001', 41, 31, 16, 3, 3, '不会回购', '保湿力度够，冬天用不紧绷，只是叠面霜会有点搓泥，建议少量多次上脸。', '/uploads/seed/report/08.jpg,/uploads/seed/report/01.jpg', 0, '已驳回', '2026-10-23 22:50:43', 31);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (8, 'BG261026000001', 42, 11, 3, 5, 2, '一定回购', '霜体偏厚但不闷，用了几天两颊的刺痛感明显减轻，晚上厚涂一层第二天不紧绷。白天叠防晒没有搓泥，值得回购。', '/uploads/seed/report/09.jpg,/uploads/seed/report/02.jpg', 0, '待审核', '2026-10-26 19:23:54', 11);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (9, 'BG261101000002', 44, 32, 6, 5, 3, '考虑中', '上脸不粘，吸收很快，第二天起来脸颊没有起皮，上妆也更服帖。唯一不太习惯的是味道偏香，敏感期可能会刺激，整体还是会回购正装。', '/uploads/seed/report/10.jpg,/uploads/seed/report/03.jpg', 0, '待审核', '2026-11-01 23:08:58', 32);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (10, 'BG261024000001', 45, 11, 8, 5, 4, '一定回购', '质地清爽，早晚各一次用了两周，脸颊的暗沉淡了一些，早上出油也少了。没有刺痛和搓泥，性价比不错，会考虑回购。使用第 3 天颧骨处出现轻微泛红和小疹子，停用两天后缓解，怀疑对其中某个成分不耐受。', '/uploads/seed/report/01.jpg,/uploads/seed/report/04.jpg', 1, '已驳回', '2026-10-24 06:40:24', 11);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (11, 'BG260712000001', 49, 29, 26, 4, 5, '考虑中', '泡沫细腻，洗完不假滑也不紧绷，敏感期用着没有泛红。清洁力对油皮稍弱，夏天可能需要配合洁面仪。', '/uploads/seed/report/02.jpg,/uploads/seed/report/05.jpg', 0, '已通过', '2026-07-12 15:37:58', 29);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (12, 'BG260729000001', 50, 11, 5, 4, 2, '一定回购', '味道清淡，延展性好，一泵够全脸。用了十天鼻翼的小颗粒平了不少，但价格偏高，会等大促再买。', '/uploads/seed/report/03.jpg,/uploads/seed/report/06.jpg', 0, '已通过', '2026-07-29 20:57:12', 11);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (13, 'BG260630000001', 51, 21, 8, 5, 3, '考虑中', '质地清爽，早晚各一次用了两周，脸颊的暗沉淡了一些，早上出油也少了。没有刺痛和搓泥，性价比不错，会考虑回购。', '/uploads/seed/report/04.jpg,/uploads/seed/report/07.jpg', 0, '已通过', '2026-06-30 21:52:12', 21);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (14, 'BG260620000001', 52, 32, 11, 4, 5, '考虑中', '质地清爽，早晚各一次用了两周，脸颊的暗沉淡了一些，早上出油也少了。没有刺痛和搓泥，性价比不错，会考虑回购。使用第 3 天颧骨处出现轻微泛红和小疹子，停用两天后缓解，怀疑对其中某个成分不耐受。', '/uploads/seed/report/05.jpg,/uploads/seed/report/08.jpg', 1, '已通过', '2026-06-20 03:41:02', 32);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (15, 'BG260705000001', 53, 17, 25, 4, 4, '考虑中', '保湿力度够，冬天用不紧绷，只是叠面霜会有点搓泥，建议少量多次上脸。', '/uploads/seed/report/06.jpg,/uploads/seed/report/09.jpg', 0, '已通过', '2026-07-05 04:09:58', 17);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (16, 'BG260906000001', 54, 15, 21, 5, 2, '考虑中', '霜体偏厚但不闷，用了几天两颊的刺痛感明显减轻，晚上厚涂一层第二天不紧绷。白天叠防晒没有搓泥，值得回购。使用第 3 天颧骨处出现轻微泛红和小疹子，停用两天后缓解，怀疑对其中某个成分不耐受。', '/uploads/seed/report/07.jpg,/uploads/seed/report/10.jpg', 1, '已通过', '2026-09-06 17:17:50', 15);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (17, 'BG260526000001', 55, 28, 9, 2, 3, '不会回购', '质地清爽，早晚各一次用了两周，脸颊的暗沉淡了一些，早上出油也少了。没有刺痛和搓泥，性价比不错，会考虑回购。', '/uploads/seed/report/08.jpg,/uploads/seed/report/01.jpg', 0, '已通过', '2026-05-26 21:34:26', 28);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (18, 'BG260910000001', 56, 17, 18, 4, 4, '考虑中', '保湿力度够，冬天用不紧绷，只是叠面霜会有点搓泥，建议少量多次上脸。', '/uploads/seed/report/09.jpg,/uploads/seed/report/02.jpg', 0, '已通过', '2026-09-10 21:47:27', 17);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (19, 'BG260813000001', 57, 17, 24, 5, 3, '不会回购', '上脸不粘，吸收很快，第二天起来脸颊没有起皮，上妆也更服帖。唯一不太习惯的是味道偏香，敏感期可能会刺激，整体还是会回购正装。', '/uploads/seed/report/10.jpg,/uploads/seed/report/03.jpg', 0, '已通过', '2026-08-13 21:57:27', 17);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (20, 'BG260703000001', 58, 24, 28, 5, 4, '考虑中', '泡沫细腻，洗完不假滑也不紧绷，敏感期用着没有泛红。清洁力对油皮稍弱，夏天可能需要配合洁面仪。', '/uploads/seed/report/01.jpg,/uploads/seed/report/04.jpg', 0, '已通过', '2026-07-03 02:19:04', 24);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (21, 'BG261028000001', 59, 10, 25, 4, 5, '不会回购', '保湿力度够，冬天用不紧绷，只是叠面霜会有点搓泥，建议少量多次上脸。', '/uploads/seed/report/02.jpg,/uploads/seed/report/05.jpg', 0, '已通过', '2026-10-28 18:13:14', 10);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (22, 'BG260818000001', 60, 26, 10, 2, 4, '考虑中', '保湿力度够，冬天用不紧绷，只是叠面霜会有点搓泥，建议少量多次上脸。', '/uploads/seed/report/03.jpg,/uploads/seed/report/06.jpg', 0, '已通过', '2026-08-18 22:59:32', 26);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (23, 'BG260701000001', 61, 30, 9, 4, 5, '一定回购', '泡沫细腻，洗完不假滑也不紧绷，敏感期用着没有泛红。清洁力对油皮稍弱，夏天可能需要配合洁面仪。', '/uploads/seed/report/04.jpg,/uploads/seed/report/07.jpg', 0, '已通过', '2026-07-01 21:54:28', 30);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (24, 'BG260913000001', 62, 25, 3, 4, 5, '不会回购', '质地清爽，早晚各一次用了两周，脸颊的暗沉淡了一些，早上出油也少了。没有刺痛和搓泥，性价比不错，会考虑回购。', '/uploads/seed/report/05.jpg,/uploads/seed/report/08.jpg', 0, '已通过', '2026-09-13 08:54:45', 25);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (25, 'BG260810000001', 63, 14, 27, 5, 4, '不会回购', '上脸不粘，吸收很快，第二天起来脸颊没有起皮，上妆也更服帖。唯一不太习惯的是味道偏香，敏感期可能会刺激，整体还是会回购正装。', '/uploads/seed/report/06.jpg,/uploads/seed/report/09.jpg', 0, '已通过', '2026-08-10 19:24:06', 14);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (26, 'BG260726000001', 64, 33, 25, 5, 5, '不会回购', '上脸不粘，吸收很快，第二天起来脸颊没有起皮，上妆也更服帖。唯一不太习惯的是味道偏香，敏感期可能会刺激，整体还是会回购正装。使用第 3 天颧骨处出现轻微泛红和小疹子，停用两天后缓解，怀疑对其中某个成分不耐受。', '/uploads/seed/report/07.jpg,/uploads/seed/report/10.jpg', 1, '已通过', '2026-07-26 22:34:55', 33);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (27, 'BG260923000001', 65, 33, 23, 4, 2, '一定回购', '泡沫细腻，洗完不假滑也不紧绷，敏感期用着没有泛红。清洁力对油皮稍弱，夏天可能需要配合洁面仪。', '/uploads/seed/report/08.jpg,/uploads/seed/report/01.jpg', 0, '已通过', '2026-09-23 16:58:18', 33);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (28, 'BG260806000001', 66, 16, 12, 2, 5, '考虑中', '上脸不粘，吸收很快，第二天起来脸颊没有起皮，上妆也更服帖。唯一不太习惯的是味道偏香，敏感期可能会刺激，整体还是会回购正装。', '/uploads/seed/report/09.jpg,/uploads/seed/report/02.jpg', 0, '已通过', '2026-08-06 01:05:36', 16);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (29, 'BG260916000001', 67, 15, 5, 2, 5, '考虑中', '保湿力度够，冬天用不紧绷，只是叠面霜会有点搓泥，建议少量多次上脸。', '/uploads/seed/report/10.jpg,/uploads/seed/report/03.jpg', 0, '已通过', '2026-09-16 12:42:11', 15);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (30, 'BG260923000002', 68, 31, 26, 5, 5, '考虑中', '保湿力度够，冬天用不紧绷，只是叠面霜会有点搓泥，建议少量多次上脸。', '/uploads/seed/report/01.jpg,/uploads/seed/report/04.jpg', 0, '已通过', '2026-09-23 18:40:32', 31);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (31, 'BG260530000001', 69, 20, 7, 4, 3, '考虑中', '泡沫细腻，洗完不假滑也不紧绷，敏感期用着没有泛红。清洁力对油皮稍弱，夏天可能需要配合洁面仪。', '/uploads/seed/report/02.jpg,/uploads/seed/report/05.jpg', 0, '已通过', '2026-05-30 18:35:30', 20);
INSERT INTO trial_report (id, report_no, apply_id, user_id, use_days, absorb_score, mild_score, repurchase_will, content, image_urls, allergic_flag, status, create_time, create_by) VALUES (32, 'BG260715000001', 70, 32, 10, 4, 3, '一定回购', '保湿力度够，冬天用不紧绷，只是叠面霜会有点搓泥，建议少量多次上脸。', '/uploads/seed/report/03.jpg,/uploads/seed/report/06.jpg', 0, '已通过', '2026-07-15 21:00:06', 32);

-- 正装订单（51 条，含归因与退款）
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (1, 'ZD260620000001', 29, 16, 1, 1180.00, 94.40, 1085.60, 49, '微信', '已支付', '已完成', '2026-06-20 16:37:58', 29);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (2, 'ZD260819000001', 11, 5, 1, 268.00, 21.44, 246.56, 50, '微信', '已支付', '待发货', '2026-08-19 04:57:12', 11);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (3, 'ZD260626000001', 21, 7, 1, 89.00, 7.12, 81.88, 51, '微信', '已支付', '已发货', '2026-06-26 02:52:12', 21);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (4, 'ZD260620000002', 32, 16, 2, 2360.00, 188.80, 2171.20, 52, '支付宝', '已支付', '已发货', '2026-06-20 11:41:02', 32);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (5, 'ZD260629000001', 17, 3, 1, 289.00, 23.12, 265.88, 53, '微信', '已支付', '待发货', '2026-06-29 11:09:58', 17);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (6, 'ZD260526000001', 28, 7, 1, 89.00, 7.12, 81.88, 55, '支付宝', '已支付', '待发货', '2026-05-26 18:34:26', 28);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (7, 'ZD260826000001', 26, 3, 1, 289.00, 23.12, 265.88, 60, '支付宝', '已支付', '已发货', '2026-08-26 09:59:32', 26);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (8, 'ZD260719000001', 30, 13, 1, 128.00, 10.24, 117.76, 61, '支付宝', '已支付', '待发货', '2026-07-19 04:54:28', 30);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (9, 'ZD261005000001', 25, 18, 1, 420.00, 33.60, 386.40, 62, '微信', '已支付', '已完成', '2026-10-05 04:54:45', 25);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (10, 'ZD260714000001', 33, 1, 1, 780.00, 62.40, 717.60, 64, '支付宝', '已支付', '已完成', '2026-07-14 05:34:55', 33);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (11, 'ZD260816000001', 16, 18, 2, 840.00, 67.20, 772.80, 66, '支付宝', '已支付', '已发货', '2026-08-16 05:05:36', 16);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (12, 'ZD260908000001', 31, 11, 1, 690.00, 55.20, 634.80, 68, '储值卡', '已支付', '已发货', '2026-09-08 04:40:32', 31);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (13, 'ZD260726000001', 32, 1, 1, 780.00, 62.40, 717.60, 70, '微信', '已支付', '已发货', '2026-07-26 03:00:06', 32);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (14, 'ZD260820000001', 29, 8, 2, 920.00, 0.00, 920.00, NULL, '支付宝', '已支付', '已发货', '2026-08-20 10:35:06', 29);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (15, 'ZD260906000001', 13, 3, 1, 289.00, 0.00, 289.00, NULL, '储值卡', '已支付', '已发货', '2026-09-06 16:49:44', 13);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (16, 'ZD260926000001', 11, 10, 1, 159.00, 0.00, 159.00, NULL, '储值卡', '未支付', '待支付', '2026-09-26 19:58:29', 11);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (17, 'ZD261018000001', 27, 8, 1, 460.00, 0.00, 460.00, NULL, '储值卡', '已支付', '待发货', '2026-10-18 08:43:46', 27);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (18, 'ZD260607000001', 19, 9, 1, 460.00, 0.00, 460.00, NULL, '微信', '已支付', '已完成', '2026-06-07 19:57:51', 19);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (19, 'ZD260705000001', 31, 10, 2, 318.00, 0.00, 318.00, NULL, '支付宝', '未支付', '待支付', '2026-07-05 09:05:07', 31);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (20, 'ZD260930000001', 32, 6, 1, 198.00, 0.00, 198.00, NULL, '微信', '已支付', '待发货', '2026-09-30 09:29:53', 32);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (21, 'ZD260604000001', 20, 8, 1, 460.00, 0.00, 460.00, NULL, '微信', '已支付', '已完成', '2026-06-04 11:34:55', 20);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (22, 'ZD261017000001', 15, 4, 1, 1180.00, 0.00, 1180.00, NULL, '支付宝', '已支付', '已完成', '2026-10-17 18:00:50', 15);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (23, 'ZD260702000001', 11, 19, 1, 199.00, 0.00, 199.00, NULL, '支付宝', '已支付', '已完成', '2026-07-02 13:07:30', 11);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (24, 'ZD261028000001', 31, 1, 1, 780.00, 0.00, 780.00, NULL, '支付宝', '已支付', '已取消', '2026-10-28 17:02:52', 31);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (25, 'ZD260715000001', 30, 4, 2, 2360.00, 0.00, 2360.00, NULL, '微信', '已支付', '已完成', '2026-07-15 19:36:21', 30);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (26, 'ZD261004000001', 12, 20, 1, 129.00, 0.00, 129.00, NULL, '支付宝', '已支付', '已取消', '2026-10-04 08:41:52', 12);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (27, 'ZD260723000001', 12, 13, 2, 256.00, 0.00, 256.00, NULL, '微信', '已支付', '已完成', '2026-07-23 09:53:38', 12);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (28, 'ZD260917000001', 22, 17, 1, 79.00, 0.00, 79.00, NULL, '微信', '已支付', '已完成', '2026-09-17 10:54:33', 22);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (29, 'ZD260715000002', 30, 16, 2, 2360.00, 0.00, 2360.00, NULL, '微信', '已支付', '已取消', '2026-07-15 14:33:15', 30);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (30, 'ZD260819000002', 30, 10, 1, 159.00, 0.00, 159.00, NULL, '微信', '已支付', '已取消', '2026-08-19 12:45:08', 30);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (31, 'ZD260604000002', 31, 13, 1, 128.00, 0.00, 128.00, NULL, '支付宝', '已支付', '已发货', '2026-06-04 19:29:45', 31);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (32, 'ZD261016000001', 14, 6, 1, 198.00, 0.00, 198.00, NULL, '微信', '已支付', '已取消', '2026-10-16 15:02:52', 14);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (33, 'ZD260710000001', 21, 7, 1, 89.00, 0.00, 89.00, NULL, '储值卡', '已退款', '已退款', '2026-07-10 12:57:01', 21);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (34, 'ZD260710000002', 23, 1, 2, 1560.00, 0.00, 1560.00, NULL, '储值卡', '未支付', '待支付', '2026-07-10 20:59:55', 23);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (35, 'ZD260712000001', 31, 10, 1, 159.00, 0.00, 159.00, NULL, '微信', '已支付', '待发货', '2026-07-12 09:52:38', 31);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (36, 'ZD260919000001', 28, 12, 1, 298.00, 0.00, 298.00, NULL, '支付宝', '已支付', '已完成', '2026-09-19 10:03:23', 28);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (37, 'ZD260524000001', 15, 17, 1, 79.00, 0.00, 79.00, NULL, '微信', '已支付', '已取消', '2026-05-24 14:37:28', 15);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (38, 'ZD261029000001', 33, 17, 1, 79.00, 0.00, 79.00, NULL, '支付宝', '已退款', '已退款', '2026-10-29 09:05:42', 33);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (39, 'ZD260910000001', 15, 13, 2, 256.00, 0.00, 256.00, NULL, '支付宝', '已支付', '已完成', '2026-09-10 20:41:10', 15);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (40, 'ZD261015000001', 19, 13, 1, 128.00, 0.00, 128.00, NULL, '支付宝', '已支付', '已完成', '2026-10-15 15:04:22', 19);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (41, 'ZD260827000001', 14, 6, 1, 198.00, 0.00, 198.00, NULL, '储值卡', '已支付', '已发货', '2026-08-27 11:24:13', 14);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (42, 'ZD260906000002', 31, 5, 2, 536.00, 0.00, 536.00, NULL, '微信', '已退款', '已退款', '2026-09-06 19:31:39', 31);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (43, 'ZD260528000001', 12, 4, 1, 1180.00, 0.00, 1180.00, NULL, '储值卡', '未支付', '待支付', '2026-05-28 15:39:57', 12);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (44, 'ZD260813000001', 33, 2, 1, 920.00, 0.00, 920.00, NULL, '储值卡', '已支付', '已发货', '2026-08-13 13:49:40', 33);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (45, 'ZD260905000001', 23, 11, 2, 1380.00, 0.00, 1380.00, NULL, '储值卡', '已退款', '已退款', '2026-09-05 15:41:08', 23);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (46, 'ZD260919000002', 18, 12, 1, 298.00, 0.00, 298.00, NULL, '支付宝', '已支付', '待发货', '2026-09-19 21:11:18', 18);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (47, 'ZD260609000001', 22, 18, 1, 420.00, 0.00, 420.00, NULL, '微信', '已支付', '待发货', '2026-06-09 10:57:42', 22);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (48, 'ZD260518000001', 22, 17, 1, 79.00, 0.00, 79.00, NULL, '微信', '已支付', '待发货', '2026-05-18 21:46:30', 22);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (49, 'ZD260605000001', 32, 5, 1, 268.00, 0.00, 268.00, NULL, '微信', '已支付', '已完成', '2026-06-05 10:32:17', 32);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (50, 'ZD261030000001', 27, 2, 1, 920.00, 0.00, 920.00, NULL, '储值卡', '已支付', '已完成', '2026-10-30 11:20:46', 27);
INSERT INTO makeup_order (id, order_no, user_id, goods_id, buy_qty, goods_amount, discount_amount, pay_amount, source_apply_id, pay_type, pay_status, status, create_time, create_by) VALUES (51, 'ZD260726000002', 22, 17, 1, 79.00, 0.00, 79.00, NULL, '储值卡', '已支付', '已完成', '2026-07-26 20:30:46', 22);

-- 转化跟踪（46 条，一申领单一条）
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (1, 'ZH261026000001', 25, 32, 22, 0, 60.28, '中意向', NULL, '2026-11-26', '未跟进', '2026-10-27 21:31:55', 32);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (2, 'ZH261030000001', 26, 11, 18, 0, 55.72, '高意向', NULL, '2026-12-02', '已触达', '2026-11-02 05:00:35', 11);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (3, 'ZH261026000002', 27, 15, 0, 0, 55.00, '低意向', NULL, '2026-11-26', '未跟进', '2026-10-27 18:52:09', 15);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (4, 'ZH261028000001', 28, 29, 22, 0, 60.28, '中意向', NULL, '2026-11-28', '已触达', '2026-10-29 20:48:45', 29);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (5, 'ZH261028000002', 29, 14, 22, 0, 63.75, '中意向', NULL, '2026-11-30', '已触达', '2026-10-31 14:31:45', 14);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (6, 'ZH261029000001', 30, 28, 6, 0, 47.85, '低意向', NULL, '2026-11-29', '未跟进', '2026-10-30 17:25:46', 28);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (7, 'ZH261025000001', 31, 31, 22, 2, 62.08, '中意向', NULL, '2026-11-26', '未跟进', '2026-10-27 22:27:06', 31);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (8, 'ZH261030000002', 32, 23, 22, 2, 52.08, '中意向', NULL, '2026-12-02', '已触达', '2026-11-02 14:51:54', 23);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (9, 'ZH261026000003', 33, 23, 22, 1, 51.18, '中意向', NULL, '2026-11-26', '已触达', '2026-10-27 21:46:07', 23);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (10, 'ZH261025000002', 34, 26, 22, 1, 53.80, '中意向', NULL, '2026-11-27', '未跟进', '2026-10-28 23:27:08', 26);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (11, 'ZH261014000001', 35, 11, 26, 0, 79.10, '高意向', NULL, '2026-11-17', '未跟进', '2026-10-18 00:54:58', 11);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (12, 'ZH261027000001', 36, 14, 42, 1, 86.88, '高意向', NULL, '2026-11-30', '未跟进', '2026-10-31 01:23:56', 14);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (13, 'ZH261019000001', 37, 30, 58, 0, 95.05, '高意向', NULL, '2026-11-20', '已触达', '2026-10-21 23:17:36', 30);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (14, 'ZH261005000001', 38, 23, 12, 1, 67.38, '中意向', NULL, '2026-11-05', '已触达', '2026-10-06 22:12:21', 23);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (15, 'ZH261011000001', 39, 32, 42, 3, 84.38, '高意向', NULL, '2026-11-13', '未跟进', '2026-10-14 16:41:15', 32);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (16, 'ZH261005000002', 40, 26, 42, 1, 77.31, '高意向', NULL, '2026-11-06', '未跟进', '2026-10-07 03:21:56', 26);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (17, 'ZH261005000003', 41, 31, 0, 0, 40.48, '低意向', NULL, '2026-11-06', '已触达', '2026-10-07 21:50:43', 31);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (18, 'ZH261021000001', 42, 11, 0, 3, 63.10, '中意向', NULL, '2026-11-22', '未跟进', '2026-10-23 18:23:54', 11);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (19, 'ZH261009000001', 43, 24, 58, 1, 77.91, '高意向', NULL, '2026-11-11', '未跟进', '2026-10-12 02:45:22', 24);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (20, 'ZH261024000001', 44, 32, 34, 3, 81.86, '高意向', NULL, '2026-11-25', '已放弃', '2026-10-26 23:08:58', 32);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (21, 'ZH261013000001', 45, 11, 42, 1, 59.35, '中意向', NULL, '2026-11-15', '未跟进', '2026-10-16 00:40:24', 11);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (22, 'ZH261023000001', 46, 10, 0, 0, 55.00, '中意向', NULL, '2026-11-24', '未跟进', '2026-10-25 00:52:58', 10);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (23, 'ZH261024000002', 47, 16, 46, 0, 36.04, '低意向', NULL, '2026-11-24', '未跟进', '2026-10-25 12:24:41', 16);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (24, 'ZH261025000003', 48, 22, 72, 0, 66.55, '中意向', NULL, '2026-11-28', '已放弃', '2026-10-29 03:47:15', 22);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (25, 'ZH260614000001', 49, 29, 46, 1, 64.34, '中意向', 1, '2026-07-16', '已下单', '2026-06-16 10:37:58', 29);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (26, 'ZH260721000001', 50, 11, 0, 1, 47.62, '低意向', 2, '2026-08-23', '已下单', '2026-07-24 20:57:12', 11);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (27, 'ZH260620000001', 51, 21, 72, 2, 96.28, '高意向', 3, '2026-07-22', '已下单', '2026-06-22 16:52:12', 21);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (28, 'ZH260606000001', 52, 32, 6, 3, 86.83, '高意向', 4, '2026-07-09', '已下单', '2026-06-09 03:41:02', 32);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (29, 'ZH260607000001', 53, 17, 42, 1, 63.94, '中意向', 5, '2026-07-10', '已下单', '2026-06-10 01:09:58', 17);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (30, 'ZH260814000001', 54, 15, 58, 1, 81.56, '高意向', NULL, '2026-09-15', '未跟进', '2026-08-16 14:17:50', 15);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (31, 'ZH260516000001', 55, 28, 42, 4, 84.21, '高意向', 6, '2026-06-16', '已下单', '2026-05-17 18:34:26', 28);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (32, 'ZH260821000001', 56, 17, 6, 4, 55.90, '中意向', NULL, '2026-09-22', '已触达', '2026-08-23 17:47:27', 17);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (33, 'ZH260719000001', 57, 17, 42, 0, 60.14, '中意向', NULL, '2026-08-19', '未跟进', '2026-07-20 19:57:27', 17);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (34, 'ZH260602000001', 58, 24, 18, 1, 86.84, '高意向', NULL, '2026-07-04', '已放弃', '2026-06-04 21:19:04', 24);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (35, 'ZH261001000001', 59, 10, 58, 3, 96.62, '高意向', NULL, '2026-11-02', '已触达', '2026-10-03 18:13:14', 10);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (36, 'ZH260806000001', 60, 26, 34, 4, 92.72, '高意向', 7, '2026-09-07', '已下单', '2026-08-08 21:59:32', 26);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (37, 'ZH260620000002', 61, 30, 58, 0, 87.52, '高意向', 8, '2026-07-22', '已下单', '2026-06-22 18:54:28', 30);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (38, 'ZH260906000001', 62, 25, 46, 2, 93.80, '高意向', 9, '2026-10-10', '已下单', '2026-09-10 02:54:45', 25);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (39, 'ZH260713000001', 63, 14, 6, 0, 85.01, '高意向', NULL, '2026-08-13', '已触达', '2026-07-14 18:24:06', 14);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (40, 'ZH260628000001', 64, 33, 12, 0, 73.75, '中意向', 10, '2026-07-31', '已下单', '2026-07-01 20:34:55', 33);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (41, 'ZH260829000001', 65, 33, 0, 0, 65.84, '中意向', NULL, '2026-09-30', '已触达', '2026-08-31 14:58:18', 33);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (42, 'ZH260721000002', 66, 16, 72, 3, 79.28, '高意向', 11, '2026-08-23', '已下单', '2026-07-24 19:05:36', 16);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (43, 'ZH260909000001', 67, 15, 42, 1, 68.58, '中意向', NULL, '2026-10-11', '已触达', '2026-09-11 11:42:11', 15);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (44, 'ZH260827000001', 68, 31, 18, 3, 75.56, '高意向', 12, '2026-09-27', '已下单', '2026-08-28 18:40:32', 31);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (45, 'ZH260522000001', 69, 20, 58, 0, 95.52, '高意向', NULL, '2026-06-22', '未跟进', '2026-05-23 17:35:30', 20);
INSERT INTO convert_track (id, track_no, apply_id, user_id, browse_min, cart_times, convert_score, convert_level, order_id, attribution_end, follow_status, create_time, create_by) VALUES (46, 'ZH260704000001', 70, 32, 26, 2, 89.04, '高意向', 13, '2026-08-04', '已下单', '2026-07-05 20:00:06', 32);

-- 转化计算留痕（70 条，含高中低与无档案异常样本）
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (1, 'KP26102200001', 1, 25, 32, 10, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 0.00, 0.00, 22, 0, 35.20, 838.70, 0.00, 60.28, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；正装详情浏览不足 1 分钟，可推送成分测评内容；历史客单价与本品价格带偏差较大', 1, '2026-10-22 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (2, 'KP26101700002', 2, 26, 11, 14, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 0.00, 0.00, 18, 0, 28.80, 201.52, 84.04, 55.72, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；正装详情浏览不足 1 分钟，可推送成分测评内容', 1, '2026-10-17 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (3, 'KP26102900003', 3, 27, 15, 10, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 0.00, 0.00, 0, 0, 0.00, 505.00, 0.00, 55.00, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；正装详情浏览不足 1 分钟，可推送成分测评内容；历史客单价与本品价格带偏差较大', 1, '2026-10-29 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (4, 'KP26102300004', 4, 28, 29, 18, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 0.00, 0.00, 22, 0, 35.20, 1002.80, 0.00, 60.28, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；正装详情浏览不足 1 分钟，可推送成分测评内容；历史客单价与本品价格带偏差较大', 1, '2026-10-23 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (5, 'KP26102100005', 5, 29, 14, 15, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 0.00, 0.00, 22, 0, 35.20, 198.00, 34.67, 63.75, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；正装详情浏览不足 1 分钟，可推送成分测评内容；历史客单价与本品价格带偏差较大', 0, '2026-10-21 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (6, 'KP26101400006', 6, 30, 28, 15, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 0.00, 0.00, 6, 0, 9.60, 189.94, 34.07, 47.85, '低意向', '低成本触达：仅保留站内消息，不单独发券', '试用报告未提交，完整度记 0 分；正装详情浏览不足 1 分钟，可推送成分测评内容；历史客单价与本品价格带偏差较大', 0, '2026-10-14 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (7, 'KP26101900007', 7, 31, 31, 7, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 0.00, 0.00, 22, 2, 47.20, 425.97, 0.00, 62.08, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；历史客单价与本品价格带偏差较大', 0, '2026-10-19 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (8, 'KP26103100008', 8, 32, 23, 7, 3, 'V3', '完全匹配', 100.00, 60.00, 60.00, 0.00, 0.00, 22, 2, 47.20, 1470.00, 0.00, 52.08, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；历史客单价与本品价格带偏差较大', 0, '2026-10-31 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (9, 'KP26102400009', 9, 33, 23, 7, 3, 'V3', '完全匹配', 100.00, 60.00, 60.00, 0.00, 0.00, 22, 1, 41.20, 1470.00, 0.00, 51.18, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；历史客单价与本品价格带偏差较大', 0, '2026-10-24 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (10, 'KP26102800010', 10, 34, 26, 10, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 0.00, 0.00, 22, 1, 41.20, 265.88, 46.22, 53.80, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；历史客单价与本品价格带偏差较大', 0, '2026-10-28 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (11, 'KP26101600011', 11, 35, 11, 6, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 100.00, 100.00, 26, 0, 41.60, 201.52, 98.58, 79.10, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', NULL, 0, '2026-10-16 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (12, 'KP26102700012', 12, 36, 14, 11, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 83.00, 83.00, 42, 1, 73.20, 198.00, 42.96, 86.88, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', '历史客单价与本品价格带偏差较大', 0, '2026-10-27 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (13, 'KP26102400013', 13, 37, 30, 4, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 83.00, 83.00, 58, 0, 92.80, 1249.19, 95.31, 95.05, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', NULL, 0, '2026-10-24 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (14, 'KP26101800014', 14, 38, 23, 13, 3, 'V3', '完全匹配', 100.00, 60.00, 60.00, 93.00, 93.00, 12, 1, 25.20, 1470.00, 0.00, 67.38, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '正装详情浏览不足 1 分钟，可推送成分测评内容；历史客单价与本品价格带偏差较大', 0, '2026-10-18 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (15, 'KP26103100015', 15, 39, 32, 10, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 83.00, 83.00, 42, 3, 85.20, 838.70, 0.00, 84.38, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', '历史客单价与本品价格带偏差较大', 0, '2026-10-31 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (16, 'KP26102700016', 16, 40, 26, 1, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 93.00, 93.00, 42, 1, 73.20, 265.88, 47.27, 77.31, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', '历史客单价与本品价格带偏差较大', 0, '2026-10-27 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (17, 'KP26101600017', 17, 41, 31, 19, 3, 'V3', '不匹配', 0.00, 100.00, 100.00, 73.00, 73.00, 0, 0, 0.00, 425.97, 8.76, 40.48, '低意向', '低成本触达：仅保留站内消息，不单独发券', '正装详情浏览不足 1 分钟，可推送成分测评内容；历史客单价与本品价格带偏差较大', 0, '2026-10-16 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (18, 'KP26110200018', 18, 42, 11, 8, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 73.00, 73.00, 0, 3, 0.00, 201.52, 55.05, 63.10, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '正装详情浏览不足 1 分钟，可推送成分测评内容；历史客单价与本品价格带偏差较大', 0, '2026-11-02 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (19, 'KP26101700019', 19, 43, 24, 8, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 0.00, 0.00, 58, 1, 98.80, 569.87, 80.89, 77.91, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', '试用报告未提交，完整度记 0 分', 0, '2026-10-17 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (20, 'KP26110100020', 20, 44, 32, 7, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 80.00, 80.00, 34, 3, 72.40, 838.70, 0.00, 81.86, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', '历史客单价与本品价格带偏差较大', 0, '2026-11-01 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (21, 'KP26102000021', 21, 45, 11, 16, 3, 'V3', '不匹配', 0.00, 100.00, 100.00, 100.00, 100.00, 42, 1, 73.20, 201.52, 33.66, 59.35, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '历史客单价与本品价格带偏差较大', 0, '2026-10-20 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (22, 'KP26102200022', 22, 46, 10, 14, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 0.00, 0.00, 0, 0, 0.00, 806.82, 0.00, 55.00, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；正装详情浏览不足 1 分钟，可推送成分测评内容；历史客单价与本品价格带偏差较大', 0, '2026-10-22 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (23, 'KP26102900023', 23, 47, 16, 5, 3, 'V3', '不匹配', 0.00, 100.00, 100.00, 0.00, 0.00, 46, 0, 73.60, 772.80, 0.00, 36.04, '低意向', '低成本触达：仅保留站内消息，不单独发券', '试用报告未提交，完整度记 0 分；历史客单价与本品价格带偏差较大', 0, '2026-10-29 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (24, 'KP26102400024', 24, 48, 22, 3, 3, 'V3', '完全匹配', 100.00, 60.00, 60.00, 0.00, 0.00, 72, 0, 100.00, 164.25, 65.47, 66.55, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分', 0, '2026-10-24 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (25, 'KP26103100025', 25, 49, 29, 16, 3, 'V3', '不匹配', 0.00, 100.00, 100.00, 93.00, 93.00, 46, 1, 79.60, 1002.80, 87.99, 64.34, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', NULL, 0, '2026-10-31 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (26, 'KP26110100026', 26, 50, 11, 5, 3, 'V3', '不匹配', 0.00, 100.00, 100.00, 73.00, 73.00, 0, 1, 0.00, 201.52, 80.16, 47.62, '低意向', '低成本触达：仅保留站内消息，不单独发券', '正装详情浏览不足 1 分钟，可推送成分测评内容', 0, '2026-11-01 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (27, 'KP26102900027', 27, 51, 21, 7, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 83.00, 83.00, 72, 2, 100.00, 85.44, 96.80, 96.28, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', NULL, 0, '2026-10-29 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (28, 'KP26110200028', 28, 52, 32, 16, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 100.00, 100.00, 6, 3, 27.60, 838.70, 76.86, 86.83, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', '正装详情浏览不足 1 分钟，可推送成分测评内容', 0, '2026-11-02 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (29, 'KP26102200029', 29, 53, 17, 3, 3, 'V3', '无档案', 0.00, 100.00, 100.00, 93.00, 93.00, 42, 1, 73.20, 265.88, 93.60, 63.94, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '缺少肤质档案，建议先完成自测问卷', 0, '2026-10-22 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (30, 'KP26103100030', 30, 54, 15, 15, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 90.00, 90.00, 58, 1, 98.80, 505.00, 57.41, 81.56, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', '历史客单价与本品价格带偏差较大', 0, '2026-10-31 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (31, 'KP26101600031', 31, 55, 28, 7, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 73.00, 73.00, 42, 4, 91.20, 189.94, 9.27, 84.21, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', '历史客单价与本品价格带偏差较大', 0, '2026-10-16 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (32, 'KP26110100032', 32, 56, 17, 6, 3, 'V3', '无档案', 0.00, 100.00, 100.00, 93.00, 93.00, 6, 4, 33.60, 265.88, 72.57, 55.90, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '缺少肤质档案，建议先完成自测问卷；正装详情浏览不足 1 分钟，可推送成分测评内容', 0, '2026-11-01 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (33, 'KP26102600033', 33, 57, 17, 18, 3, 'V3', '无档案', 0.00, 100.00, 100.00, 90.00, 90.00, 42, 0, 67.20, 265.88, 70.64, 60.14, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '缺少肤质档案，建议先完成自测问卷', 0, '2026-10-26 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (34, 'KP26101500034', 34, 58, 24, 11, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 93.00, 93.00, 18, 1, 34.80, 860.42, 80.24, 86.84, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', '正装详情浏览不足 1 分钟，可推送成分测评内容', 0, '2026-10-15 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (35, 'KP26102400035', 35, 59, 10, 11, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 93.00, 93.00, 58, 3, 100.00, 860.42, 80.24, 96.62, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', NULL, 0, '2026-10-24 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (36, 'KP26101600036', 36, 60, 26, 3, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 83.00, 83.00, 34, 4, 78.40, 265.88, 93.60, 92.72, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', NULL, 0, '2026-10-16 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (37, 'KP26101500037', 37, 61, 30, 13, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 93.00, 93.00, 58, 0, 92.80, 1249.19, 0.00, 87.52, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', '历史客单价与本品价格带偏差较大', 0, '2026-10-15 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (38, 'KP26102500038', 38, 62, 25, 18, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 83.00, 83.00, 46, 2, 85.60, 386.40, 93.60, 93.80, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', NULL, 0, '2026-10-25 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (39, 'KP26101800039', 39, 63, 14, 14, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 100.00, 100.00, 6, 0, 9.60, 198.00, 85.71, 85.01, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', '正装详情浏览不足 1 分钟，可推送成分测评内容', 0, '2026-10-18 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (40, 'KP26102100040', 40, 64, 33, 1, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 100.00, 100.00, 12, 0, 19.20, 572.20, 78.69, 73.75, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '正装详情浏览不足 1 分钟，可推送成分测评内容', 0, '2026-10-21 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (41, 'KP26102900041', 41, 65, 33, 15, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 83.00, 83.00, 0, 0, 0.00, 572.20, 62.39, 65.84, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '正装详情浏览不足 1 分钟，可推送成分测评内容', 0, '2026-10-29 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (42, 'KP26102600042', 42, 66, 16, 18, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 90.00, 90.00, 72, 3, 100.00, 772.80, 32.80, 79.28, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', '历史客单价与本品价格带偏差较大', 0, '2026-10-26 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (43, 'KP26101800043', 43, 67, 15, 20, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 73.00, 73.00, 42, 1, 73.20, 505.00, 0.00, 68.58, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '历史客单价与本品价格带偏差较大', 0, '2026-10-18 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (44, 'KP26103000044', 44, 68, 31, 11, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 93.00, 93.00, 18, 3, 46.80, 425.97, 69.39, 75.56, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', NULL, 0, '2026-10-30 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (45, 'KP26102300045', 45, 69, 20, 8, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 83.00, 83.00, 58, 0, 92.80, 460.00, 100.00, 95.52, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', NULL, 0, '2026-10-23 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (46, 'KP26102000046', 46, 70, 32, 1, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 83.00, 83.00, 26, 2, 53.60, 838.70, 93.98, 89.04, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', NULL, 0, '2026-10-20 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (47, 'KP26101700047', 1, 25, 32, 10, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 0.00, 0.00, 22, 0, 35.20, 838.70, 0.00, 51.78, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；正装详情浏览不足 1 分钟，可推送成分测评内容；历史客单价与本品价格带偏差较大', 0, '2026-10-17 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (48, 'KP26101900048', 1, 25, 32, 10, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 0.00, 0.00, 22, 0, 35.20, 838.70, 0.00, 55.18, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；正装详情浏览不足 1 分钟，可推送成分测评内容；历史客单价与本品价格带偏差较大', 0, '2026-10-19 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (49, 'KP26101200049', 2, 26, 11, 14, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 0.00, 0.00, 18, 0, 28.80, 201.52, 84.04, 47.22, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；正装详情浏览不足 1 分钟，可推送成分测评内容', 0, '2026-10-12 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (50, 'KP26101400050', 2, 26, 11, 14, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 0.00, 0.00, 18, 0, 28.80, 201.52, 84.04, 50.62, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；正装详情浏览不足 1 分钟，可推送成分测评内容', 0, '2026-10-14 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (51, 'KP26102400051', 3, 27, 15, 10, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 0.00, 0.00, 0, 0, 0.00, 505.00, 0.00, 46.50, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；正装详情浏览不足 1 分钟，可推送成分测评内容；历史客单价与本品价格带偏差较大', 0, '2026-10-24 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (52, 'KP26102600052', 3, 27, 15, 10, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 0.00, 0.00, 0, 0, 0.00, 505.00, 0.00, 49.90, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；正装详情浏览不足 1 分钟，可推送成分测评内容；历史客单价与本品价格带偏差较大', 0, '2026-10-26 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (53, 'KP26101800053', 4, 28, 29, 18, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 0.00, 0.00, 22, 0, 35.20, 1002.80, 0.00, 51.78, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；正装详情浏览不足 1 分钟，可推送成分测评内容；历史客单价与本品价格带偏差较大', 0, '2026-10-18 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (54, 'KP26102000054', 4, 28, 29, 18, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 0.00, 0.00, 22, 0, 35.20, 1002.80, 0.00, 55.18, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；正装详情浏览不足 1 分钟，可推送成分测评内容；历史客单价与本品价格带偏差较大', 0, '2026-10-20 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (55, 'KP26101600055', 5, 29, 14, 15, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 0.00, 0.00, 22, 0, 35.20, 198.00, 34.67, 55.25, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；正装详情浏览不足 1 分钟，可推送成分测评内容；历史客单价与本品价格带偏差较大', 0, '2026-10-16 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (56, 'KP26101800056', 5, 29, 14, 15, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 0.00, 0.00, 22, 0, 35.20, 198.00, 34.67, 58.65, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；正装详情浏览不足 1 分钟，可推送成分测评内容；历史客单价与本品价格带偏差较大', 0, '2026-10-18 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (57, 'KP26100900057', 6, 30, 28, 15, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 0.00, 0.00, 6, 0, 9.60, 189.94, 34.07, 39.35, '低意向', '低成本触达：仅保留站内消息，不单独发券', '试用报告未提交，完整度记 0 分；正装详情浏览不足 1 分钟，可推送成分测评内容；历史客单价与本品价格带偏差较大', 0, '2026-10-09 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (58, 'KP26101100058', 6, 30, 28, 15, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 0.00, 0.00, 6, 0, 9.60, 189.94, 34.07, 42.75, '低意向', '低成本触达：仅保留站内消息，不单独发券', '试用报告未提交，完整度记 0 分；正装详情浏览不足 1 分钟，可推送成分测评内容；历史客单价与本品价格带偏差较大', 0, '2026-10-11 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (59, 'KP26101400059', 7, 31, 31, 7, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 0.00, 0.00, 22, 2, 47.20, 425.97, 0.00, 53.58, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；历史客单价与本品价格带偏差较大', 0, '2026-10-14 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (60, 'KP26101600060', 7, 31, 31, 7, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 0.00, 0.00, 22, 2, 47.20, 425.97, 0.00, 56.98, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；历史客单价与本品价格带偏差较大', 0, '2026-10-16 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (61, 'KP26102600061', 8, 32, 23, 7, 3, 'V3', '完全匹配', 100.00, 60.00, 60.00, 0.00, 0.00, 22, 2, 47.20, 1470.00, 0.00, 43.58, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；历史客单价与本品价格带偏差较大', 0, '2026-10-26 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (62, 'KP26102800062', 8, 32, 23, 7, 3, 'V3', '完全匹配', 100.00, 60.00, 60.00, 0.00, 0.00, 22, 2, 47.20, 1470.00, 0.00, 46.98, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；历史客单价与本品价格带偏差较大', 0, '2026-10-28 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (63, 'KP26101900063', 9, 33, 23, 7, 3, 'V3', '完全匹配', 100.00, 60.00, 60.00, 0.00, 0.00, 22, 1, 41.20, 1470.00, 0.00, 42.68, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；历史客单价与本品价格带偏差较大', 0, '2026-10-19 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (64, 'KP26102100064', 9, 33, 23, 7, 3, 'V3', '完全匹配', 100.00, 60.00, 60.00, 0.00, 0.00, 22, 1, 41.20, 1470.00, 0.00, 46.08, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；历史客单价与本品价格带偏差较大', 0, '2026-10-21 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (65, 'KP26102300065', 10, 34, 26, 10, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 0.00, 0.00, 22, 1, 41.20, 265.88, 46.22, 45.30, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；历史客单价与本品价格带偏差较大', 0, '2026-10-23 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (66, 'KP26102500066', 10, 34, 26, 10, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 0.00, 0.00, 22, 1, 41.20, 265.88, 46.22, 48.70, '中意向', '常规培育：推送使用教程与真实测评，7 天未下单转常规触达', '试用报告未提交，完整度记 0 分；历史客单价与本品价格带偏差较大', 0, '2026-10-25 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (67, 'KP26101100067', 11, 35, 11, 6, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 100.00, 100.00, 26, 0, 41.60, 201.52, 98.58, 70.60, '中意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', NULL, 0, '2026-10-11 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (68, 'KP26101300068', 11, 35, 11, 6, 3, 'V3', '部分匹配', 60.00, 100.00, 100.00, 100.00, 100.00, 26, 0, 41.60, 201.52, 98.58, 74.00, '中意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', NULL, 0, '2026-10-13 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (69, 'KP26102200069', 12, 36, 14, 11, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 83.00, 83.00, 42, 1, 73.20, 198.00, 42.96, 78.38, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', '历史客单价与本品价格带偏差较大', 0, '2026-10-22 02:00:11');
INSERT INTO convert_snapshot (id, snap_no, track_id, apply_id, user_id, goods_id, rule_id, rule_version, skin_match, skin_score, history_rate, history_score, report_complete, report_score, browse_min, cart_times, browse_score, avg_amount, order_score, total_score, convert_level, conclusion, unmet, correction_flag, calc_time) VALUES (70, 'KP26102400070', 12, 36, 14, 11, 3, 'V3', '完全匹配', 100.00, 100.00, 100.00, 83.00, 83.00, 42, 1, 73.20, 198.00, 42.96, 81.78, '高意向', '优先跟进：肤质适配且浏览充分，建议 24 小时内一对一触达并推送组合券', '历史客单价与本品价格带偏差较大', 0, '2026-10-24 02:00:11');

-- 人工修正（原快照保留，不被覆盖）
INSERT INTO convert_correction (id, snap_id, track_id, before_score, before_level, after_level, reason, oper_id, oper_name, oper_time) VALUES (1, 1, 1, 60.28, '中意向', '中意向', '用户反馈对酒精敏感，暂不推送正装', 6, '陈亦然', '2026-10-27 06:00:00');
INSERT INTO convert_correction (id, snap_id, track_id, before_score, before_level, after_level, reason, oper_id, oper_name, oper_time) VALUES (2, 2, 2, 55.72, '中意向', '高意向', '用户主动咨询成分表，购买意图明确', 6, '陈亦然', '2026-10-28 06:00:00');
INSERT INTO convert_correction (id, snap_id, track_id, before_score, before_level, after_level, reason, oper_id, oper_name, oper_time) VALUES (3, 3, 3, 55.00, '中意向', '低意向', '已连续两次未响应，转为低成本触达', 6, '陈亦然', '2026-10-29 06:00:00');
INSERT INTO convert_correction (id, snap_id, track_id, before_score, before_level, after_level, reason, oper_id, oper_name, oper_time) VALUES (4, 4, 4, 60.28, '中意向', '中意向', '近期刚完成正装购买，30 天内不重复触达', 6, '陈亦然', '2026-10-30 06:00:00');

-- 转化规则（3 个版本，V3 生效）
INSERT INTO convert_rule (id, rule_no, rule_name, rule_version, w_skin, w_history, w_report, w_browse, w_order, high_threshold, mid_threshold, status, effect_time, remark, create_by) VALUES (1, 'GZ2605100001', '初版五因子规则', 'V1', 35.00, 25.00, 15.00, 15.00, 10.00, 75.00, 50.00, '历史', '2026-05-10 00:00:00', '权重合计 100%', 1);
INSERT INTO convert_rule (id, rule_no, rule_name, rule_version, w_skin, w_history, w_report, w_browse, w_order, high_threshold, mid_threshold, status, effect_time, remark, create_by) VALUES (2, 'GZ2607010002', '报告完整度下调', 'V2', 35.00, 25.00, 15.00, 15.00, 10.00, 75.00, 50.00, '历史', '2026-07-01 00:00:00', '权重合计 100%', 1);
INSERT INTO convert_rule (id, rule_no, rule_name, rule_version, w_skin, w_history, w_report, w_browse, w_order, high_threshold, mid_threshold, status, effect_time, remark, create_by) VALUES (3, 'GZ2609010003', '当前生效版本', 'V3', 30.00, 25.00, 20.00, 15.00, 10.00, 75.00, 50.00, '生效', '2026-09-01 00:00:00', '权重合计 100%', 1);

-- 试用装出入库流水（84 条，before + change = after）
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (1, 'SL260503000001', 1, '入库', 500, 0, 500, 'RK260503001', 2, NULL, '2026-05-03 14:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (2, 'SL260701000001', 1, '派发', -1, 500, 499, 'SQ260628000001', 2, NULL, '2026-07-01 21:01:55');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (3, 'SL260509000001', 2, '入库', 400, 0, 400, 'RK260509002', 2, NULL, '2026-05-09 19:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (4, 'SL260515000001', 3, '入库', 800, 0, 800, 'RK260515003', 2, NULL, '2026-05-15 15:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (5, 'SL260610000001', 3, '派发', -1, 800, 799, 'SQ260607000001', 2, NULL, '2026-06-10 01:11:58');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (6, 'SL260808000001', 3, '派发', -1, 799, 798, 'SQ260806000001', 2, NULL, '2026-08-08 22:05:32');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (7, 'SL261029000001', 3, '派发', -1, 798, 797, 'SQ261025000003', 2, NULL, '2026-10-29 04:05:15');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (8, 'SL260521000001', 4, '入库', 300, 0, 300, 'RK260521004', 2, NULL, '2026-05-21 14:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (9, 'SL260630000001', 4, '退回', 2, 300, 302, NULL, 2, '用户拒收，包裹退回重新入库', '2026-06-30 11:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (10, 'SL260527000001', 5, '入库', 600, 0, 600, 'RK260527005', 2, NULL, '2026-05-27 19:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (11, 'SL260724000001', 5, '派发', -1, 600, 599, 'SQ260721000001', 2, NULL, '2026-07-24 21:18:12');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (12, 'SL261025000001', 5, '派发', -1, 599, 598, 'SQ261024000002', 2, NULL, '2026-10-25 12:43:41');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (13, 'SL260621000001', 5, '报损', -3, 598, 595, NULL, 2, '运输途中瓶身破损，无法派发', '2026-06-21 16:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (14, 'SL260602000001', 6, '入库', 500, 0, 500, 'RK260602006', 2, NULL, '2026-06-02 13:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (15, 'SL261021000001', 6, '过期核销', -120, 500, 380, NULL, 2, '批次有效期 2026-10-20 已过，按规核销', '2026-10-21 11:02:08');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (16, 'SL260823000001', 6, '派发', -1, 380, 379, 'SQ260821000001', 2, NULL, '2026-08-23 18:19:27');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (17, 'SL261018000001', 6, '派发', -1, 379, 378, 'SQ261014000001', 2, NULL, '2026-10-18 00:56:58');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (18, 'SL260608000001', 7, '入库', 700, 0, 700, 'RK260608007', 2, NULL, '2026-06-08 16:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (19, 'SL260517000001', 7, '派发', -1, 700, 699, 'SQ260516000001', 2, NULL, '2026-05-17 18:38:26');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (20, 'SL260622000001', 7, '派发', -1, 699, 698, 'SQ260620000001', 2, NULL, '2026-06-22 16:54:12');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (21, 'SL261027000001', 7, '派发', -1, 698, 697, 'SQ261026000005', 2, NULL, '2026-10-27 22:21:07');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (22, 'SL260614000001', 8, '入库', 380, 0, 380, 'RK260614008', 2, NULL, '2026-06-14 19:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (23, 'SL260523000001', 8, '派发', -1, 380, 379, 'SQ260522000001', 2, NULL, '2026-05-23 17:51:30');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (24, 'SL261012000001', 8, '派发', -1, 379, 378, 'SQ261009000001', 2, NULL, '2026-10-12 02:50:22');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (25, 'SL261023000001', 8, '派发', -1, 378, 377, 'SQ261021000001', 2, NULL, '2026-10-23 18:52:54');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (26, 'SL260724000002', 8, '退回', 2, 377, 379, NULL, 2, '用户拒收，包裹退回重新入库', '2026-07-24 16:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (27, 'SL260620000001', 9, '入库', 260, 0, 260, 'RK260620009', 2, NULL, '2026-06-20 21:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (28, 'SL260626000001', 10, '入库', 420, 0, 420, 'RK260626010', 2, NULL, '2026-06-26 20:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (29, 'SL261014000001', 10, '派发', -1, 420, 419, 'SQ261011000001', 2, NULL, '2026-10-14 17:07:15');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (30, 'SL261027000002', 10, '派发', -1, 419, 418, 'SQ261026000004', 2, NULL, '2026-10-27 19:03:09');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (31, 'SL260721000001', 10, '报损', -3, 418, 415, NULL, 2, '运输途中瓶身破损，无法派发', '2026-07-21 17:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (32, 'SL260702000001', 11, '入库', 320, 0, 320, 'RK260702011', 2, NULL, '2026-07-02 16:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (33, 'SL260604000001', 11, '派发', -1, 320, 319, 'SQ260602000002', 2, NULL, '2026-06-04 21:44:04');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (34, 'SL260828000001', 11, '派发', -1, 319, 318, 'SQ260827000001', 2, NULL, '2026-08-28 19:16:32');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (35, 'SL261003000001', 11, '派发', -1, 318, 317, 'SQ261001000001', 2, NULL, '2026-10-03 18:41:14');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (36, 'SL261031000001', 11, '派发', -1, 317, 316, 'SQ261027000004', 2, NULL, '2026-10-31 01:52:56');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (37, 'SL260708000001', 12, '入库', 280, 0, 280, 'RK260708012', 2, NULL, '2026-07-08 15:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (38, 'SL260817000001', 12, '退回', 2, 280, 282, NULL, 2, '用户拒收，包裹退回重新入库', '2026-08-17 12:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (39, 'SL260714000001', 13, '入库', 460, 0, 460, 'RK260714013', 2, NULL, '2026-07-14 21:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (40, 'SL261006000001', 13, '派发', -1, 460, 459, 'SQ261005000001', 2, NULL, '2026-10-06 22:34:21');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (41, 'SL260720000001', 14, '入库', 340, 0, 340, 'RK260720014', 2, NULL, '2026-07-20 19:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (42, 'SL260714000002', 14, '派发', -1, 340, 339, 'SQ260713000001', 2, NULL, '2026-07-14 18:45:06');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (43, 'SL261025000002', 14, '派发', -1, 339, 338, 'SQ261023000001', 2, NULL, '2026-10-25 01:19:58');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (44, 'SL261102000001', 14, '派发', -1, 338, 337, 'SQ261030000004', 2, NULL, '2026-11-02 05:18:35');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (45, 'SL260726000001', 15, '入库', 200, 0, 200, 'RK260726015', 2, NULL, '2026-07-26 20:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (46, 'SL260816000001', 15, '派发', -1, 200, 199, 'SQ260814000001', 2, NULL, '2026-08-16 14:20:50');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (47, 'SL260831000001', 15, '派发', -1, 199, 198, 'SQ260829000001', 2, NULL, '2026-08-31 15:26:18');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (48, 'SL261030000001', 15, '派发', -1, 198, 197, 'SQ261029000003', 2, NULL, '2026-10-30 17:45:46');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (49, 'SL261031000002', 15, '派发', -1, 197, 196, 'SQ261028000002', 2, NULL, '2026-10-31 14:54:45');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (50, 'SL260820000001', 15, '报损', -3, 196, 193, NULL, 2, '运输途中瓶身破损，无法派发', '2026-08-20 17:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (51, 'SL260801000001', 16, '入库', 260, 0, 260, 'RK260801016', 2, NULL, '2026-08-01 18:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (52, 'SL260616000001', 16, '派发', -1, 260, 259, 'SQ260614000001', 2, NULL, '2026-06-16 10:42:58');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (53, 'SL260910000001', 16, '退回', 2, 259, 261, NULL, 2, '用户拒收，包裹退回重新入库', '2026-09-10 15:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (54, 'SL260807000001', 17, '入库', 540, 0, 540, 'RK260807017', 2, NULL, '2026-08-07 16:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (55, 'SL260813000001', 18, '入库', 300, 0, 300, 'RK260813018', 2, NULL, '2026-08-13 21:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (56, 'SL260720000002', 18, '派发', -1, 300, 299, 'SQ260719000001', 2, NULL, '2026-07-20 20:27:27');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (57, 'SL260724000003', 18, '派发', -1, 299, 298, 'SQ260721000002', 2, NULL, '2026-07-24 19:25:36');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (58, 'SL260910000002', 18, '派发', -1, 298, 297, 'SQ260906000001', 2, NULL, '2026-09-10 03:28:45');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (59, 'SL261029000002', 18, '派发', -1, 297, 296, 'SQ261028000001', 2, NULL, '2026-10-29 20:54:45');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (60, 'SL260819000001', 19, '入库', 380, 0, 380, 'RK260819019', 2, NULL, '2026-08-19 21:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (61, 'SL261007000001', 19, '派发', -1, 380, 379, 'SQ261005000003', 2, NULL, '2026-10-07 22:22:43');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (62, 'SL260825000001', 20, '入库', 240, 0, 240, 'RK260825020', 2, NULL, '2026-08-25 13:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (63, 'SL260911000001', 20, '派发', -1, 240, 239, 'SQ260909000001', 2, NULL, '2026-09-11 12:03:11');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (64, 'SL261004000001', 20, '退回', 2, 239, 241, NULL, 2, '用户拒收，包裹退回重新入库', '2026-10-04 10:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (65, 'SL260919000001', 20, '报损', -3, 241, 238, NULL, 2, '运输途中瓶身破损，无法派发', '2026-09-19 10:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (66, 'SL260903000001', 21, '入库', 200, 0, 200, 'RK260903021', 2, NULL, '2026-09-03 11:29:22');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (67, 'SL260705000001', 21, '派发', -1, 200, 199, 'SQ260704000001', 2, NULL, '2026-07-05 20:37:06');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (68, 'SL261007000002', 21, '派发', -1, 199, 198, 'SQ261005000002', 2, NULL, '2026-10-07 03:24:56');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (69, 'SL260911000002', 22, '入库', 150, 0, 150, 'RK260911022', 2, NULL, '2026-09-11 20:34:04');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (70, 'SL261021000002', 22, '派发', -1, 150, 149, 'SQ261019000002', 2, NULL, '2026-10-21 23:50:36');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (71, 'SL260919000002', 23, '入库', 120, 0, 120, 'RK260919023', 2, NULL, '2026-09-19 17:54:40');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (72, 'SL261026000001', 23, '派发', -1, 120, 119, 'SQ261024000001', 2, NULL, '2026-10-26 23:20:58');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (73, 'SL261027000003', 23, '派发', -1, 119, 118, 'SQ261025000001', 2, NULL, '2026-10-27 22:50:06');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (74, 'SL261102000002', 23, '派发', -1, 118, 117, 'SQ261030000005', 2, NULL, '2026-11-02 15:00:54');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (75, 'SL260927000001', 24, '入库', 100, 0, 100, 'RK260927024', 2, NULL, '2026-09-27 22:48:38');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (76, 'SL261027000004', 24, '派发', -1, 100, 99, 'SQ261026000003', 2, NULL, '2026-10-27 21:56:55');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (77, 'SL261028000001', 24, '派发', -1, 99, 98, 'SQ261025000002', 2, NULL, '2026-10-28 23:37:08');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (78, 'SL261030000002', 24, '退回', 2, 98, 100, NULL, 2, '用户拒收，包裹退回重新入库', '2026-10-30 09:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (79, 'SL261005000001', 25, '入库', 80, 0, 80, 'RK261005025', 2, NULL, '2026-10-05 12:42:14');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (80, 'SL260622000002', 25, '派发', -1, 80, 79, 'SQ260620000002', 2, NULL, '2026-06-22 19:29:28');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (81, 'SL261025000003', 25, '报损', -3, 79, 76, NULL, 2, '运输途中瓶身破损，无法派发', '2026-10-25 09:00:00');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (82, 'SL261013000001', 26, '入库', 60, 0, 60, 'RK261013026', 2, NULL, '2026-10-13 21:32:58');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (83, 'SL260609000001', 26, '派发', -1, 60, 59, 'SQ260606000001', 2, NULL, '2026-06-09 04:14:02');
INSERT INTO sample_stock_log (id, log_no, sample_id, change_type, change_qty, before_qty, after_qty, biz_no, operator_id, remark, create_time) VALUES (84, 'SL261016000001', 26, '派发', -1, 59, 58, 'SQ261013000001', 2, NULL, '2026-10-16 00:55:24');

-- 站内消息
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (1, 17, '试用申领进度提醒', '你的「珀莱雅双抗精华 3.0」申领单 SQ261030000001 当前状态：待审核。', '系统通知', 'sample_apply', 1, 0, '2026-10-30 16:57:17');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (2, 10, '试用申领进度提醒', '你的「雅诗兰黛 DW 持妆粉底液」申领单 SQ261031000001 当前状态：待审核。', '系统通知', 'sample_apply', 2, 1, '2026-10-31 14:05:10');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (3, 32, '试用申领进度提醒', '你的「雅诗兰黛 DW 持妆粉底液」申领单 SQ261101000001 当前状态：待审核。', '系统通知', 'sample_apply', 3, 1, '2026-11-01 22:59:16');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (4, 25, '试用申领进度提醒', '你的「兰蔻极光淡斑精华」申领单 SQ261029000001 当前状态：待审核。', '系统通知', 'sample_apply', 4, 0, '2026-10-29 17:04:49');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (5, 13, '试用申领进度提醒', '你的「珀莱雅双抗精华 3.0」申领单 SQ261029000002 当前状态：待审核。', '系统通知', 'sample_apply', 5, 1, '2026-10-29 12:53:14');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (6, 15, '试用申领进度提醒', '你的「玉泽皮肤屏障修护面霜」申领单 SQ261031000002 当前状态：待审核。', '系统通知', 'sample_apply', 6, 1, '2026-10-31 22:49:45');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (7, 31, '试用申领进度提醒', '你的「修丽可 B5 保湿精华」申领单 SQ261101000002 当前状态：待审核。', '系统通知', 'sample_apply', 7, 0, '2026-11-01 14:34:46');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (8, 26, '试用申领进度提醒', '你的「至本倍润修护面霜」申领单 SQ261031000003 当前状态：待审核。', '系统通知', 'sample_apply', 8, 1, '2026-10-31 17:39:42');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (9, 21, '试用申领进度提醒', '你的「至本倍润修护面霜」申领单 SQ261030000002 当前状态：待审核。', '系统通知', 'sample_apply', 9, 1, '2026-10-30 23:35:31');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (10, 24, '试用申领进度提醒', '你的「兰蔻极光淡斑精华」申领单 SQ261019000001 当前状态：已驳回。', '系统通知', 'sample_apply', 10, 0, '2026-10-19 21:32:03');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (11, 22, '试用申领进度提醒', '你的「雅诗兰黛 DW 持妆粉底液」申领单 SQ261012000001 当前状态：已驳回。', '系统通知', 'sample_apply', 11, 1, '2026-10-12 11:36:01');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (12, 25, '试用申领进度提醒', '你的「玉泽屏障修护洁面乳」申领单 SQ260908000001 当前状态：已驳回。', '系统通知', 'sample_apply', 12, 1, '2026-09-08 14:21:37');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (13, 22, '试用申领进度提醒', '你的「修丽可 CE 复合修护精华」申领单 SQ260927000001 当前状态：已驳回。', '系统通知', 'sample_apply', 13, 0, '2026-09-27 16:40:59');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (14, 32, '试用申领进度提醒', '你的「玉泽屏障修护洁面乳」申领单 SQ260901000001 当前状态：已驳回。', '系统通知', 'sample_apply', 14, 1, '2026-09-01 10:05:56');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (15, 32, '试用申领进度提醒', '你的「玉泽皮肤屏障修护面霜」申领单 SQ261027000001 当前状态：已驳回。', '系统通知', 'sample_apply', 15, 1, '2026-10-27 19:20:52');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (16, 21, '试用申领进度提醒', '你的「玉泽屏障修护面膜」申领单 SQ260602000001 当前状态：已驳回。', '系统通知', 'sample_apply', 16, 0, '2026-06-02 21:41:28');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (17, 2, '待审核试用申领 9 单', '有 2 单已超过 24 小时未处理，请尽快审核。', '待办', NULL, NULL, 0, '2026-11-02 06:00:00');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (18, 3, '待审核试用申领 9 单', '有 2 单已超过 24 小时未处理，请尽快审核。', '待办', NULL, NULL, 0, '2026-11-02 06:00:00');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (19, 2, '试用装临期提醒', '玉泽 B006260322 批次 2026-10-20 到期，请及时核销或调拨。', '超时', 'sample_sku', 6, 0, '2026-11-01 13:00:00');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (20, 6, '高意向用户待跟进 12 人', '其中 4 人超过 24 小时未触达，请优先处理。', '待办', NULL, NULL, 0, '2026-11-02 02:00:00');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (21, 4, '报告待审核 18 份', '其中 3 份含过敏反馈，需重点核查症状描述。', '审核', NULL, NULL, 0, '2026-11-02 00:00:00');
INSERT INTO sys_message (id, receiver_id, title, content, msg_type, biz_type, biz_id, read_flag, create_time) VALUES (22, 8, '转化规则 V3 重算完成', '本次重算 128 条跟踪记录，高意向 12 人。', '系统通知', NULL, NULL, 1, '2026-11-01 03:00:00');

-- 操作日志
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (1, '申领审核', '审核', 'SQ261030000001', '状态 待审核 → 待审核', 2, '林佳', '2026-10-31 04:57:17', '10.12.6.2');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (2, '申领审核', '审核', 'SQ261031000001', '状态 待审核 → 待审核', 2, '林佳', '2026-11-01 07:05:10', '10.12.2.70');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (3, '申领审核', '审核', 'SQ261101000001', '状态 待审核 → 待审核', 2, '林佳', '2026-11-02 07:59:16', '10.12.5.228');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (4, '申领审核', '审核', 'SQ261029000001', '状态 待审核 → 待审核', 2, '林佳', '2026-10-30 11:04:49', '10.12.6.123');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (5, '申领审核', '审核', 'SQ261029000002', '状态 待审核 → 待审核', 2, '林佳', '2026-10-30 03:53:14', '10.12.1.180');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (6, '申领审核', '审核', 'SQ261031000002', '状态 待审核 → 待审核', 2, '林佳', '2026-11-01 09:49:45', '10.12.3.94');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (7, '申领审核', '审核', 'SQ261101000002', '状态 待审核 → 待审核', 2, '林佳', '2026-11-01 15:34:46', '10.12.5.210');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (8, '申领审核', '审核', 'SQ261031000003', '状态 待审核 → 待审核', 2, '林佳', '2026-10-31 20:39:42', '10.12.4.131');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (9, '申领审核', '审核', 'SQ261030000002', '状态 待审核 → 待审核', 2, '林佳', '2026-10-31 08:35:31', '10.12.4.55');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (10, '申领审核', '审核', 'SQ261019000001', '状态 待审核 → 已驳回', 2, '林佳', '2026-10-20 04:32:03', '10.12.3.247');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (11, '申领审核', '审核', 'SQ261012000001', '状态 待审核 → 已驳回', 2, '林佳', '2026-10-12 21:36:01', '10.12.4.104');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (12, '申领审核', '审核', 'SQ260908000001', '状态 待审核 → 已驳回', 2, '林佳', '2026-09-09 03:21:37', '10.12.5.49');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (13, '申领审核', '审核', 'SQ260927000001', '状态 待审核 → 已驳回', 2, '林佳', '2026-09-27 20:40:59', '10.12.3.208');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (14, '申领审核', '审核', 'SQ260901000001', '状态 待审核 → 已驳回', 2, '林佳', '2026-09-01 14:05:56', '10.12.5.56');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (15, '申领审核', '审核', 'SQ261027000001', '状态 待审核 → 已驳回', 2, '林佳', '2026-10-28 02:20:52', '10.12.5.96');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (16, '申领审核', '审核', 'SQ260602000001', '状态 待审核 → 已驳回', 2, '林佳', '2026-06-03 15:41:28', '10.12.6.61');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (17, '申领审核', '审核', 'SQ261026000001', '状态 待审核 → 待发放', 2, '林佳', '2026-10-27 10:13:59', '10.12.3.210');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (18, '申领审核', '审核', 'SQ261027000002', '状态 待审核 → 待发放', 2, '林佳', '2026-10-28 06:06:43', '10.12.2.165');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (19, '申领审核', '审核', 'SQ261026000002', '状态 待审核 → 待发放', 2, '林佳', '2026-10-27 04:51:17', '10.12.3.148');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (20, '申领审核', '审核', 'SQ261022000001', '状态 待审核 → 待发放', 2, '林佳', '2026-10-23 06:19:48', '10.12.2.10');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (21, '申领审核', '审核', 'SQ261030000003', '状态 待审核 → 待发放', 2, '林佳', '2026-10-31 03:21:53', '10.12.5.70');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (22, '申领审核', '审核', 'SQ261022000002', '状态 待审核 → 待发放', 2, '林佳', '2026-10-23 11:12:06', '10.12.6.50');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (23, '申领审核', '审核', 'SQ261101000003', '状态 待审核 → 待发放', 2, '林佳', '2026-11-02 02:47:40', '10.12.1.90');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (24, '申领审核', '审核', 'SQ261027000003', '状态 待审核 → 待发放', 2, '林佳', '2026-10-27 23:21:58', '10.12.2.13');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (25, '申领审核', '审核', 'SQ261026000003', '状态 待审核 → 已发放', 2, '林佳', '2026-10-26 14:31:55', '10.12.4.188');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (26, '申领审核', '审核', 'SQ261030000004', '状态 待审核 → 已发放', 2, '林佳', '2026-10-31 06:00:35', '10.12.3.250');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (27, '申领审核', '审核', 'SQ261026000004', '状态 待审核 → 已发放', 2, '林佳', '2026-10-26 19:52:09', '10.12.1.28');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (28, '申领审核', '审核', 'SQ261028000001', '状态 待审核 → 已发放', 2, '林佳', '2026-10-29 06:48:45', '10.12.4.184');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (29, '申领审核', '审核', 'SQ261028000002', '状态 待审核 → 已发放', 2, '林佳', '2026-10-28 14:31:45', '10.12.4.204');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (30, '申领审核', '审核', 'SQ261029000003', '状态 待审核 → 已发放', 2, '林佳', '2026-10-29 17:25:46', '10.12.6.102');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (31, '出入库登记', '入库', 'RK260503001', '入库 500 份，0 → 500', 2, '林佳', '2026-05-03 14:00:00', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (32, '出入库登记', '派发', 'SQ260628000001', '派发 -1 份，500 → 499', 2, '林佳', '2026-07-01 21:01:55', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (33, '出入库登记', '入库', 'RK260509002', '入库 400 份，0 → 400', 2, '林佳', '2026-05-09 19:00:00', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (34, '出入库登记', '入库', 'RK260515003', '入库 800 份，0 → 800', 2, '林佳', '2026-05-15 15:00:00', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (35, '出入库登记', '派发', 'SQ260607000001', '派发 -1 份，800 → 799', 2, '林佳', '2026-06-10 01:11:58', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (36, '出入库登记', '派发', 'SQ260806000001', '派发 -1 份，799 → 798', 2, '林佳', '2026-08-08 22:05:32', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (37, '出入库登记', '派发', 'SQ261025000003', '派发 -1 份，798 → 797', 2, '林佳', '2026-10-29 04:05:15', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (38, '出入库登记', '入库', 'RK260521004', '入库 300 份，0 → 300', 2, '林佳', '2026-05-21 14:00:00', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (39, '出入库登记', '退回', NULL, '退回 2 份，300 → 302', 2, '林佳', '2026-06-30 11:00:00', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (40, '出入库登记', '入库', 'RK260527005', '入库 600 份，0 → 600', 2, '林佳', '2026-05-27 19:00:00', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (41, '出入库登记', '派发', 'SQ260721000001', '派发 -1 份，600 → 599', 2, '林佳', '2026-07-24 21:18:12', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (42, '出入库登记', '派发', 'SQ261024000002', '派发 -1 份，599 → 598', 2, '林佳', '2026-10-25 12:43:41', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (43, '出入库登记', '报损', NULL, '报损 -3 份，598 → 595', 2, '林佳', '2026-06-21 16:00:00', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (44, '出入库登记', '入库', 'RK260602006', '入库 500 份，0 → 500', 2, '林佳', '2026-06-02 13:00:00', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (45, '出入库登记', '过期核销', NULL, '过期核销 -120 份，500 → 380', 2, '林佳', '2026-10-21 11:02:08', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (46, '出入库登记', '派发', 'SQ260821000001', '派发 -1 份，380 → 379', 2, '林佳', '2026-08-23 18:19:27', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (47, '出入库登记', '派发', 'SQ261014000001', '派发 -1 份，379 → 378', 2, '林佳', '2026-10-18 00:56:58', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (48, '出入库登记', '入库', 'RK260608007', '入库 700 份，0 → 700', 2, '林佳', '2026-06-08 16:00:00', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (49, '出入库登记', '派发', 'SQ260516000001', '派发 -1 份，700 → 699', 2, '林佳', '2026-05-17 18:38:26', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (50, '出入库登记', '派发', 'SQ260620000001', '派发 -1 份，699 → 698', 2, '林佳', '2026-06-22 16:54:12', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (51, '出入库登记', '派发', 'SQ261026000005', '派发 -1 份，698 → 697', 2, '林佳', '2026-10-27 22:21:07', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (52, '出入库登记', '入库', 'RK260614008', '入库 380 份，0 → 380', 2, '林佳', '2026-06-14 19:00:00', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (53, '出入库登记', '派发', 'SQ260522000001', '派发 -1 份，380 → 379', 2, '林佳', '2026-05-23 17:51:30', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (54, '出入库登记', '派发', 'SQ261009000001', '派发 -1 份，379 → 378', 2, '林佳', '2026-10-12 02:50:22', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (55, '出入库登记', '派发', 'SQ261021000001', '派发 -1 份，378 → 377', 2, '林佳', '2026-10-23 18:52:54', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (56, '出入库登记', '退回', NULL, '退回 2 份，377 → 379', 2, '林佳', '2026-07-24 16:00:00', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (57, '出入库登记', '入库', 'RK260620009', '入库 260 份，0 → 260', 2, '林佳', '2026-06-20 21:00:00', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (58, '出入库登记', '入库', 'RK260626010', '入库 420 份，0 → 420', 2, '林佳', '2026-06-26 20:00:00', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (59, '出入库登记', '派发', 'SQ261011000001', '派发 -1 份，420 → 419', 2, '林佳', '2026-10-14 17:07:15', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (60, '出入库登记', '派发', 'SQ261026000004', '派发 -1 份，419 → 418', 2, '林佳', '2026-10-27 19:03:09', '10.12.3.88');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (61, '规则计算', '计算', 'ZH261026000001', '转化分 60.28 · 中意向 · 规则 V3', 0, 'system', '2026-10-22 02:00:11', '127.0.0.1');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (62, '规则计算', '计算', 'ZH261030000001', '转化分 55.72 · 中意向 · 规则 V3', 0, 'system', '2026-10-17 02:00:11', '127.0.0.1');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (63, '规则计算', '计算', 'ZH261026000002', '转化分 55.00 · 中意向 · 规则 V3', 0, 'system', '2026-10-29 02:00:11', '127.0.0.1');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (64, '规则计算', '计算', 'ZH261028000001', '转化分 60.28 · 中意向 · 规则 V3', 0, 'system', '2026-10-23 02:00:11', '127.0.0.1');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (65, '规则计算', '计算', 'ZH261028000002', '转化分 63.75 · 中意向 · 规则 V3', 0, 'system', '2026-10-21 02:00:11', '127.0.0.1');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (66, '规则计算', '计算', 'ZH261029000001', '转化分 47.85 · 低意向 · 规则 V3', 0, 'system', '2026-10-14 02:00:11', '127.0.0.1');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (67, '规则计算', '计算', 'ZH261025000001', '转化分 62.08 · 中意向 · 规则 V3', 0, 'system', '2026-10-19 02:00:11', '127.0.0.1');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (68, '规则计算', '计算', 'ZH261030000002', '转化分 52.08 · 中意向 · 规则 V3', 0, 'system', '2026-10-31 02:00:11', '127.0.0.1');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (69, '规则计算', '计算', 'ZH261026000003', '转化分 51.18 · 中意向 · 规则 V3', 0, 'system', '2026-10-24 02:00:11', '127.0.0.1');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (70, '规则计算', '计算', 'ZH261025000002', '转化分 53.80 · 中意向 · 规则 V3', 0, 'system', '2026-10-28 02:00:11', '127.0.0.1');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (71, '规则计算', '计算', 'ZH261014000001', '转化分 79.10 · 高意向 · 规则 V3', 0, 'system', '2026-10-16 02:00:11', '127.0.0.1');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (72, '规则计算', '计算', 'ZH261027000001', '转化分 86.88 · 高意向 · 规则 V3', 0, 'system', '2026-10-27 02:00:11', '127.0.0.1');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (73, '人工修正', '修正', 'ZH261026000001', '中意向 60.28 → 中意向', 6, '陈亦然', '2026-10-27 06:00:00', '10.12.5.19');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (74, '人工修正', '修正', 'ZH261030000001', '中意向 55.72 → 高意向', 6, '陈亦然', '2026-10-28 06:00:00', '10.12.5.19');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (75, '人工修正', '修正', 'ZH261026000002', '中意向 55.00 → 低意向', 6, '陈亦然', '2026-10-29 06:00:00', '10.12.5.19');
INSERT INTO sys_oper_log (id, module, oper_type, biz_no, content, oper_id, oper_name, oper_time, ip) VALUES (76, '人工修正', '修正', 'ZH261028000001', '中意向 60.28 → 中意向', 6, '陈亦然', '2026-10-30 06:00:00', '10.12.5.19');

-- 公告
INSERT INTO sys_notice (id, title, content, publish_time, status, create_by) VALUES (1, '秋季换季修护专场开启', '9 月 1 日至 10 月 31 日，26 款修护类试用装开放申领，每款限领一次，报告通过后可获正装优惠券。', '2026-09-01 09:00:00', '已发布', 1);
INSERT INTO sys_notice (id, title, content, publish_time, status, create_by) VALUES (2, '试用报告填写规范更新', '自 9 月起，报告需包含使用天数、吸收感、温和度、回购意愿与不少于 30 字描述，含图片的报告在转化评分中权重更高。', '2026-09-05 10:30:00', '已发布', 1);
INSERT INTO sys_notice (id, title, content, publish_time, status, create_by) VALUES (3, '问卷 V2 上线说明', '肤质自测问卷升级至 V2，新增敏感程度与过敏成分两项，历史档案不重算。', '2026-08-20 14:00:00', '已发布', 1);

-- 文件元数据
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (1, 'goods-01.jpg', '/uploads/seed/goods/01.jpg', 292864, 'image/jpeg', 'goods', 1, 2, '2026-05-01 11:00:00');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (2, 'goods-02.jpg', '/uploads/seed/goods/02.jpg', 323584, 'image/jpeg', 'goods', 2, 2, '2026-05-07 16:00:00');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (3, 'goods-03.jpg', '/uploads/seed/goods/03.jpg', 235520, 'image/jpeg', 'goods', 3, 2, '2026-05-13 12:00:00');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (4, 'goods-04.jpg', '/uploads/seed/goods/04.jpg', 150528, 'image/jpeg', 'goods', 4, 2, '2026-05-19 11:00:00');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (5, 'goods-05.jpg', '/uploads/seed/goods/05.jpg', 233472, 'image/jpeg', 'goods', 5, 2, '2026-05-25 16:00:00');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (6, 'goods-06.jpg', '/uploads/seed/goods/06.jpg', 223232, 'image/jpeg', 'goods', 6, 2, '2026-05-31 10:00:00');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (7, 'goods-07.jpg', '/uploads/seed/goods/07.jpg', 281600, 'image/jpeg', 'goods', 7, 2, '2026-06-06 13:00:00');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (8, 'goods-08.jpg', '/uploads/seed/goods/08.jpg', 239616, 'image/jpeg', 'goods', 8, 2, '2026-06-12 16:00:00');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (9, 'goods-09.jpg', '/uploads/seed/goods/09.jpg', 379904, 'image/jpeg', 'goods', 9, 2, '2026-06-18 18:00:00');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (10, 'goods-10.jpg', '/uploads/seed/goods/10.jpg', 122880, 'image/jpeg', 'goods', 10, 2, '2026-06-24 17:00:00');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (11, 'goods-11.jpg', '/uploads/seed/goods/11.jpg', 200704, 'image/jpeg', 'goods', 11, 2, '2026-06-30 13:00:00');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (12, 'goods-12.jpg', '/uploads/seed/goods/12.jpg', 289792, 'image/jpeg', 'goods', 12, 2, '2026-07-06 12:00:00');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (13, 'report-01.jpg', '/uploads/seed/report/02.jpg', 362496, 'image/jpeg', 'report', 1, 11, '2026-10-29 06:54:58');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (14, 'report-02.jpg', '/uploads/seed/report/03.jpg', 237568, 'image/jpeg', 'report', 2, 14, '2026-11-02 05:23:56');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (15, 'report-03.jpg', '/uploads/seed/report/04.jpg', 243712, 'image/jpeg', 'report', 3, 30, '2026-10-31 00:17:36');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (16, 'report-04.jpg', '/uploads/seed/report/05.jpg', 390144, 'image/jpeg', 'report', 4, 23, '2026-10-22 23:12:21');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (17, 'report-05.jpg', '/uploads/seed/report/06.jpg', 377856, 'image/jpeg', 'report', 5, 32, '2026-11-01 18:41:15');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (18, 'report-06.jpg', '/uploads/seed/report/07.jpg', 179200, 'image/jpeg', 'report', 6, 26, '2026-10-25 09:21:56');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (19, 'report-07.jpg', '/uploads/seed/report/08.jpg', 210944, 'image/jpeg', 'report', 7, 31, '2026-10-23 22:50:43');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (20, 'report-08.jpg', '/uploads/seed/report/09.jpg', 202752, 'image/jpeg', 'report', 8, 11, '2026-10-26 19:23:54');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (21, 'report-09.jpg', '/uploads/seed/report/10.jpg', 375808, 'image/jpeg', 'report', 9, 32, '2026-11-01 23:08:58');
INSERT INTO sys_file (id, file_name, file_path, file_size, file_type, biz_type, biz_id, uploader_id, create_time) VALUES (22, 'report-10.jpg', '/uploads/seed/report/01.jpg', 393216, 'image/jpeg', 'report', 10, 11, '2026-10-24 06:40:24');

SET FOREIGN_KEY_CHECKS = 1;

-- 数据自检
SELECT '商品' AS t, COUNT(*) c FROM cosmetic_goods
UNION ALL SELECT '试用装', COUNT(*) FROM sample_sku
UNION ALL SELECT '申领', COUNT(*) FROM sample_apply
UNION ALL SELECT '报告', COUNT(*) FROM trial_report
UNION ALL SELECT '订单', COUNT(*) FROM makeup_order
UNION ALL SELECT '跟踪', COUNT(*) FROM convert_track
UNION ALL SELECT '快照', COUNT(*) FROM convert_snapshot
UNION ALL SELECT '流水', COUNT(*) FROM sample_stock_log
UNION ALL SELECT '账号', COUNT(*) FROM sys_user;
