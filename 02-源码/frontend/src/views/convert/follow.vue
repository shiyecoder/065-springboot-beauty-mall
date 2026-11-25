<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">用户跟进</h3>
        <div class="page-sub">按转化概率排序触达，登记跟进结果或对结果做人工修正（需填不少于 5 字原因，原始结果保留）</div>
      </div>
      <el-button :icon="Refresh" @click="load">刷新</el-button>
    </div>

    <div class="filter-bar">
      <el-input v-model="q.keyword" placeholder="用户 / 商品 / 跟踪号" clearable style="width: 220px" @keyup.enter="search" />
      <el-select v-model="q.level" placeholder="全部意向" clearable style="width: 180px">
        <el-option v-for="t in LEVELS" :key="t" :label="t" :value="t" />
      </el-select>
      <el-select v-model="q.followStatus" placeholder="全部跟进状态" clearable style="width: 180px">
        <el-option v-for="t in FOLLOWS" :key="t" :label="t" :value="t" />
      </el-select>
      <el-button type="primary" :icon="Search" @click="search">查询</el-button>
      <el-button @click="reset">重置</el-button>
      <span class="muted" style="margin-left: auto; font-size: 12px">共 {{ total }} 条跟踪记录</span>
    </div>

    <div class="card">
      <el-table :data="rows" v-loading="loading" stripe>
        <el-table-column label="商品" width="72">
          <template #default="{ row }"><img v-if="row.goodsCover" class="thumb" :src="row.goodsCover" alt="" /></template>
        </el-table-column>
        <el-table-column label="用户 / 跟踪号" width="160">
          <template #default="{ row }">
            <div style="font-weight: 600">{{ row.userName }}</div>
            <div class="muted" style="font-size: 11px">{{ row.trackNo }}</div>
          </template>
        </el-table-column>
        <el-table-column prop="goodsName" label="试用商品" min-width="180" show-overflow-tooltip />
        <el-table-column label="浏览 / 加购" width="120">
          <template #default="{ row }">{{ row.browseMin }} 分 / {{ row.cartTimes }} 次</template>
        </el-table-column>
        <el-table-column label="转化分" width="150" sortable :sort-by="(r) => r.convertScore">
          <template #default="{ row }">
            <div class="score-cell">
              <b>{{ row.convertScore }}</b>
              <span class="tag" :class="row.convertLevel === '高意向' ? 'ok' : row.convertLevel === '中意向' ? 'warn' : 'info'">{{ row.convertLevel }}</span>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="跟进状态" width="110">
          <template #default="{ row }">
            <span class="tag" :class="F_CLS[row.followStatus] || 'info'">{{ row.followStatus }}</span>
          </template>
        </el-table-column>
        <el-table-column label="归因" width="110">
          <template #default="{ row }">
            <span v-if="row.orderId" class="tag ok">已归因</span>
            <span v-else-if="row.inWindow" class="tag info">窗口内</span>
            <span v-else class="muted">已超窗</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openScore(row)">算分明细</el-button>
            <el-button link type="primary" @click="openFollow(row)">登记跟进</el-button>
            <el-button link type="warning" @click="openCorrect(row)">修正</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next, sizes" :total="total"
                       v-model:current-page="q.page" v-model:page-size="q.size"
                       :page-sizes="[10, 20, 50]" @current-change="load" @size-change="search" />
      </div>
    </div>

    <el-drawer v-model="scoreDrawer" title="转化概率计算明细" size="520px">
      <div v-if="sc">
        <div class="sc-head">
          <div>
            <div class="muted" style="font-size: 12px">{{ sc.snapNo }} · 规则 {{ sc.ruleVersion }} · 快照可追溯</div>
            <div class="sc-total">{{ sc.totalScore }}<small>分</small></div>
          </div>
          <span class="tag" :class="sc.level === '高意向' ? 'ok' : sc.level === '中意向' ? 'warn' : 'info'" style="font-size: 13px">{{ sc.level }}</span>
        </div>
        <div class="note-box" style="margin: 14px 0">{{ sc.conclusion }}</div>
        <div class="dt-sec">五因素明细</div>
        <div v-for="f in sc.factors" :key="f.name" class="ft">
          <div class="ft-h"><span>{{ f.name }}</span><span class="muted">权重 {{ f.weight }}%</span></div>
          <div class="ft-bar"><i :style="{ width: Math.min(100, f.score) + '%' }"></i></div>
          <div class="ft-d"><span class="muted">{{ f.detail }}</span><b>{{ f.score }} → {{ f.weighted }}</b></div>
        </div>
        <div class="dt-sec">未满足条件</div>
        <div v-if="!sc.unmet || !sc.unmet.length" class="muted" style="font-size: 12px">无</div>
        <div v-for="(u, i) in sc.unmet || []" :key="i" class="note-box warn" style="margin-bottom: 8px">{{ u }}</div>
      </div>
    </el-drawer>

    <el-dialog v-model="followDlg" title="登记跟进结果" width="480px">
      <el-form :model="ff" label-width="92px">
        <el-form-item label="跟进状态">
          <el-select v-model="ff.followStatus" style="width: 100%">
            <el-option v-for="t in FOLLOWS" :key="t" :label="t" :value="t" />
          </el-select>
        </el-form-item>
        <el-form-item label="关联订单号">
          <el-input v-model="ff.orderNo" placeholder="用户已下单时填写，用于归因" />
        </el-form-item>
        <el-form-item label="跟进说明">
          <el-input v-model="ff.remark" type="textarea" :rows="3" placeholder="触达方式、用户反馈、下一步计划" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="followDlg = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="submitFollow">保存</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="correctDlg" title="人工修正转化结果" width="480px">
      <div class="note-box" style="margin-bottom: 14px">
        当前系统结论：<b>{{ curRow?.convertLevel }}</b>（{{ curRow?.convertScore }} 分）。修正后原始计算结果保留，不被覆盖，修正率将计入规则效果统计。
      </div>
      <el-form :model="cf" label-width="92px">
        <el-form-item label="修正为">
          <el-radio-group v-model="cf.afterLevel">
            <el-radio-button v-for="t in LEVELS" :key="t" :label="t">{{ t }}</el-radio-button>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="修正原因">
          <el-input v-model="cf.reason" type="textarea" :rows="3" placeholder="不少于 5 字，例如：用户已线下门店购买，系统未采集到订单" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="correctDlg = false">取消</el-button>
        <el-button type="warning" :loading="saving" @click="submitCorrect">提交修正</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { Search, Refresh } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { useRoute } from 'vue-router'
import { trackPage, trackScore, trackFollow, trackCorrect } from '../../api'

const route = useRoute()
const LEVELS = ['高意向', '中意向', '低意向']
const FOLLOWS = ['未跟进', '已触达', '已下单', '已放弃']
const F_CLS = { 未跟进: 'info', 已触达: 'warn', 已下单: 'ok', 已放弃: 'bad' }

const q = reactive({ page: 1, size: 10, keyword: '', level: '', followStatus: '' })
const rows = ref([])
const total = ref(0)
const loading = ref(false)
const saving = ref(false)
const scoreDrawer = ref(false)
const followDlg = ref(false)
const correctDlg = ref(false)
const sc = ref(null)
const curRow = ref(null)
const ff = reactive({ followStatus: '已触达', orderNo: '', remark: '' })
const cf = reactive({ afterLevel: '中意向', reason: '' })

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
const reset = () => { q.keyword = ''; q.level = ''; q.followStatus = ''; search() }

const openScore = async (row) => {
  sc.value = (await trackScore(row.id)).data
  scoreDrawer.value = true
}
const openFollow = (row) => {
  curRow.value = row
  Object.assign(ff, { followStatus: '已触达', orderNo: '', remark: '' })
  followDlg.value = true
}
const openCorrect = (row) => {
  curRow.value = row
  Object.assign(cf, { afterLevel: row.convertLevel, reason: '' })
  correctDlg.value = true
}

const submitFollow = async () => {
  saving.value = true
  try {
    await trackFollow(curRow.value.id, { ...ff })
    ElMessage.success('跟进结果已登记')
    followDlg.value = false
    load()
  } finally {
    saving.value = false
  }
}
const submitCorrect = async () => {
  if (!cf.reason || cf.reason.length < 5) return ElMessage.warning('修正原因不少于 5 字')
  saving.value = true
  try {
    await trackCorrect(curRow.value.id, { ...cf })
    ElMessage.success('已修正，原始结果已保留')
    correctDlg.value = false
    load()
  } finally {
    saving.value = false
  }
}

onMounted(() => {
  if (route.query.level) q.level = route.query.level
  if (route.query.id) q.keyword = ''
  load()
})
</script>

<style scoped>
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
