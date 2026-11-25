package com.grad.beauty.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.beauty.entity.SysFile;
import org.apache.ibatis.annotations.Mapper;

/** sys_file 数据访问，复杂统计走 XML 或注解 SQL。 */
@Mapper
public interface SysFileMapper extends BaseMapper<SysFile> {
}
