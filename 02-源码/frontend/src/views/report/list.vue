<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">报告审核</h3>
        <div class="page-sub">审核试用报告与晒图内容，含广告、竞品拉踩或与商品无关内容时隐藏并通知用户；审核人不得审核本人提交内容</div>
      </div>
      <el-button :icon="Refresh" @click="load">刷新</el-button>
    </div>

    <div class="filter-bar">
      <el-input v-model="q.keyword" placeholder="报告编号 / 商品 / 用户" clearable style="width: 220px" @keyup.enter="search" />
      <el-select v-model="q.status" placeholder="全部状态" clearable style="width: 180px">
        <el-option v-for="t in STATUS" :key="t" :label="t" :value="t" />
      </el-select>
      <el-button type="primary" :icon="Search" @click="search">查询</el-button>
      <el-button @click="reset">重置</el-button>
      <span class="muted" style="margin-left: auto; font-size: 12px">
        待审核 {{ pendingCount }} 份 · 报告须含使用天数、三项评分与不少于 30 字描述
      </span>
    </div>

    <div class="card">
      <el-table :data="rows" v-loading="loading" stripe>
        <el-table-column prop="reportNo" label="报告编号" width="150" />
        <el-table-column label="商品 / 申领单" min-width="200">
          <template #default="{ row }">
            <div>{{ row.goodsName }}</div>
            <div class="muted" style="font-size: 11px">{{ row.applyNo }}</div>
          </template>
        </el-table-column>
        <el-table-column prop="userName" label="提交人" width="110" />
        <el-table-column label="使用天数" width="90">
          <template #default="{ row }">{{ row.useDays }} 天</template>
        </el-table-column>
        <el-table-column label="吸收 / 温和 / 均分" width="160">
          <template #default="{ row }">
            <span class="stars">{{ star(row.absorbScore) }}</span>
            <span class="muted" style="margin: 0 4px">/</span>
            <span class="stars">{{ star(row.mildScore) }}</span>
            <div class="muted" style="font-size: 11px">均分 {{ row.avgScore }}</div>
          </template>
        </el-table-column>
        <el-table-column label="回购意愿" width="100">
          <template #default="{ row }"><span class="tag info">{{ row.repurchaseWill }}</span></template>
        </el-table-column>
        <el-table-column prop="content" label="报告内容" min-width="240" show-overflow-tooltip />
        <el-table-column label="配图" width="90">
          <template #default="{ row }">
            <span class="muted">{{ imgList(row.imageUrls).length || '无' }} 张</span>
          </template>
        </el-table-column>
        <el-table-column label="过敏" width="70">
          <template #default="{ row }">
            <span class="tag" :class="row.allergicFlag ? 'bad' : 'ok'">{{ row.allergicFlag ? '是' : '否' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="90">
          <template #default="{ row }"><span class="tag" :class="ST_CLS[row.status] || 'info'">{{ row.status }}</span></template>
        </el-table-column>
        <el-table-column label="操作" width="110" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="open(row)">查看</el-button>
            <el-button v-if="row.status === '待审核'" link type="primary" @click="open(row)">审核</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next, sizes" :total="total"
                       v-model:current-page="q.page" v-model:page-size="q.size"
                       :page-sizes="[10, 20, 50]" @current-change="load" @size-change="search" />
      </div>
    </div>

    <el-drawer v-model="drawer" title="试用报告详情" size="540px">
      <div v-if="cur">
        <div class="rp-head">
          <div>
            <div style="font-weight: 700; font-size: 15px">{{ cur.goodsName }}</div>
            <div class="muted" style="font-size: 12px; margin-top: 4px">{{ cur.reportNo }} · {{ cur.userName }} · 使用 {{ cur.useDays }} 天</div>
          </div>
          <span class="tag" :class="ST_CLS[cur.status] || 'info'">{{ cur.status }}</span>
        </div>

        <div class="score-cards">
          <div class="sc"><span>吸收感</span><b>{{ cur.absorbScore }}.0</b>{{ star(cur.absorbScore) }}</div>
          <div class="sc"><span>温和度</span><b>{{ cur.mildScore }}.0</b>{{ star(cur.mildScore) }}</div>
          <div class="sc"><span>平均分</span><b>{{ cur.avgScore }}</b><span class="muted">5 分制</span></div>
          <div class="sc"><span>回购意愿</span><b style="font-size: 15px">{{ cur.repurchaseWill }}</b><span class="muted">—</span></div>
        </div>

        <div class="dt-sec">报告正文<span class="muted" style="font-weight: 400; font-size: 12px">（{{ cur.contentLength || (cur.content || '').length }} 字）</span></div>
        <div class="note-box" style="line-height: 1.9">{{ cur.content }}</div>

        <div v-if="cur.allergicFlag" class="note-box warn" style="margin-top: 10px">
          <b>用户标记出现过敏反应</b>，需核对症状描述与商品成分后决定是否下架该批次。
        </div>

        <div class="dt-sec">使用前后照片</div>
        <div class="imgs">
          <el-image v-for="(u, i) in imgList(cur.imageUrls)" :key="i" :src="u" :preview-src-list="imgList(cur.imageUrls)"
                    fit="cover" class="rp-img" />
          <div v-if="!imgList(cur.imageUrls).length" class="muted" style="font-size: 12px">该报告未上传图片</div>
        </div>

        <div class="dt-sec">提交信息</div>
        <div class="kv">
          <span class="k">关联申领单</span><span>{{ cur.applyNo }}</span>
          <span class="k">发放时间</span><span>{{ fmt(cur.sendTime) }}</span>
          <span class="k">提交时间</span><span>{{ fmt(cur.createTime) }}</span>
          <span class="k">审核意见</span><span>{{ cur.auditRemark || '-' }}</span>
        </div>

        <div v-if="cur.status === '待审核'" class="audit-bar">
          <el-input v-model="remark" type="textarea" :rows="2" placeholder="审核意见：驳回或隐藏时必须说明原因（不少于 5 字）" />
          <div style="margin-top: 10px">
            <el-button type="primary" :loading="saving" @click="doAudit(true)">通过并计入转化</el-button>
            <el-button type="danger" plain :loading="saving" @click="doAudit(false)">驳回 / 隐藏</el-button>
          </div>
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { Search, Refresh } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { reportPage, reportAudit } from '../../api'

const STATUS = ['待审核', '已通过', '已驳回', '已隐藏']
const ST_CLS = { 待审核: 'warn', 已通过: 'ok', 已驳回: 'bad', 已隐藏: 'info' }

const q = reactive({ page: 1, size: 10, keyword: '', status: '' })
const rows = ref([])
const total = ref(0)
const pendingCount = ref(0)
const loading = ref(false)
const drawer = ref(false)
const cur = ref(null)
const remark = ref('')
const saving = ref(false)

const imgList = (s) => (s ? String(s).split(',').filter(Boolean) : [])
const star = (n) => '★'.repeat(n || 0) + '☆'.repeat(Math.max(0, 5 - (n || 0)))
const fmt = (t) => (t ? String(t).replace('T', ' ').slice(0, 16) : '-')

const load = async () => {
  loading.value = true
  try {
    const r = await reportPage(q)
    rows.value = r.data.records || []
    total.value = r.data.total || 0
    const p = await reportPage({ page: 1, size: 1, status: '待审核' })
    pendingCount.value = p.data.total || 0
  } finally {
    loading.value = false
  }
}
const search = () => { q.page = 1; load() }
const reset = () => { q.keyword = ''; q.status = ''; search() }

// 列表返回的字段已覆盖详情所需内容，直接复用行数据，避免额外请求
const open = (row) => {
  cur.value = row
  remark.value = ''
  drawer.value = true
}

const doAudit = async (pass) => {
  if (!pass && (!remark.value || remark.value.length < 5)) {
    return ElMessage.warning('驳回或隐藏必须填写不少于 5 字的说明')
  }
  saving.value = true
  try {
    await reportAudit(cur.value.id, { pass, remark: remark.value })
    ElMessage.success(pass ? '已通过，计入转化统计' : '已驳回，已通知用户')
    drawer.value = false
    load()
  } finally {
    saving.value = false
  }
}

onMounted(load)
</script>

<style scoped>
.rp-head { display: flex; justify-content: space-between; align-items: flex-start; padding-bottom: 12px; border-bottom: 1px solid var(--bt-line); }
.score-cards { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin: 14px 0; }
.sc { background: var(--bt-primary-soft); border-radius: 8px; padding: 10px; text-align: center; }
.sc span { display: block; font-size: 11px; color: var(--bt-text-3); }
.sc b { display: block; font-size: 20px; margin: 4px 0 2px; color: var(--bt-primary); }
.stars { color: var(--bt-accent); letter-spacing: 1px; }
.dt-sec { font-weight: 600; font-size: 13px; margin: 16px 0 10px; padding-left: 8px; border-left: 3px solid var(--bt-primary); }
.imgs { display: flex; gap: 8px; flex-wrap: wrap; }
.rp-img { width: 104px; height: 78px; border-radius: 8px; background: #f0edf6; }
.audit-bar { margin-top: 18px; padding-top: 14px; border-top: 1px dashed var(--bt-line); }
</style>
