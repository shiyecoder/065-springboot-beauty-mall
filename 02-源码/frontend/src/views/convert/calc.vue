<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">转化计算留痕</h3>
        <div class="page-sub">每次计算保存输入快照、规则版本、各因素得分与结论，相同输入与规则版本必然得到相同结果</div>
      </div>
      <el-button :icon="Refresh" @click="load">刷新</el-button>
    </div>

    <div class="filter-bar">
      <el-input v-model="q.keyword" placeholder="用户 / 商品 / 跟踪号" clearable style="width: 220px" @keyup.enter="search" />
      <el-select v-model="q.level" placeholder="全部意向" clearable style="width: 180px">
        <el-option v-for="t in LEVELS" :key="t" :label="t" :value="t" />
      </el-select>
      <el-button type="primary" :icon="Search" @click="search">查询</el-button>
      <el-button @click="reset">重置</el-button>
      <span class="muted" style="margin-left: auto; font-size: 12px">留痕不可修改，只有主动重算才生成新快照</span>
    </div>

    <div class="card">
      <el-table :data="rows" v-loading="loading" stripe>
        <el-table-column prop="trackNo" label="跟踪号" width="150" />
        <el-table-column prop="userName" label="用户" width="100" />
        <el-table-column prop="goodsName" label="试用商品" min-width="180" show-overflow-tooltip />
        <el-table-column label="转化分" width="110" sortable :sort-by="(r) => r.convertScore">
          <template #default="{ row }"><b style="color: var(--bt-primary); font-size: 15px">{{ row.convertScore }}</b></template>
        </el-table-column>
        <el-table-column label="结论等级" width="110">
          <template #default="{ row }">
            <span class="tag" :class="row.convertLevel === '高意向' ? 'ok' : row.convertLevel === '中意向' ? 'warn' : 'info'">{{ row.convertLevel }}</span>
          </template>
        </el-table-column>
        <el-table-column label="浏览 / 加购" width="120">
          <template #default="{ row }">{{ row.browseMin }} 分 / {{ row.cartTimes }} 次</template>
        </el-table-column>
        <el-table-column prop="followStatus" label="跟进状态" width="100" />
        <el-table-column label="计算时间" width="150">
          <template #default="{ row }">{{ fmt(row.createTime) }}</template>
        </el-table-column>
        <el-table-column label="操作" width="110" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="open(row)">查看留痕</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next, sizes" :total="total"
                       v-model:current-page="q.page" v-model:page-size="q.size"
                       :page-sizes="[10, 20, 50]" @current-change="load" @size-change="search" />
      </div>
    </div>

    <el-drawer v-model="drawer" title="计算快照留痕" size="560px">
      <div v-if="sc">
        <div class="snap-hd">
          <div>
            <div class="muted" style="font-size: 12px">快照编号 {{ sc.snapNo }} · 规则版本 {{ sc.ruleVersion }}</div>
            <div class="snap-total">{{ sc.totalScore }}<small>分 · {{ sc.level }}</small></div>
          </div>
          <span class="tag ok">{{ sc.match }}</span>
        </div>

        <div class="note-box" style="margin: 14px 0">{{ sc.conclusion }}</div>

        <div class="dt-sec">各因素得分（权重来自规则 {{ sc.ruleVersion }}）</div>
        <el-table :data="sc.factors" size="small" border>
          <el-table-column prop="name" label="因素" width="150" />
          <el-table-column prop="weight" label="权重" width="70">
            <template #default="{ row }">{{ row.weight }}%</template>
          </el-table-column>
          <el-table-column prop="score" label="得分" width="70" />
          <el-table-column prop="weighted" label="加权" width="80" />
          <el-table-column prop="detail" label="输入依据" min-width="200" show-overflow-tooltip />
        </el-table>

        <div class="dt-sec">未满足条件</div>
        <div v-if="!sc.unmet || !sc.unmet.length" class="muted" style="font-size: 12px">无，数据完整</div>
        <div v-for="(u, i) in sc.unmet || []" :key="i" class="note-box warn" style="margin-bottom: 8px">{{ u }}</div>

        <div class="dt-sec">可改进项</div>
        <div class="note-box">
          提升转化分最有效的方式是完善肤质档案、在发放后 15 天内提交含照片的完整报告，
          并持续浏览正装详情页 —— 三项合计占总权重的 65%。
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { Search, Refresh } from '@element-plus/icons-vue'
import { trackPage, trackScore } from '../../api'

const LEVELS = ['高意向', '中意向', '低意向']
const q = reactive({ page: 1, size: 10, keyword: '', level: '' })
const rows = ref([])
const total = ref(0)
const loading = ref(false)
const drawer = ref(false)
const sc = ref(null)

const load = async () => {
  loading.value = true
  try {
    const r = await trackPage(q)
    rows.value = r.data.records || []
    total.value = r.data.total || 0
  } finally {
    loading.value = false
  }
}
const search = () => { q.page = 1; load() }
const reset = () => { q.keyword = ''; q.level = ''; search() }
const open = async (row) => {
  sc.value = (await trackScore(row.id)).data
  drawer.value = true
}
const fmt = (t) => (t ? String(t).replace('T', ' ').slice(0, 16) : '-')

onMounted(load)
</script>

<style scoped>
.snap-hd { display: flex; justify-content: space-between; align-items: center; }
.snap-total { font-size: 32px; font-weight: 700; color: var(--bt-primary); }
.snap-total small { font-size: 13px; font-weight: 400; color: var(--bt-text-3); margin-left: 4px; }
.dt-sec { font-weight: 600; font-size: 13px; margin: 16px 0 10px; padding-left: 8px; border-left: 3px solid var(--bt-primary); }
</style>
