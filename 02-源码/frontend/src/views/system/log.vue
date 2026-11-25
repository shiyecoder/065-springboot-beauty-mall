<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">操作日志</h3>
        <div class="page-sub">审核、发放、退款、规则变更等关键动作全部留痕，可按模块与关键词追溯</div>
      </div>
      <span class="muted" style="font-size: 12px">共 {{ total }} 条</span>
    </div>

    <div class="filter-bar">
      <el-input v-model="q.keyword" placeholder="操作人 / 业务编号" clearable style="width: 220px" @keyup.enter="search" />
      <el-select v-model="q.module" placeholder="全部模块" clearable style="width: 180px">
        <el-option v-for="m in MODULES" :key="m" :label="m" :value="m" />
      </el-select>
      <el-button type="primary" :icon="Search" @click="search">查询</el-button>
      <el-button @click="reset">重置</el-button>
    </div>

    <div class="card">
      <el-table :data="rows" v-loading="loading" stripe>
        <el-table-column prop="operTime" label="操作时间" width="170">
          <template #default="{ row }">{{ fmt(row.operTime) }}</template>
        </el-table-column>
        <el-table-column prop="module" label="模块" width="120" />
        <el-table-column prop="operType" label="动作" width="110">
          <template #default="{ row }"><span class="tag warn">{{ row.operType }}</span></template>
        </el-table-column>
        <el-table-column prop="bizNo" label="业务编号" width="170">
          <template #default="{ row }"><span class="mono">{{ row.bizNo || '—' }}</span></template>
        </el-table-column>
        <el-table-column prop="content" label="操作内容" min-width="300" show-overflow-tooltip />
        <el-table-column prop="operName" label="操作人" width="110" />
        <el-table-column prop="ip" label="IP" width="130">
          <template #default="{ row }"><span class="mono">{{ row.ip || '—' }}</span></template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next, sizes" :total="total"
                       v-model:current-page="q.page" v-model:page-size="q.size"
                       :page-sizes="[10, 20, 50]" @current-change="load" @size-change="search" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { Search } from '@element-plus/icons-vue'
import { logPage } from '../../api'
import { fmt } from '../../utils/format'

const MODULES = ['申领', '审核', '发放', '报告', '订单', '转换', '规则', '系统']

const q = reactive({ page: 1, size: 10, keyword: '', module: '' })
const rows = ref([])
const total = ref(0)
const loading = ref(false)

const load = async () => {
  loading.value = true
  try {
    const r = await logPage(q)
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
  q.module = ''
  search()
}

onMounted(load)
</script>
