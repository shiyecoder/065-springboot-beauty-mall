<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">转化看板</h3>
        <div class="page-sub">
          归因窗口为发放后 30 天，转化概率每日重算；当前规则 {{ b.ruleVersion || '-' }}（生效 {{ fmt(b.ruleEffectTime) }}）
        </div>
      </div>
      <div>
        <el-button :icon="Refresh" @click="load">刷新</el-button>
        <el-button type="primary" @click="$router.push('/admin/convert/rule')">规则配置</el-button>
      </div>
    </div>

    <div class="lv-cols">
      <div class="lv high" @click="go('高意向')">
        <div class="lv-lb">高意向（≥75 分）</div>
        <div class="lv-n">{{ b.high ?? 0 }}</div>
        <div class="lv-d">24 小时内一对一跟进 · 待触达 <b>{{ b.highToTouch ?? 0 }}</b> 人</div>
      </div>
      <div class="lv mid" @click="go('中意向')">
        <div class="lv-lb">中意向（50–74 分）</div>
        <div class="lv-n">{{ b.mid ?? 0 }}</div>
        <div class="lv-d">3 天内推送教程与测评 · 7 天未下单转常规</div>
      </div>
      <div class="lv low" @click="go('低意向')">
        <div class="lv-lb">低意向（&lt;50 分）</div>
        <div class="lv-n">{{ b.low ?? 0 }}</div>
        <div class="lv-d">仅站内消息触达 · 不单独发券</div>
      </div>
      <div class="lv eff">
        <div class="lv-lb">规则效果</div>
        <div class="eff-row"><span>推荐采纳率</span><b>{{ b.adoptRate ?? 0 }}%</b></div>
        <div class="eff-row"><span>人工修正率</span><b>{{ b.correctionRate ?? 0 }}%</b></div>
        <div class="eff-row"><span>已下单 / 总跟踪</span><b>{{ b.ordered ?? 0 }} / {{ b.total ?? 0 }}</b></div>
      </div>
    </div>

    <div class="g21">
      <div class="card">
        <div class="card-hd">试用转化漏斗<span class="hint">发放 → 浏览 → 加购 → 下单 → 支付</span></div>
        <Chart :option="funnelOpt" height="228px" />
      </div>
      <div class="card">
        <div class="card-hd">意向分布<span class="hint">按分数区间</span></div>
        <Chart :option="distOpt" height="228px" />
      </div>
    </div>

    <div class="card">
      <div class="card-hd">
        高意向待跟进名单
        <span class="hint">客服需在 24 小时内触达，登记跟进结果后自动流转</span>
      </div>
      <el-table :data="todo" v-loading="loading" stripe size="small">
        <el-table-column label="用户" width="140">
          <template #default="{ row }">
            <div style="font-weight: 600">{{ row.userName }}</div>
            <div class="muted" style="font-size: 11px">{{ row.trackNo }}</div>
          </template>
        </el-table-column>
        <el-table-column prop="goodsName" label="试用商品" min-width="180" show-overflow-tooltip />
        <el-table-column label="浏览 / 加购" width="120">
          <template #default="{ row }">{{ row.browseMin }} 分钟 / {{ row.cartTimes }} 次</template>
        </el-table-column>
        <el-table-column label="转化分" width="110">
          <template #default="{ row }">
            <div class="score-cell">
              <b>{{ row.convertScore }}</b>
              <span class="tag" :class="row.convertLevel === '高意向' ? 'ok' : row.convertLevel === '中意向' ? 'warn' : 'info'">{{ row.convertLevel }}</span>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="归因窗口" width="150">
          <template #default="{ row }">
            <span :class="row.inWindow ? 'tag ok' : 'tag info'">{{ row.inWindow ? '窗口内' : '已超窗' }}</span>
            <div class="muted" style="font-size: 11px">至 {{ row.attributionEnd }}</div>
          </template>
        </el-table-column>
        <el-table-column prop="followStatus" label="跟进状态" width="100" />
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="$router.push({ path: '/admin/convert/follow', query: { id: row.id } })">跟进</el-button>
            <el-button link type="primary" @click="openScore(row)">算分明细</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <el-drawer v-model="drawer" title="转化概率计算明细" size="520px">
      <div v-if="sc">
        <div class="sc-head">
          <div>
            <div class="muted" style="font-size: 12px">{{ sc.snapNo }} · 规则 {{ sc.ruleVersion }}</div>
            <div class="sc-total">{{ sc.totalScore }}<small>分</small></div>
          </div>
          <span class="tag" :class="sc.level === '高意向' ? 'ok' : sc.level === '中意向' ? 'warn' : 'info'" style="font-size: 13px">{{ sc.level }}</span>
        </div>
        <div class="note-box" style="margin: 14px 0">{{ sc.conclusion }}</div>
        <div class="dt-sec">五因素明细</div>
        <div v-for="f in sc.factors" :key="f.name" class="ft">
          <div class="ft-h"><span>{{ f.name }}</span><span class="muted">权重 {{ f.weight }}%</span></div>
          <div class="ft-bar"><i :style="{ width: Math.min(100, f.score) + '%' }"></i></div>
          <div class="ft-d"><span class="muted">{{ f.detail }}</span><b>{{ f.score }} 分 → 加权 {{ f.weighted }}</b></div>
        </div>
        <div class="dt-sec">未满足条件</div>
        <div v-if="!sc.unmet || !sc.unmet.length" class="muted" style="font-size: 12px">无，数据完整可直接采纳结论</div>
        <div v-for="(u, i) in sc.unmet || []" :key="i" class="note-box warn" style="margin-bottom: 8px">{{ u }}</div>
      </div>
      <template #footer>
        <el-button @click="drawer = false">关闭</el-button>
        <el-button type="primary" @click="$router.push('/admin/convert/follow')">去跟进</el-button>
      </template>
    </el-drawer>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Refresh } from '@element-plus/icons-vue'
import { useRouter } from 'vue-router'
import Chart from '../../components/Chart.vue'
import { convertBoard, trackPage, trackScore } from '../../api'

const router = useRouter()
const b = ref({})
const todo = ref([])
const loading = ref(false)
const drawer = ref(false)
const sc = ref(null)

const funnelOpt = computed(() => ({
  grid: { left: 60, right: 30, top: 12, bottom: 10 },
  tooltip: { trigger: 'item' },
  series: [{
    type: 'funnel', left: '6%', width: '88%', minSize: '32%', gap: 2,
    label: { position: 'inside', formatter: '{b} {c}', color: '#fff', fontSize: 11 },
    itemStyle: { borderWidth: 0 },
    data: (b.value.funnel || []).map((x, i) => ({
      name: x.label, value: x.value,
      itemStyle: { color: ['#7a5aa6', '#9377b8', '#ab93c8', '#c4b0d8', '#e0b36a'][i % 5] }
    }))
  }]
}))

const distOpt = computed(() => ({
  grid: { left: 40, right: 16, top: 16, bottom: 30 },
  tooltip: { trigger: 'axis' },
  xAxis: { type: 'category', data: (b.value.dist || []).map((x) => x.label), axisLabel: { fontSize: 10 } },
  yAxis: { type: 'value', splitLine: { lineStyle: { color: '#f0edf6' } } },
  series: [{
    type: 'bar', barWidth: '52%',
    data: (b.value.dist || []).map((x) => x.value),
    itemStyle: { color: '#a98bc9', borderRadius: [4, 4, 0, 0] }
  }]
}))

const load = async () => {
  loading.value = true
  try {
    const [r1, r2] = await Promise.all([
      convertBoard(),
      trackPage({ page: 1, size: 8, level: '高意向', followStatus: '未跟进' })
    ])
    b.value = r1.data || {}
    todo.value = r2.data.records || []
  } finally {
    loading.value = false
  }
}
const openScore = async (row) => {
  sc.value = (await trackScore(row.id)).data
  drawer.value = true
}
const go = (level) => router.push({ path: '/admin/convert/follow', query: { level } })
const fmt = (t) => (t ? String(t).replace('T', ' ').slice(0, 10) : '-')

onMounted(load)
</script>

<style scoped>
.lv-cols { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 14px; }
.lv { border-radius: var(--bt-radius); padding: 14px 16px; cursor: pointer; border: 1px solid var(--bt-line); background: #fff; }
.lv.high { background: linear-gradient(135deg, #f3eefb, #fff); border-color: #d8c9ea; }
.lv.mid { background: linear-gradient(135deg, #fdf6ea, #fff); border-color: #ecdcbf; }
.lv.low { background: linear-gradient(135deg, #f2f4f8, #fff); border-color: #dde2ec; }
.lv.eff { cursor: default; }
.lv-lb { font-size: 12px; color: var(--bt-text-3); }
.lv-n { font-size: 30px; font-weight: 700; margin: 4px 0 2px; color: var(--bt-primary); }
.lv.mid .lv-n { color: var(--bt-warn); }
.lv.low .lv-n { color: var(--bt-text-2); }
.lv-d { font-size: 11px; color: var(--bt-text-3); line-height: 1.6; }
.eff-row { display: flex; justify-content: space-between; font-size: 12px; padding: 4px 0; color: var(--bt-text-2); }
.eff-row b { color: var(--bt-primary); }
.score-cell { display: flex; align-items: center; gap: 6px; }
.score-cell b { font-size: 15px; color: var(--bt-primary); }
.sc-head { display: flex; justify-content: space-between; align-items: center; }
.sc-total { font-size: 34px; font-weight: 700; color: var(--bt-primary); }
.sc-total small { font-size: 13px; font-weight: 400; color: var(--bt-text-3); margin-left: 3px; }
.dt-sec { font-weight: 600; font-size: 13px; margin: 16px 0 10px; padding-left: 8px; border-left: 3px solid var(--bt-primary); }
.ft { margin-bottom: 12px; }
.ft-h { display: flex; justify-content: space-between; font-size: 12px; margin-bottom: 5px; }
.ft-bar { height: 7px; background: #f0edf6; border-radius: 4px; overflow: hidden; }
.ft-bar i { display: block; height: 100%; background: linear-gradient(90deg, #7a5aa6, #b79ad4); border-radius: 4px; }
.ft-d { display: flex; justify-content: space-between; font-size: 11px; margin-top: 4px; gap: 10px; }
</style>
