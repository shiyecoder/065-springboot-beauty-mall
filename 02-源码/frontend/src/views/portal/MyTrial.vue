<template>
  <div class="wrap">
    <div class="hd">
      <div>
        <h2>我的试用</h2>
        <p>从申领到报告的完整记录，收到货后 30 天内提交报告可提升信用分</p>
      </div>
      <el-button @click="$router.push('/portal/trial')">领更多试用</el-button>
    </div>

    <div class="tabs">
      <span v-for="t in TABS" :key="t.v" class="tb" :class="{ on: tab === t.v }" @click="pick(t.v)">
        {{ t.t }}<i v-if="t.v === ''">{{ rows.length }}</i>
      </span>
    </div>

    <div v-loading="loading">
      <div v-for="a in rows" :key="a.id" class="item" @click="$router.push(`/portal/apply/${a.id}`)">
        <img :src="a.goodsCover" alt="" />
        <div class="bd">
          <div class="top">
            <span class="nm">{{ a.goodsName }}</span>
            <span class="tag" :class="ST[a.status] || 'info'">{{ a.status }}</span>
          </div>
          <div class="meta">申领单 {{ a.applyNo }} · {{ a.sampleSpec }}ml · {{ fmt(a.createTime) }}</div>
          <div class="meta" v-if="a.expressNo">快递 {{ a.expressCompany }} {{ a.expressNo }}</div>
        </div>
        <div class="rt">
          <el-button v-if="['已发放', '待提交报告'].includes(a.status)" type="primary" size="small"
                     @click.stop="$router.push(`/portal/report/${a.id}`)">写报告</el-button>
          <span v-else-if="a.status === '已完成'" class="done">已完成</span>
          <span v-else class="muted" style="font-size: 12px">查看详情 →</span>
        </div>
      </div>
      <el-empty v-if="!rows.length && !loading" description="还没有申领记录">
        <el-button type="primary" @click="$router.push('/portal/trial')">去领试用装</el-button>
      </el-empty>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { applyPage } from '../../api'
import { fmt } from '../../utils/format'

const ST = { 待审核: 'warn', 已驳回: 'bad', 待发放: 'info', 已发放: 'info', 待提交报告: 'warn', 已完成: 'ok' }
const TABS = [
  { t: '全部', v: '' },
  { t: '待审核', v: '待审核' },
  { t: '已发放', v: '已发放' },
  { t: '待提交报告', v: '待提交报告' },
  { t: '已完成', v: '已完成' }
]

const tab = ref('')
const rows = ref([])
const loading = ref(false)

const load = async () => {
  loading.value = true
  try {
    const r = await applyPage({ page: 1, size: 50, status: tab.value })
    rows.value = r.data.records || []
  } finally {
    loading.value = false
  }
}
const pick = (v) => {
  tab.value = v
  load()
}

onMounted(load)
</script>

<style scoped>
.wrap { width: 1060px; margin: 0 auto; padding: 28px 0 46px; }
.hd { display: flex; align-items: flex-end; justify-content: space-between; margin-bottom: 16px; }
.hd h2 { font-size: 22px; margin: 0 0 6px; }
.hd p { font-size: 12px; color: var(--bt-text-3); margin: 0; }
.tabs { display: flex; gap: 20px; border-bottom: 1px solid var(--bt-line); margin-bottom: 8px; }
.tb { font-size: 13px; color: var(--bt-text-2); padding: 8px 0; cursor: pointer; }
.tb.on { color: var(--bt-primary); font-weight: 600; box-shadow: inset 0 -2px 0 var(--bt-primary); }
.tb i { font-style: normal; margin-left: 5px; font-size: 11px; color: var(--bt-text-3); }
.item { display: flex; gap: 14px; align-items: center; padding: 16px 4px; border-bottom: 1px dashed var(--bt-line); cursor: pointer; }
.item:hover { background: #faf8fd; }
.item img { width: 72px; height: 72px; border-radius: 10px; object-fit: cover; background: #f7f3fb; }
.bd { flex: 1; min-width: 0; }
.top { display: flex; align-items: center; gap: 8px; }
.nm { font-size: 15px; font-weight: 600; }
.meta { font-size: 12px; color: var(--bt-text-3); margin-top: 5px; }
.rt { flex: none; }
.done { font-size: 12px; color: #2f8f5b; }
</style>
