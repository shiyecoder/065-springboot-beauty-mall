package com.grad.beauty.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.beauty.entity.TrialReport;
import org.apache.ibatis.annotations.Mapper;

/** trial_report 数据访问，复杂统计走 XML 或注解 SQL。 */
@Mapper
public interface TrialReportMapper extends BaseMapper<TrialReport> {
}
