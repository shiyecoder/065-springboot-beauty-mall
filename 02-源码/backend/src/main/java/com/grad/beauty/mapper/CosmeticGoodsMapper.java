package com.grad.beauty.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.beauty.entity.CosmeticGoods;
import org.apache.ibatis.annotations.Mapper;

/** cosmetic_goods 数据访问，复杂统计走 XML 或注解 SQL。 */
@Mapper
public interface CosmeticGoodsMapper extends BaseMapper<CosmeticGoods> {
}
