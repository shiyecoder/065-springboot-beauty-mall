<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">发放登记</h3>
        <div class="page-sub">审核通过的申领单在此拣货登记快递单号，保存后扣减试用装库存并写入库存流水（同一事务）</div>
      </div>
      <el-button :icon="Refresh" @click="load">刷新</el-button>
    </div>

    <div class="kpi-grid" style="grid-template-columns: repeat(3, 1fr)">
      <div class="kpi"><div class="lb">待发放单据</div><div class="vl">{{ total }}<small>单</small></div></div>
      <div class="kpi"><div class="lb">今日已登记</div><div class="vl">{{ todaySent }}<small>单</small></div></div>
      <div class="kpi"><div class="lb">库存不足单据</div><div class="vl" style="color: var(--bt-bad)">{{ shortStock }}<small>单</small></div></div>
    </div>

    <div class="filter-bar">
      <el-input v-model="q.keyword" placeholder="申领单号 / 收货人" clearable style="width: 220px" @keyup.enter="search" />
      <el-button type="primary" :icon="Search" @click="search">查询</el-button>
      <el-button @click="reset">重置</el-button>
      <span class="muted" style="margin-left: auto; font-size: 12px">库存不足时整单退回待审核，需运营先补货</span>
    </div>

    <div class="card">
      <el-table :data="rows" v-loading="loading" stripe>
        <el-table-column label="商品" width="72">
          <template #default="{ row }"><img v-if="row.goodsCover" class="thumb" :src="row.goodsCover" alt="" /></template>
        </el-table-column>
        <el-table-column prop="applyNo" label="申领单号" width="150" />
        <el-table-column label="收货人" width="150">
          <template #default="{ row }">
            <div style="font-weight: 600">{{ row.receiverName }}</div>
            <div class="muted" style="font-size: 11px">{{ row.receiverPhone }}</div>
          </template>
        </el-table-column>
        <el-table-column label="商品与试用装" min-width="200">
          <template #default="{ row }">
            <div>{{ row.goodsName }}</div>
            <div class="muted" style="font-size: 11px">{{ row.sampleNo }} · {{ row.sampleSpec }}ml</div>
          </template>
        </el-table-column>
        <el-table-column prop="addressDesc" label="收货地址" min-width="220" show-overflow-tooltip />
        <el-table-column label="状态" width="100">
          <template #default="{ row }"><span class="tag warn">{{ row.status }}</span></template>
        </el-table-column>
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="openSend(row)">登记发货</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next, sizes" :total="total"
                       v-model:current-page="q.page" v-model:page-size="q.size"
                       :page-sizes="[10, 20, 50]" @current-change="load" @size-change="search" />
      </div>
    </div>

    <el-dialog v-model="dlg" title="登记发放" width="520px">
      <div v-if="cur" class="send-box">
        <div class="sb-row"><span class="k">申领单</span><span class="mono">{{ cur.applyNo }}</span></div>
        <div class="sb-row"><span class="k">商品</span><span>{{ cur.goodsName }}</span></div>
        <div class="sb-row"><span class="k">试用装</span><span>{{ cur.sampleNo }} · {{ cur.sampleSpec }}ml</span></div>
        <div class="sb-row"><span class="k">收货信息</span><span>{{ cur.receiverName }} {{ cur.receiverPhone }}<br />{{ cur.addressDesc }}</span></div>
        <div class="sb-row"><span class="k">批次库存</span>
          <span :style="{ color: (cur.stockRemain || 0) <= 0 ? 'var(--bt-bad)' : 'var(--bt-ok)', fontWeight: 600 }">
            剩余 {{ cur.stockRemain ?? '-' }} 份 · 有效期 {{ cur.expireDate || '-' }}
          </span>
        </div>
      </div>
      <el-form :model="form" label-width="92px" style="margin-top: 16px">
        <el-form-item label="快递公司">
          <el-select v-model="form.expressCompany" style="width: 100%">
            <el-option v-for="c in COMPANIES" :key="c" :label="c" :value="c" />
          </el-select>
        </el-form-item>
        <el-form-item label="快递单号">
          <el-input v-model="form.expressNo" placeholder="JD000000001234" />
        </el-form-item>
      </el-form>
      <div class="note-box">登记成功后状态转为「已发放」，系统开始计算 15 天报告期限与 30 天转化归因窗口。</div>
      <template #footer>
        <el-button @click="dlg = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="submit">确认发放</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { Search, Refresh } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { applyPage, applyDetail, applySend } from '../../api'

const COMPANIES = ['顺丰速运', '京东物流', '中通快递', '圆通速递', '韵达快递']
const q = reactive({ page: 1, size: 10, keyword: '', status: '待发放' })
const rows = ref([])
const total = ref(0)
const loading = ref(false)
const dlg = ref(false)
const saving = ref(false)
const cur = ref(null)
const form = reactive({ expressNo: '', expressCompany: '顺丰速运' })

const todaySent = computed(() => rows.value.filter((r) => r.expressNo).length)
const shortStock = computed(() => rows.value.filter((r) => (r.stockRemain ?? 1) <= 0).length)

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
const reset = () => { q.keyword = ''; q.status = '待发放'; search() }

const openSend = async (row) => {
  cur.value = (await applyDetail(row.id)).data
  form.expressNo = cur.value.expressNo || ''
  form.expressCompany = '顺丰速运'
  dlg.value = true
}

const submit = async () => {
  if (!form.expressNo) return ElMessage.warning('请填写快递单号')
  if ((cur.value?.stockRemain ?? 0) <= 0) return ElMessage.warning('该批次库存不足，请先补货再发放')
  saving.value = true
  try {
    await applySend(cur.value.id, { ...form })
    ElMessage.success('发放登记成功，库存已扣减')
    dlg.value = false
    load()
  } finally {
    saving.value = false
  }
}

onMounted(load)
</script>

<style scoped>
.send-box { background: var(--bt-primary-soft); border-radius: 8px; padding: 12px 14px; }
.sb-row { display: flex; gap: 12px; font-size: 13px; padding: 4px 0; }
.sb-row .k { width: 76px; color: var(--bt-text-3); flex: none; }
</style>
