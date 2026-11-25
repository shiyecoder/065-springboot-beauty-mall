package com.grad.beauty.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.beauty.entity.SkinProfile;
import org.apache.ibatis.annotations.Mapper;

/** skin_profile 数据访问，复杂统计走 XML 或注解 SQL。 */
@Mapper
public interface SkinProfileMapper extends BaseMapper<SkinProfile> {
}
