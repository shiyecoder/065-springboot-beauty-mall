<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">商品管理</h3>
        <div class="page-sub">在售商品与试用装货源的唯一维护入口，修改售价与库存会记录版本号</div>
      </div>
      <el-button type="primary" :icon="Plus" @click="openEdit()">新增商品</el-button>
    </div>

    <div class="filter-bar">
      <el-input v-model="q.keyword" placeholder="商品名称 / 编号" clearable style="width: 220px" @keyup.enter="search" />
      <el-select v-model="q.goodsType" placeholder="全部品类" clearable style="width: 130px">
        <el-option v-for="t in TYPES" :key="t" :label="t" :value="t" />
      </el-select>
      <el-select v-model="q.status" placeholder="全部状态" clearable style="width: 130px">
        <el-option v-for="t in STATUS" :key="t" :label="t" :value="t" />
      </el-select>
      <el-button type="primary" :icon="Search" @click="search">查询</el-button>
      <el-button @click="reset">重置</el-button>
      <span class="muted" style="margin-left: auto; font-size: 12px">共 {{ total }} 个商品</span>
    </div>

    <div class="card">
      <el-table :data="rows" v-loading="loading" stripe>
        <el-table-column label="封面" width="72">
          <template #default="{ row }">
            <img class="thumb" :src="row.coverImage" alt="" />
          </template>
        </el-table-column>
        <el-table-column prop="goodsNo" label="商品编号" width="150" />
        <el-table-column label="商品名称" min-width="220">
          <template #default="{ row }">
            <div style="font-weight: 600">{{ row.goodsName }}</div>
            <div class="muted" style="font-size: 12px">{{ row.brand }} · {{ row.specMl }}ml · {{ row.effectTags }}</div>
          </template>
        </el-table-column>
        <el-table-column prop="goodsType" label="品类" width="80" />
        <el-table-column prop="skinType" label="适合肤质" width="150" />
        <el-table-column label="售价" width="100">
          <template #default="{ row }"><span class="price">¥{{ row.salePrice }}</span></template>
        </el-table-column>
        <el-table-column prop="stockQty" label="正装库存" width="100" />
        <el-table-column label="试用装" width="90">
          <template #default="{ row }">
            <span class="tag" :class="row.isTrial ? 'ok' : 'info'">{{ row.isTrial ? '已开派' : '未开派' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="90">
          <template #default="{ row }">
            <span class="tag" :class="ST_CLS[row.status] || 'info'">{{ row.status }}</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="140" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
            <el-button link type="danger" @click="remove(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next, sizes" :total="total"
                       v-model:current-page="q.page" v-model:page-size="q.size"
                       :page-sizes="[10, 20, 50]" @current-change="load" @size-change="search" />
      </div>
    </div>

    <el-dialog v-model="dlg" :title="form.id ? '编辑商品' : '新增商品'" width="640px">
      <el-form :model="form" label-width="92px">
        <el-row :gutter="12">
          <el-col :span="12"><el-form-item label="商品名称"><el-input v-model="form.goodsName" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="品牌"><el-input v-model="form.brand" /></el-form-item></el-col>
          <el-col :span="12">
            <el-form-item label="品类">
              <el-select v-model="form.goodsType" style="width: 100%">
                <el-option v-for="t in TYPES" :key="t" :label="t" :value="t" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="适合肤质"><el-input v-model="form.skinType" placeholder="干性,油性,混合" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="功效标签"><el-input v-model="form.effectTags" placeholder="保湿,舒缓" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="规格(ml)"><el-input-number v-model="form.specMl" :min="1" style="width: 100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="售价"><el-input-number v-model="form.salePrice" :min="0" :precision="2" style="width: 100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="正装库存"><el-input-number v-model="form.stockQty" :min="0" style="width: 100%" /></el-form-item></el-col>
          <el-col :span="12">
            <el-form-item label="状态">
              <el-select v-model="form.status" style="width: 100%">
                <el-option v-for="t in STATUS" :key="t" :label="t" :value="t" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="开启派发">
              <el-switch v-model="form.isTrial" :active-value="1" :inactive-value="0" />
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="封面图">
              <el-input v-model="form.coverImage" placeholder="/uploads/seed/goods/01.jpg" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
      <template #footer>
        <el-button @click="dlg = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { Plus, Search } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { goodsPage, goodsDetail, goodsSave, goodsDelete } from '../../api'

const TYPES = ['精华', '面霜', '洁面', '防晒', '面膜', '彩妆']
const STATUS = ['在售', '待上架', '已售罄', '已下架']
const ST_CLS = { 在售: 'ok', 待上架: 'info', 已售罄: 'warn', 已下架: 'bad' }

const q = reactive({ page: 1, size: 10, keyword: '', goodsType: '', status: '' })
const rows = ref([])
const total = ref(0)
const loading = ref(false)
const dlg = ref(false)
const saving = ref(false)
const form = reactive({})

const load = async () => {
  loading.value = true
  try {
    const r = await goodsPage(q)
    rows.value = r.data.records || []
    total.value = r.data.total || 0
  } finally {
    loading.value = false
  }
}
const search = () => {
  q.page = 1
  load()
}
const reset = () => {
  q.keyword = ''
  q.goodsType = ''
  q.status = ''
  search()
}

const openEdit = async (row) => {
  Object.keys(form).forEach((k) => delete form[k])
  if (row) {
    const r = await goodsDetail(row.id)
    Object.assign(form, r.data)
  } else {
    Object.assign(form, { goodsName: '', brand: '', goodsType: '精华', skinType: '干性,混合', effectTags: '保湿', specMl: 30, salePrice: 199, stockQty: 100, isTrial: 1, status: '在售', coverImage: '/uploads/seed/goods/01.jpg' })
  }
  dlg.value = true
}

const save = async () => {
  if (!form.goodsName || !form.brand) return ElMessage.warning('商品名称与品牌不能为空')
  saving.value = true
  try {
    await goodsSave({ ...form })
    ElMessage.success('保存成功')
    dlg.value = false
    load()
  } finally {
    saving.value = false
  }
}

const remove = async (row) => {
  await ElMessageBox.confirm(`确认删除商品「${row.goodsName}」？存在试用装批次时将拒绝删除。`, '提示', { type: 'warning' })
  await goodsDelete(row.id)
  ElMessage.success('已删除')
  load()
}

onMounted(load)
</script>
