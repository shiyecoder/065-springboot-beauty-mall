package com.grad.beauty.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.beauty.entity.SysMenu;
import org.apache.ibatis.annotations.Mapper;

/** sys_menu 数据访问，复杂统计走 XML 或注解 SQL。 */
@Mapper
public interface SysMenuMapper extends BaseMapper<SysMenu> {
}
