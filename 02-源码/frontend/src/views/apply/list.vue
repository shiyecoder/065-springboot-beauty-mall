<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">申领列表</h3>
        <div class="page-sub">全部试用申领单据，状态流转由后端状态机校验，前端不可直接改状态</div>
      </div>
      <el-button :icon="Refresh" @click="load">刷新</el-button>
    </div>

    <div class="filter-bar">
      <el-input v-model="q.keyword" placeholder="申领单号 / 用户 / 商品" clearable style="width: 220px" @keyup.enter="search" />
      <el-select v-model="q.status" placeholder="全部状态" clearable style="width: 180px">
        <el-option v-for="t in STATUS" :key="t" :label="t" :value="t" />
      </el-select>
      <el-select v-model="q.skinType" placeholder="全部肤质" clearable style="width: 180px">
        <el-option v-for="t in SKINS" :key="t" :label="t" :value="t" />
      </el-select>
      <el-button type="primary" :icon="Search" @click="search">查询</el-button>
      <el-button @click="reset">重置</el-button>
      <span class="muted" style="margin-left: auto; font-size: 12px">共 {{ total }} 条申领单</span>
    </div>

    <div class="card">
      <el-table :data="rows" v-loading="loading" stripe>
        <el-table-column label="商品" width="72">
          <template #default="{ row }"><img v-if="row.goodsCover" class="thumb" :src="row.goodsCover" alt="" /></template>
        </el-table-column>
        <el-table-column prop="applyNo" label="申领单号" width="150" />
        <el-table-column label="申请人" width="150">
          <template #default="{ row }">
            <div style="font-weight: 600">{{ row.userName }}</div>
            <div class="muted" style="font-size: 11px">肤质：{{ row.skinType || '未填' }}</div>
          </template>
        </el-table-column>
        <el-table-column label="商品" min-width="190">
          <template #default="{ row }">
            <div>{{ row.goodsName }}</div>
            <div class="muted" style="font-size: 11px">{{ row.brand }} · 试用装 {{ row.sampleSpec }}ml</div>
          </template>
        </el-table-column>
        <el-table-column prop="applyReason" label="申领理由" min-width="200" show-overflow-tooltip />
        <el-table-column label="状态" width="110">
          <template #default="{ row }">
            <span class="tag" :class="ST_CLS[row.status] || 'info'">{{ row.status }}</span>
          </template>
        </el-table-column>
        <el-table-column label="快递单号" width="150">
          <template #default="{ row }"><span class="mono">{{ row.expressNo || '-' }}</span></template>
        </el-table-column>
        <el-table-column label="申领时间" width="150">
          <template #default="{ row }">{{ fmt(row.createTime) }}</template>
        </el-table-column>
        <el-table-column label="操作" width="90" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="open(row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next, sizes" :total="total"
                       v-model:current-page="q.page" v-model:page-size="q.size"
                       :page-sizes="[10, 20, 50]" @current-change="load" @size-change="search" />
      </div>
    </div>

    <el-drawer v-model="drawer" title="申领单详情" size="520px">
      <div v-if="cur">
        <div class="dt-head">
          <img v-if="cur.goodsCover" :src="cur.goodsCover" class="dt-cover" alt="" />
          <div>
            <div style="font-weight: 700; font-size: 15px">{{ cur.goodsName }}</div>
            <div class="muted" style="font-size: 12px; margin-top: 4px">{{ cur.applyNo }} · {{ cur.brand }}</div>
            <span class="tag" :class="ST_CLS[cur.status] || 'info'" style="margin-top: 8px">{{ cur.status }}</span>
          </div>
        </div>

        <div class="dt-sec">申领信息</div>
        <div class="kv">
          <span class="k">申请人</span><span>{{ cur.userName }}</span>
          <span class="k">肤质类型</span><span>{{ cur.skinType || '未完善' }}</span>
          <span class="k">试用装</span><span>{{ cur.sampleNo }} · {{ cur.sampleSpec }}ml</span>
          <span class="k">申领时间</span><span>{{ fmt(cur.createTime) }}</span>
          <span class="k">申领理由</span><span>{{ cur.applyReason }}</span>
          <span class="k">收货人</span><span>{{ cur.receiverName }} {{ cur.receiverPhone }}</span>
          <span class="k">地址</span><span>{{ cur.addressDesc }}</span>
          <span class="k">快递单号</span><span class="mono">{{ cur.expressNo || '未登记' }}</span>
          <span class="k">审核意见</span><span>{{ cur.auditRemark || '-' }}</span>
        </div>

        <template v-if="cur.profile">
          <div class="dt-sec">肤质档案快照</div>
          <div class="kv">
            <span class="k">肤质类型</span><span>{{ cur.profile.skinType }}</span>
            <span class="k">敏感程度</span><span>{{ cur.profile.sensitiveLevel }}</span>
            <span class="k">主要诉求</span><span>{{ cur.profile.demandTags }}</span>
            <span class="k">过敏成分</span><span>{{ cur.profile.allergyIngredients || '无记录' }}</span>
            <span class="k">自测得分</span><span>{{ cur.profile.selfTestScore }}</span>
          </div>
        </template>

        <div class="dt-sec">库存情况</div>
        <div class="note-box" :class="{ warn: (cur.stockRemain || 0) <= 0 }">
          该批次剩余 {{ cur.stockRemain ?? '-' }} 份，有效期至 {{ cur.expireDate || '-' }}。
          <span v-if="(cur.stockRemain || 0) <= 0">库存不足，发放前需补货。</span>
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { Search, Refresh } from '@element-plus/icons-vue'
import { applyPage, applyDetail } from '../../api'

const STATUS = ['待审核', '待发放', '已发放', '待提交报告', '已完成', '已驳回']
const SKINS = ['干性', '油性', '混合', '敏感', '中性']
const ST_CLS = { 待审核: 'warn', 待发放: 'info', 已发放: 'info', 待提交报告: 'warn', 已完成: 'ok', 已驳回: 'bad' }

const q = reactive({ page: 1, size: 10, keyword: '', status: '', skinType: '' })
const rows = ref([])
const total = ref(0)
const loading = ref(false)
const drawer = ref(false)
const cur = ref(null)

const load = async () => {
  loading.value = true
  try {
    const r = await applyPage(q)
    rows.value = r.data.records || []
    total.value = r.data.total || 0
  } finally {
    loading.value = false
  }
}
const search = () => { q.page = 1; load() }
const reset = () => { q.keyword = ''; q.status = ''; q.skinType = ''; search() }
const open = async (row) => {
  cur.value = (await applyDetail(row.id)).data
  drawer.value = true
}
const fmt = (t) => (t ? String(t).replace('T', ' ').slice(0, 16) : '-')

onMounted(load)
</script>

<style scoped>
.dt-head { display: flex; gap: 14px; align-items: flex-start; padding-bottom: 14px; border-bottom: 1px solid var(--bt-line); }
.dt-cover { width: 84px; height: 84px; border-radius: 10px; object-fit: cover; background: var(--bt-primary-soft); }
.dt-sec { font-weight: 600; font-size: 13px; margin: 16px 0 10px; padding-left: 8px; border-left: 3px solid var(--bt-primary); }
</style>
