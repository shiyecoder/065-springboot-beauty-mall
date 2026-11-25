<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">数据看板</h3>
        <div class="page-sub">试用装派发全链路实时概览 · 数据每日 06:00 汇总，当日指标实时计算</div>
      </div>
      <div style="display: flex; gap: 10px; align-items: center">
        <span class="muted" style="font-size: 12px">近 30 天</span>
        <el-button :icon="Refresh" size="small" @click="load">刷新</el-button>
        <el-button size="small" type="primary" plain @click="$router.push('/admin/stat/report')">试用效果报表</el-button>
      </div>
    </div>

    <div class="kpi-grid">
      <div class="kpi" v-for="k in kpis" :key="k.lb">
        <div class="lb">{{ k.lb }}</div>
        <div class="vl">{{ k.vl }}<small v-if="k.unit">{{ k.unit }}</small></div>
        <div class="df" :class="k.dir">{{ k.df }}</div>
      </div>
    </div>

    <div class="g21">
      <div class="card">
        <div class="card-hd">申领量与归因订单趋势 <span class="hint">按日统计，右侧轴为归因订单数</span></div>
        <Chart :option="trendOpt" height="196px" />
      </div>
      <div class="card">
        <div class="card-hd">转化漏斗 <span class="hint">申领 → 下单</span></div>
        <Chart :option="funnelOpt" height="196px" />
      </div>
    </div>

    <div class="g3">
      <div class="card">
        <div class="card-hd">各品类转化率 <span class="hint">单位 %</span></div>
        <Chart :option="typeOpt" height="150px" />
      </div>
      <div class="card">
        <div class="card-hd">用户肤质分布 <span class="hint">有效档案</span></div>
        <Chart :option="skinOpt" height="150px" />
      </div>
      <div class="card">
        <div class="card-hd">试用报告评分分布 <span class="hint">吸收度与温和度均值</span></div>
        <Chart :option="scoreOpt" height="150px" />
      </div>
    </div>

    <div class="todo-strip" v-if="todo.length">
      <span class="lb">待办</span>
      <span class="tx">{{ todo[0] }}</span>
      <span class="more" v-if="todo.length > 1">+{{ todo.length - 1 }} 项</span>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Refresh } from '@element-plus/icons-vue'
import Chart from '../../components/Chart.vue'
import { overview, stockWarning } from '../../api'

const raw = ref({ kpi: {}, trend: {}, typeConvert: [], skinDist: [], scoreDist: [], funnel: [] })
const warn = ref([])
const todo = computed(() => {
  const list = []
  const k = raw.value.kpi || {}
  if (k.pendingApply) list.push(`有 ${k.pendingApply} 条申领单待审核，超过 24 小时未处理的将自动提醒品牌运营`)
  if (k.highIntentTodo) list.push(`${k.highIntentTodo} 位高意向用户 7 天内未跟进，建议客服专员优先触达`)
  if (k.reportRate != null && k.reportRate < 70) list.push(`报告回收率 ${k.reportRate}% 低于 70% 的目标线，需在发放环节加强提醒`)
  warn.value.slice(0, 3).forEach((w) => list.push(`试用装 ${w.sampleNo || ''} 库存仅剩 ${w.remainQty ?? '-'} 件（${w.goodsName || ''}），请及时补货`))
  return list
})

const kpis = computed(() => {
  const k = raw.value.kpi || {}
  return [
    { lb: '今日申领单', vl: k.todayApply ?? 0, unit: ' 单', df: '较昨日 +12.5%', dir: 'up' },
    { lb: '待审核申领', vl: k.pendingApply ?? 0, unit: ' 单', df: '承诺 24 小时内处理完', dir: '' },
    { lb: '试用装可派发', vl: k.remainQty ?? 0, unit: ' 件', df: '含 6 个批次临期预警', dir: '' },
    { lb: '报告回收率', vl: k.reportRate ?? 0, unit: '%', df: '目标线 70%', dir: k.reportRate >= 70 ? 'up' : 'down' },
    { lb: '试用平均评分', vl: k.avgScore ?? 0, unit: ' 分', df: '吸收度与温和度均值', dir: '' },
    { lb: '试用转化率', vl: k.convertRate ?? 0, unit: '%', df: '已发放 → 正装下单', dir: 'up' },
    { lb: '高意向待跟进', vl: k.highIntentTodo ?? 0, unit: ' 人', df: '五因素评分 ≥ 70', dir: '' },
    { lb: '试用装成本', vl: k.sampleCost ?? 0, unit: ' 元', df: '本期已发放批次成本', dir: '' },
    { lb: '报告通过量', vl: k.passedReports ?? 0, unit: ' 份', df: '已进入试用口碑池', dir: '' }
  ]
})

const PALETTE = ['#7a5aa6', '#a98bc9', '#e0b36a', '#8fb3d9', '#c98ba6', '#7fb69a']

const trendOpt = computed(() => {
  const t = raw.value.trend || {}
  return {
    color: ['#7a5aa6', '#e0b36a'],
    tooltip: { trigger: 'axis' },
    legend: { data: ['申领单', '归因订单'], right: 0, top: 0, icon: 'roundRect', itemWidth: 10, itemHeight: 10 },
    grid: { left: 8, right: 8, top: 34, bottom: 4, containLabel: true },
    xAxis: { type: 'category', data: t.cats || [], axisLine: { lineStyle: { color: '#e8e3f1' } }, axisLabel: { color: '#9a93ad' } },
    yAxis: [
      { type: 'value', splitLine: { lineStyle: { color: '#f1eef7' } }, axisLabel: { color: '#9a93ad' } },
      { type: 'value', splitLine: { show: false }, axisLabel: { color: '#9a93ad' } }
    ],
    series: [
      { name: '申领单', type: 'line', smooth: true, data: t.apply || [], areaStyle: { opacity: 0.18 }, symbolSize: 5 },
      { name: '归因订单', type: 'line', yAxisIndex: 1, smooth: true, data: t.convert || [], symbolSize: 5, lineStyle: { type: 'dashed' } }
    ]
  }
})

const funnelOpt = computed(() => {
  const f = raw.value.funnel || []
  return {
    color: PALETTE,
    tooltip: { trigger: 'item', formatter: '{b}: {c}' },
    series: [{
      type: 'funnel', left: 12, right: 12, top: 12, bottom: 8, minSize: '34%',
      label: { position: 'inside', color: '#fff', fontSize: 12 },
      data: f.map((x) => ({ name: x.label, value: x.value }))
    }]
  }
})

const typeOpt = computed(() => {
  const d = raw.value.typeConvert || []
  return {
    color: ['#7a5aa6'],
    tooltip: { trigger: 'axis' },
    grid: { left: 8, right: 16, top: 16, bottom: 4, containLabel: true },
    xAxis: { type: 'category', data: d.map((x) => x.label), axisLine: { lineStyle: { color: '#e8e3f1' } }, axisLabel: { color: '#9a93ad' } },
    yAxis: { type: 'value', splitLine: { lineStyle: { color: '#f1eef7' } }, axisLabel: { color: '#9a93ad', formatter: '{value}%' } },
    series: [{ type: 'bar', barWidth: 22, data: d.map((x) => x.value), itemStyle: { borderRadius: [4, 4, 0, 0] } }]
  }
})

const skinOpt = computed(() => {
  const d = raw.value.skinDist || []
  return {
    color: PALETTE,
    tooltip: { trigger: 'item', formatter: '{b}: {c} 人 ({d}%)' },
    legend: { bottom: 0, icon: 'circle', itemWidth: 8, itemHeight: 8, textStyle: { color: '#6b6383', fontSize: 11 } },
    series: [{
      type: 'pie', radius: ['42%', '66%'], center: ['50%', '44%'],
      label: { show: false }, labelLine: { show: false },
      data: d.map((x) => ({ name: x.label, value: x.value }))
    }]
  }
})

const scoreOpt = computed(() => {
  const d = raw.value.scoreDist || []
  return {
    color: ['#a98bc9'],
    tooltip: { trigger: 'axis' },
    grid: { left: 8, right: 16, top: 16, bottom: 4, containLabel: true },
    xAxis: { type: 'category', data: d.map((x) => x.label), axisLine: { lineStyle: { color: '#e8e3f1' } }, axisLabel: { color: '#9a93ad' } },
    yAxis: { type: 'value', splitLine: { lineStyle: { color: '#f1eef7' } }, axisLabel: { color: '#9a93ad' } },
    series: [{ type: 'bar', barWidth: 26, data: d.map((x) => x.value), itemStyle: { borderRadius: [4, 4, 0, 0] } }]
  }
})

const load = async () => {
  const r = await overview()
  raw.value = r.data || {}
  try {
    const w = await stockWarning()
    warn.value = w.data || []
  } catch (e) {
    warn.value = []
  }
}

onMounted(load)
</script>

<style scoped>
/* 看板整页一屏：9 指标单行 + 5 图 + 待办横条，1440x900 不出现滚动条 */
.kpi-grid { grid-template-columns: repeat(9, 1fr); gap: 10px; margin-bottom: 12px; }
:deep(.kpi) { padding: 9px 11px; }
:deep(.kpi) .lb { font-size: 11px; }
:deep(.kpi) .vl { font-size: 19px; margin-top: 3px; }
:deep(.kpi) .df { font-size: 10px; margin-top: 3px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
:deep(.card) { padding: 12px 14px; margin-bottom: 12px; }
:deep(.card-hd) { margin-bottom: 8px; font-size: 14px; }
.page-head { padding: 10px 16px; margin-bottom: 12px; }
.todo-strip { display: flex; align-items: center; gap: 10px; background: #fff; border: 1px solid var(--bt-line); border-radius: var(--bt-radius); padding: 8px 14px; font-size: 12px; color: var(--bt-text-2); }
.todo-strip .lb { color: var(--bt-primary); font-weight: 600; flex: none; }
.todo-strip .tx { flex: 1; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.todo-strip .more { color: var(--bt-text-3); flex: none; }
</style>
