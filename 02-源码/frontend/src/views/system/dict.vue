<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">字典管理</h3>
        <div class="page-sub">全系统状态、品类、肤质、支付方式等枚举集中在此维护，前端展示与后端校验共用一套值</div>
      </div>
      <el-input v-model="kw" placeholder="搜索字典名称 / 编码" clearable style="width: 240px" />
    </div>

    <div class="g21">
      <div class="card">
        <div class="card-hd"><span>字典类型</span><span class="muted" style="font-size: 12px">{{ filtered.length }} 类</span></div>
        <div class="dict-list" v-loading="loading">
          <div v-for="t in filtered" :key="t.dictType" class="dict-item" :class="{ on: t.dictType === cur }"
               @click="cur = t.dictType">
            <div>
              <div class="nm">{{ t.dictName }}</div>
              <div class="mono muted">{{ t.dictType }}</div>
            </div>
            <span class="cnt">{{ (t.items || []).length }}</span>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="card-hd">
          <span>{{ curName }} · 字典项</span>
          <span class="muted" style="font-size: 12px">值不可重复，标签支持标签样式</span>
        </div>
        <el-table :data="curItems" stripe>
          <el-table-column prop="label" label="显示标签" min-width="130" />
          <el-table-column prop="value" label="存储值" min-width="150">
            <template #default="{ row }"><span class="mono">{{ row.value }}</span></template>
          </el-table-column>
          <el-table-column label="标签样式" width="120">
            <template #default="{ row }">
              <span class="tag" :class="STYLE[row.style] || 'info'">{{ STYLE_NAME[row.style] || '默认' }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="sortNo" label="排序" width="80" />
          <el-table-column label="状态" width="90">
            <template #default="{ row }">
              <span class="tag" :class="row.status === 1 ? 'ok' : 'info'">{{ row.status === 1 ? '启用' : '停用' }}</span>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { dictList } from '../../api'

const STYLE = { success: 'ok', warning: 'warn', danger: 'bad', primary: 'info', info: 'info', default: 'info' }
// 字典里存的是 Element 语义名，表格里显示中文，避免演示时出现英文枚举
const STYLE_NAME = { success: '成功', warning: '警告', danger: '危险', primary: '主色', info: '信息', default: '默认' }
const rows = ref([])
const kw = ref('')
const cur = ref('')
const loading = ref(false)

const filtered = computed(() => {
  const k = kw.value.trim()
  if (!k) return rows.value
  return rows.value.filter((t) => t.dictName.includes(k) || t.dictType.includes(k))
})
const curName = computed(() => rows.value.find((t) => t.dictType === cur.value)?.dictName || '请选择')
const curItems = computed(() => rows.value.find((t) => t.dictType === cur.value)?.items || [])

const load = async () => {
  loading.value = true
  try {
    const r = await dictList()
    rows.value = r.data || []
    if (!cur.value && rows.value.length) cur.value = rows.value[0].dictType
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<style scoped>
.dict-list { max-height: 560px; overflow: auto; }
.dict-item { display: flex; align-items: center; justify-content: space-between; padding: 10px 12px; border-radius: 8px; cursor: pointer; }
.dict-item + .dict-item { margin-top: 2px; }
.dict-item:hover { background: #f7f3fb; }
.dict-item.on { background: #f1eaf9; box-shadow: inset 2px 0 0 var(--bt-primary); }
.dict-item .nm { font-size: 13px; font-weight: 600; }
.dict-item .mono { font-size: 11px; }
.dict-item .cnt { font-size: 12px; color: var(--bt-text-3); }
</style>
