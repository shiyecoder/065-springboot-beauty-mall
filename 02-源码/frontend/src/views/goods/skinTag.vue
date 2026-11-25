<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">肤质标签配置</h3>
        <div class="page-sub">适用肤质支持多选，功效标签只能从字典选择；标签直接影响申领匹配度与转化评分</div>
      </div>
      <el-button :icon="Refresh" @click="load">刷新</el-button>
    </div>

    <div class="g31">
      <div>
        <div class="filter-bar">
          <el-input v-model="q.keyword" placeholder="商品名称 / 编号" clearable style="width: 220px" @keyup.enter="search" />
          <el-select v-model="q.skin" placeholder="按肤质筛选" clearable style="width: 180px">
            <el-option v-for="s in SKINS" :key="s" :label="s" :value="s" />
          </el-select>
          <el-button type="primary" :icon="Search" @click="search">查询</el-button>
          <el-button @click="reset">重置</el-button>
          <span class="muted" style="margin-left: auto; font-size: 12px">共 {{ total }} 个商品</span>
        </div>

        <div class="card">
          <el-table :data="rows" v-loading="loading" stripe>
            <el-table-column label="商品" min-width="200">
              <template #default="{ row }">
                <div style="display: flex; gap: 9px; align-items: center">
                  <img v-if="row.coverImage" class="thumb" :src="row.coverImage" alt="" />
                  <div>
                    <div style="font-weight: 600">{{ row.goodsName }}</div>
                    <div class="muted" style="font-size: 11px">{{ row.brand }} · {{ row.goodsType }}</div>
                  </div>
                </div>
              </template>
            </el-table-column>
            <el-table-column label="适用肤质" min-width="190">
              <template #default="{ row }">
                <span v-for="s in split(row.skinType)" :key="s" class="tag" style="margin-right: 4px">{{ s }}</span>
                <span v-if="!split(row.skinType).length" class="muted">未配置</span>
              </template>
            </el-table-column>
            <el-table-column label="功效标签" min-width="150">
              <template #default="{ row }">
                <span v-for="s in split(row.effectTags)" :key="s" class="tag ok" style="margin-right: 4px">{{ s }}</span>
              </template>
            </el-table-column>
            <el-table-column label="试用装" width="90">
              <template #default="{ row }">
                <span class="tag" :class="row.isTrial ? 'ok' : 'info'">{{ row.isTrial ? '已配置' : '未配置' }}</span>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="90" fixed="right">
              <template #default="{ row }">
                <el-button link type="primary" @click="open(row)">配置</el-button>
              </template>
            </el-table-column>
          </el-table>
          <div class="pager">
            <el-pagination background layout="total, prev, pager, next" :total="total"
                           v-model:current-page="q.page" :page-size="q.size" @current-change="load" />
          </div>
        </div>
      </div>

      <div>
        <div class="card">
          <div class="card-hd">用户肤质分布</div>
          <Chart :option="skinOpt" height="196px" />
        </div>
        <div class="card">
          <div class="card-hd">配置规则</div>
          <div class="note-box">
            参与试用的商品必须已配置试用装，否则勾选「参与试用」会被拒绝；正装库存为 0 时自动置为已售罄，
            但已售罄商品仍可申领试用装，详情页会提示正装暂时缺货。
          </div>
        </div>
      </div>
    </div>

    <el-dialog v-model="dlg" title="肤质与功效标签配置" width="560px">
      <el-form :model="form" label-width="96px">
        <el-form-item label="商品">{{ form.goodsName }}（{{ form.brand }}）</el-form-item>
        <el-form-item label="适用肤质">
          <el-checkbox-group v-model="skinPick">
            <el-checkbox v-for="s in SKINS" :key="s" :label="s">{{ s }}</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="功效标签">
          <el-checkbox-group v-model="tagPick">
            <el-checkbox v-for="t in TAGS" :key="t" :label="t">{{ t }}</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="参与试用">
          <el-switch v-model="form.isTrial" :active-value="1" :inactive-value="0" />
          <span class="muted" style="margin-left: 10px; font-size: 12px">未配置试用装的商品不能开启</span>
        </el-form-item>
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
import { Search, Refresh } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import Chart from '../../components/Chart.vue'
import { goodsPage, goodsSave, overview } from '../../api'

const SKINS = ['干性', '油性', '混合', '敏感', '中性']
const TAGS = ['保湿', '舒缓', '抗皱', '美白', '控油', '祛痘', '修护', '防晒']
const q = reactive({ page: 1, size: 10, keyword: '', skin: '' })
const rows = ref([])
const total = ref(0)
const loading = ref(false)
const dlg = ref(false)
const saving = ref(false)
const form = reactive({})
const skinPick = ref([])
const tagPick = ref([])
const skinDist = ref([])

const split = (s) => (s ? String(s).split(',').map((x) => x.trim()).filter(Boolean) : [])

const skinOpt = computed(() => ({
  tooltip: { trigger: 'item' },
  legend: { bottom: 0, itemWidth: 8, itemHeight: 8, textStyle: { fontSize: 11 } },
  series: [{
    type: 'pie', radius: ['48%', '72%'], center: ['50%', '44%'],
    label: { show: true, fontSize: 10, formatter: '{b}\n{c}' },
    data: skinDist.value,
    itemStyle: { borderColor: '#fff', borderWidth: 2 }
  }],
  color: ['#7a5aa6', '#a98bc9', '#c4b0d8', '#e0b36a', '#8fb9a8']
}))

const load = async () => {
  loading.value = true
  try {
    const params = { ...q }
    if (q.skin) { params.skinType = q.skin; delete params.skin }
    const r = await goodsPage(params)
    rows.value = r.data.records || []
    total.value = r.data.total || 0
  } finally {
    loading.value = false
  }
}
const search = () => { q.page = 1; load() }
const reset = () => { q.keyword = ''; q.skin = ''; search() }

const open = (row) => {
  Object.keys(form).forEach((k) => delete form[k])
  Object.assign(form, row)
  skinPick.value = split(row.skinType)
  tagPick.value = split(row.effectTags)
  dlg.value = true
}

const save = async () => {
  if (!skinPick.value.length) return ElMessage.warning('至少选择一种适用肤质')
  if (form.isTrial === 1 && !form.isTrialConfigured) {
    // 后端会二次校验，这里先给明确提示
  }
  saving.value = true
  try {
    await goodsSave({ ...form, skinType: skinPick.value.join(','), effectTags: tagPick.value.join(',') })
    ElMessage.success('标签已更新')
    dlg.value = false
    load()
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  await load()
  try {
    const o = await overview()
    skinDist.value = o.data?.skinDist || []
  } catch (e) { /* 看板不可用时不影响本页 */ }
})
</script>
