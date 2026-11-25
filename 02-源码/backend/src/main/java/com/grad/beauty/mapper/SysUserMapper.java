package com.grad.beauty.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.beauty.entity.SysUser;
import org.apache.ibatis.annotations.Mapper;

/** sys_user 数据访问，复杂统计走 XML 或注解 SQL。 */
@Mapper
public interface SysUserMapper extends BaseMapper<SysUser> {
}
