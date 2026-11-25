<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">试用效果报表</h3>
        <div class="page-sub">口径：报告审核通过时间归属自然日；未提交报告的申领单只计入发放量，不进转化率分母</div>
      </div>
      <div>
        <el-button :icon="Refresh" @click="load">刷新</el-button>
        <el-button type="primary" :icon="Download" @click="exportCsv">导出当前筛选</el-button>
      </div>
    </div>

    <div class="kpi-grid" style="grid-template-columns: repeat(5, 1fr)">
      <div class="kpi"><div class="lb">申领总量</div><div class="vl">{{ agg.apply }}<small>单</small></div></div>
      <div class="kpi"><div class="lb">平均通过率</div><div class="vl">{{ agg.approve }}<small>%</small></div></div>
      <div class="kpi"><div class="lb">报告提交率</div><div class="vl">{{ agg.report }}<small>%</small></div></div>
      <div class="kpi"><div class="lb">报告平均分</div><div class="vl">{{ agg.score }}<small>/5</small></div></div>
      <div class="kpi"><div class="lb">正装转化率</div><div class="vl">{{ agg.convert }}<small>%</small></div></div>
    </div>

    <div class="g2">
      <div class="card">
        <div class="card-hd">各商品试用转化率<span class="hint">点击条形可下钻</span></div>
        <Chart :option="convOpt" height="230px" />
      </div>
      <div class="card">
        <div class="card-hd">单次试用投入产出比（ROI）<span class="hint">转化销售额 ÷ 派发成本</span></div>
        <Chart :option="roiOpt" height="230px" />
      </div>
    </div>

    <div class="filter-bar">
      <el-input v-model="kw" placeholder="商品名称 / 品类" clearable style="width: 220px" />
      <el-select v-model="type" placeholder="全部品类" clearable style="width: 180px">
        <el-option v-for="t in TYPES" :key="t" :label="t" :value="t" />
      </el-select>
      <span class="muted" style="font-size: 12px; margin-left: auto">共 {{ filtered.length }} 个商品参与试用</span>
    </div>

    <div class="card">
      <el-table :data="paged" v-loading="loading" stripe show-summary :summary-method="summary">
        <el-table-column prop="goodsName" label="商品" min-width="180" show-overflow-tooltip />
        <el-table-column prop="goodsType" label="品类" width="80" />
        <el-table-column prop="skuCount" label="批次数" width="80" />
        <el-table-column prop="applyCount" label="申领" width="70" />
        <el-table-column label="通过率" width="90">
          <template #default="{ row }">{{ row.approveRate }}%</template>
        </el-table-column>
        <el-table-column prop="sentCount" label="发放单" width="80" />
        <el-table-column label="报告率" width="90">
          <template #default="{ row }">{{ row.reportRate }}%</template>
        </el-table-column>
        <el-table-column label="平均分" width="90">
          <template #default="{ row }">
            <b :style="{ color: row.avgScore < 3.5 ? 'var(--bt-bad)' : 'var(--bt-text)' }">{{ row.avgScore }}</b>
          </template>
        </el-table-column>
        <el-table-column label="转化率" width="90">
          <template #default="{ row }">{{ row.convertRate }}%</template>
        </el-table-column>
        <el-table-column label="派发成本" width="100">
          <template #default="{ row }">¥{{ row.cost }}</template>
        </el-table-column>
        <el-table-column label="转化销售额" width="110">
          <template #default="{ row }">¥{{ row.sales }}</template>
        </el-table-column>
        <el-table-column label="ROI" width="90">
          <template #default="{ row }">
            <span class="tag" :class="row.roi >= 100 ? 'ok' : row.roi > 0 ? 'warn' : 'info'">{{ row.roi }}</span>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next" :total="filtered.length"
                       v-model:current-page="page" :page-size="10" />
      </div>
    </div>

    <div class="card">
      <div class="card-hd">运营提示</div>
      <div class="note-box warn" v-if="badGoods.length">
        以下商品报告平均分低于 3.5，且差评集中在特定肤质，建议调整「适用肤质」标签或下架该批次：
        <b>{{ badGoods.map((g) => g.goodsName).join('、') }}</b>
      </div>
      <div class="note-box" v-else>当前无评分异常商品。</div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Refresh, Download } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import Chart from '../../components/Chart.vue'
import { statReport } from '../../api'

const TYPES = ['精华', '面霜', '洁面', '防晒', '面膜', '彩妆']
const rows = ref([])
const loading = ref(false)
const kw = ref('')
const type = ref('')
const page = ref(1)

const filtered = computed(() => rows.value.filter((r) =>
  (!kw.value || (r.goodsName || '').includes(kw.value) || (r.goodsType || '').includes(kw.value)) &&
  (!type.value || r.goodsType === type.value)
))
const paged = computed(() => filtered.value.slice((page.value - 1) * 10, page.value * 10))
const badGoods = computed(() => rows.value.filter((r) => r.avgScore > 0 && r.avgScore < 3.5).slice(0, 6))

const agg = computed(() => {
  const a = rows.value
  const n = a.length || 1
  const apply = a.reduce((s, r) => s + r.applyCount, 0)
  const sent = a.reduce((s, r) => s + r.sentCount, 0)
  const rep = a.reduce((s, r) => s + r.reportCount, 0)
  return {
    apply,
    approve: (a.reduce((s, r) => s + r.approveRate, 0) / n).toFixed(1),
    report: sent ? ((rep / sent) * 100).toFixed(1) : '0.0',
    score: (a.filter((r) => r.avgScore > 0).reduce((s, r) => s + r.avgScore, 0) / Math.max(1, a.filter((r) => r.avgScore > 0).length)).toFixed(2),
    convert: (a.reduce((s, r) => s + r.convertRate, 0) / n).toFixed(1)
  }
})

const top = computed(() => [...rows.value].sort((a, b) => b.applyCount - a.applyCount).slice(0, 7))

const convOpt = computed(() => ({
  grid: { left: 46, right: 20, top: 16, bottom: 46 },
  tooltip: { trigger: 'axis' },
  xAxis: {
    type: 'category',
    data: top.value.map((r) => r.goodsName.slice(0, 6)),
    axisLabel: { fontSize: 10, interval: 0, rotate: 22 }
  },
  yAxis: { type: 'value', max: 100, splitLine: { lineStyle: { color: '#f0edf6' } } },
  series: [{
    type: 'bar', barWidth: '50%',
    data: top.value.map((r) => r.convertRate),
    itemStyle: { color: '#7a5aa6', borderRadius: [4, 4, 0, 0] },
    label: { show: true, position: 'top', fontSize: 10, formatter: '{c}%' }
  }]
}))

const roiOpt = computed(() => {
  const t = [...rows.value].filter((r) => r.roi > 0).sort((a, b) => b.roi - a.roi).slice(0, 6)
  return {
    grid: { left: 52, right: 24, top: 16, bottom: 46 },
    tooltip: { trigger: 'axis' },
    xAxis: { type: 'category', data: t.map((r) => r.goodsName.slice(0, 6)), axisLabel: { fontSize: 10, interval: 0, rotate: 22 } },
    yAxis: { type: 'value', splitLine: { lineStyle: { color: '#f0edf6' } } },
    series: [{
      type: 'bar', barWidth: '50%',
      data: t.map((r) => r.roi),
      itemStyle: { color: '#e0b36a', borderRadius: [4, 4, 0, 0] },
      label: { show: true, position: 'top', fontSize: 10 }
    }]
  }
})

const summary = ({ columns }) => columns.map((c, i) => {
  if (i === 0) return '合计'
  const key = { 申领: 'applyCount', 发放单: 'sentCount' }[c.label]
  if (!key) return '-'
  return filtered.value.reduce((s, r) => s + (r[key] || 0), 0)
})

const exportCsv = () => {
  const head = ['商品', '品类', '申领', '通过率', '发放', '报告率', '平均分', '转化率', '成本', '销售额', 'ROI']
  const body = filtered.value.map((r) => [r.goodsName, r.goodsType, r.applyCount, r.approveRate, r.sentCount, r.reportRate, r.avgScore, r.convertRate, r.cost, r.sales, r.roi])
  const csv = [head, ...body].map((l) => l.join(',')).join('\n')
  const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8' })
  const a = document.createElement('a')
  a.href = URL.createObjectURL(blob)
  a.download = '试用效果报表.csv'
  a.click()
  ElMessage.success('已导出当前筛选项')
}

const load = async () => {
  loading.value = true
  try {
    rows.value = (await statReport()).data || []
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>
