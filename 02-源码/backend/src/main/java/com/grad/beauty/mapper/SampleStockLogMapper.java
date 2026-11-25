package com.grad.beauty.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.beauty.entity.SampleStockLog;
import org.apache.ibatis.annotations.Mapper;

/** sample_stock_log 数据访问，复杂统计走 XML 或注解 SQL。 */
@Mapper
public interface SampleStockLogMapper extends BaseMapper<SampleStockLog> {
}
