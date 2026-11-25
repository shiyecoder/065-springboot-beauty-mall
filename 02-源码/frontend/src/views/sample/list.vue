<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">试用装管理</h3>
        <div class="page-sub">按商品维护试用装规格、成本、批次与有效期；剩余数量 = 入库总量 − 已派发，过期批次不可派发</div>
      </div>
      <div>
        <el-button :icon="Refresh" @click="load">刷新</el-button>
        <el-button type="primary" :icon="Plus" @click="openEdit()">新增试用装</el-button>
      </div>
    </div>

    <div class="kpi-grid" style="grid-template-columns: repeat(4, 1fr)">
      <div class="kpi"><div class="lb">试用装批次数</div><div class="vl">{{ total }}<small>个</small></div></div>
      <div class="kpi"><div class="lb">剩余可派发</div><div class="vl">{{ sum.remain }}<small>份</small></div></div>
      <div class="kpi"><div class="lb">累计已派发</div><div class="vl">{{ sum.sent }}<small>份</small></div></div>
      <div class="kpi"><div class="lb">临期 / 过期批次</div><div class="vl" style="color: var(--bt-warn)">{{ sum.warn }}<small>个</small></div></div>
    </div>

    <div class="filter-bar">
      <el-input v-model="q.keyword" placeholder="试用装编号 / 商品名称" clearable style="width: 220px" @keyup.enter="search" />
      <el-select v-model="q.status" placeholder="全部状态" clearable style="width: 180px">
        <el-option v-for="t in STATUS" :key="t" :label="t" :value="t" />
      </el-select>
      <el-button type="primary" :icon="Search" @click="search">查询</el-button>
      <el-button @click="reset">重置</el-button>
      <span class="muted" style="margin-left: auto; font-size: 12px">单实体上限 16 张图，禁止外链</span>
    </div>

    <div class="card">
      <el-table :data="rows" v-loading="loading" stripe>
        <el-table-column label="商品图" width="72">
          <template #default="{ row }"><img v-if="row.goodsCover" class="thumb" :src="row.goodsCover" alt="" /></template>
        </el-table-column>
        <el-table-column prop="sampleNo" label="试用装编号" width="140" />
        <el-table-column prop="goodsName" label="关联商品" min-width="200" />
        <el-table-column label="规格" width="80">
          <template #default="{ row }">{{ row.specMl }} ml</template>
        </el-table-column>
        <el-table-column label="成本单价" width="100">
          <template #default="{ row }">¥{{ row.costPrice }}</template>
        </el-table-column>
        <el-table-column label="入库 / 已派 / 剩余" width="170">
          <template #default="{ row }">
            <span class="mono">{{ row.totalQty }}</span> /
            <span class="mono">{{ row.sentQty }}</span> /
            <b :style="{ color: row.remainQty <= 20 ? 'var(--bt-bad)' : 'var(--bt-text)' }">{{ row.remainQty }}</b>
          </template>
        </el-table-column>
        <el-table-column prop="batchNo" label="生产批次" width="130" />
        <el-table-column label="有效期" width="120">
          <template #default="{ row }">
            <span :class="{ 'exp-soon': row.expiring }">{{ row.expireDate }}</span>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <span class="tag" :class="ST_CLS[row.status] || 'info'">{{ row.status }}</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
            <el-button link type="primary" @click="goStock(row)">出入库</el-button>
            <el-button v-if="row.status === '已过期'" link type="danger" @click="scrap(row)">核销</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next, sizes" :total="total"
                       v-model:current-page="q.page" v-model:page-size="q.size"
                       :page-sizes="[10, 20, 50]" @current-change="load" @size-change="search" />
      </div>
    </div>

    <el-dialog v-model="dlg" :title="form.id ? '编辑试用装' : '新增试用装'" width="600px">
      <el-form :model="form" label-width="100px">
        <el-row :gutter="12">
          <el-col :span="24">
            <el-form-item label="关联商品">
              <el-select v-model="form.goodsId" filterable style="width: 100%" placeholder="选择商品（必须先有商品才能建试用装）">
                <el-option v-for="g in goods" :key="g.id" :label="`${g.goodsName}（正装 ${g.specMl}ml）`" :value="g.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="试用装规格"><el-input-number v-model="form.specMl" :min="1" style="width: 100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="成本单价"><el-input-number v-model="form.costPrice" :min="0" :precision="2" style="width: 100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="入库总量"><el-input-number v-model="form.totalQty" :min="1" style="width: 100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="生产批次"><el-input v-model="form.batchNo" placeholder="B001260101" /></el-form-item></el-col>
          <el-col :span="12">
            <el-form-item label="有效期">
              <el-date-picker v-model="form.expireDate" type="date" value-format="YYYY-MM-DD" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="状态">
              <el-select v-model="form.status" style="width: 100%">
                <el-option v-for="t in STATUS" :key="t" :label="t" :value="t" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <div class="note-box">试用装规格不得超过正装规格的三分之一；有效期早于当天时系统自动置为已过期，需先做过期核销才能继续操作。</div>
      </el-form>
      <template #footer>
        <el-button @click="dlg = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { Plus, Search, Refresh } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useRouter } from 'vue-router'
import { samplePage, sampleDetail, sampleSave, goodsPage, stockChange } from '../../api'

const router = useRouter()
const STATUS = ['可派发', '已过期', '库存不足', '已停用']
const ST_CLS = { 可派发: 'ok', 已过期: 'bad', 库存不足: 'warn', 已停用: 'info' }

const q = reactive({ page: 1, size: 10, keyword: '', status: '' })
const rows = ref([])
const total = ref(0)
const loading = ref(false)
const dlg = ref(false)
const saving = ref(false)
const form = reactive({})
const goods = ref([])

const sum = computed(() => {
  const a = rows.value
  return {
    remain: a.reduce((s, r) => s + (r.remainQty || 0), 0),
    sent: a.reduce((s, r) => s + (r.sentQty || 0), 0),
    warn: a.filter((r) => r.expiring || r.status === '已过期').length
  }
})

const load = async () => {
  loading.value = true
  try {
    const r = await samplePage(q)
    rows.value = r.data.records || []
    total.value = r.data.total || 0
  } finally {
    loading.value = false
  }
}
const search = () => { q.page = 1; load() }
const reset = () => { q.keyword = ''; q.status = ''; search() }

const openEdit = async (row) => {
  Object.keys(form).forEach((k) => delete form[k])
  if (!goods.value.length) goods.value = (await goodsPage({ page: 1, size: 100 })).data.records || []
  if (row) {
    Object.assign(form, (await sampleDetail(row.id)).data)
  } else {
    Object.assign(form, { goodsId: null, specMl: 10, costPrice: 2, totalQty: 100, batchNo: 'B001', expireDate: '', status: '可派发' })
  }
  dlg.value = true
}

const save = async () => {
  if (!form.goodsId) return ElMessage.warning('请选择关联商品')
  if (!form.expireDate) return ElMessage.warning('请选择有效期')
  const g = goods.value.find((x) => x.id === form.goodsId)
  if (g && form.specMl > g.specMl / 3) return ElMessage.warning(`试用装规格不得超过正装规格（${g.specMl}ml）的三分之一`)
  saving.value = true
  try {
    await sampleSave({ ...form })
    ElMessage.success('保存成功')
    dlg.value = false
    load()
  } finally {
    saving.value = false
  }
}

const goStock = (row) => router.push({ path: '/admin/sample/stock', query: { sampleNo: row.sampleNo } })

const scrap = async (row) => {
  const { value } = await ElMessageBox.prompt(`输入要核销的过期数量（剩余 ${row.remainQty} 份），核销后写入库存流水`, '过期核销', {
    inputPattern: /^\d+$/, inputErrorMessage: '请输入正整数', inputValue: String(row.remainQty)
  })
  await stockChange({ sampleId: row.id, changeType: '过期核销', changeQty: -Number(value), remark: '过期批次核销' })
  ElMessage.success('已核销')
  load()
}

onMounted(load)
</script>

<style scoped>
.exp-soon { color: var(--bt-warn); font-weight: 600; }
</style>
