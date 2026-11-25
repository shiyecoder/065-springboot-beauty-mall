package com.grad.beauty.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.beauty.entity.ConvertRule;
import org.apache.ibatis.annotations.Mapper;

/** convert_rule 数据访问，复杂统计走 XML 或注解 SQL。 */
@Mapper
public interface ConvertRuleMapper extends BaseMapper<ConvertRule> {
}
