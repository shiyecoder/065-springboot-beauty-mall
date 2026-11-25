<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">申领审核台</h3>
        <div class="page-sub">左侧为待审核队列，右侧展示申领理由、肤质档案与库存余量；驳回必须填写不少于 5 字的理由</div>
      </div>
      <div style="display: flex; gap: 10px; align-items: center">
        <el-tag type="warning" effect="plain">待审核 {{ total }} 单</el-tag>
        <el-button :icon="Refresh" size="small" @click="load">刷新队列</el-button>
      </div>
    </div>

    <div class="audit-wrap">
      <div class="card pick">
        <div class="card-hd">待审核队列 <span class="hint">按提交时间升序</span></div>
        <div class="q-list" v-loading="loading">
          <div v-for="r in rows" :key="r.id" class="q-item" :class="{ on: cur && cur.id === r.id }" @click="pick(r)">
            <img class="thumb" :src="r.goodsCover" alt="" />
            <div class="q-main">
              <div class="q-t">{{ r.goodsName }}</div>
              <div class="q-s">{{ r.userName }} · {{ r.skinType || '未建档' }} · {{ r.sampleSpec }}ml</div>
              <div class="q-s mono">{{ r.applyNo }}</div>
            </div>
            <div class="q-r">
              <div class="tag warn">{{ r.status }}</div>
              <div class="q-t2">{{ (r.createTime || '').slice(5, 16) }}</div>
            </div>
          </div>
          <el-empty v-if="!loading && !rows.length" description="队列已清空" :image-size="60" />
        </div>
        <div class="pager">
          <el-pagination small background layout="prev, pager, next" :total="total"
                         v-model:current-page="q.page" :page-size="q.size" @current-change="load" />
        </div>
      </div>

      <div class="card detail" v-if="cur">
        <div class="card-hd">
          <span>{{ cur.goodsName }} <span class="muted" style="font-weight: 400; font-size: 12px">{{ cur.brand }} · {{ cur.sampleSpec }}ml</span></span>
          <span class="tag warn">{{ cur.status }}</span>
        </div>

        <div class="g2">
          <div>
            <div class="sec-t">申领信息</div>
            <div class="kv">
              <div class="k">申领单号</div><div class="mono">{{ cur.applyNo }}</div>
              <div class="k">申领人</div><div>{{ cur.userName }}</div>
              <div class="k">肤质类型</div><div>{{ cur.skinType || '未建档' }}</div>
              <div class="k">提交时间</div><div>{{ cur.createTime }}</div>
              <div class="k">收货人</div><div>{{ cur.receiverName }} {{ cur.receiverPhone }}</div>
              <div class="k">收货地址</div><div>{{ cur.addressDesc }}</div>
            </div>
          </div>
          <div>
            <div class="sec-t">肤质档案</div>
            <div class="kv" v-if="cur.profile">
              <div class="k">敏感等级</div><div>{{ cur.profile.sensitiveLevel }}</div>
              <div class="k">诉求标签</div><div>{{ cur.profile.demandTags }}</div>
              <div class="k">过敏成分</div><div>{{ cur.profile.allergyIngredients || '无' }}</div>
              <div class="k">自测得分</div><div>{{ cur.profile.selfTestScore }} 分（{{ cur.profile.paperVersion }}）</div>
            </div>
            <el-empty v-else description="该用户未建档" :image-size="50" />
          </div>
        </div>

        <div class="sec-t">申领理由</div>
        <div class="note-box">{{ cur.applyReason }}</div>

        <div class="sec-t">库存与有效期</div>
        <div class="sum-row">
          <div><span class="muted">可派发余量</span><b>{{ cur.stockRemain ?? '-' }}</b> 件</div>
          <div><span class="muted">批次有效期</span><b>{{ cur.expireDate || '-' }}</b></div>
          <div><span class="muted">是否临期</span>
            <b :class="daysToExpire < 90 ? 'warn-t' : 'ok-t'">{{ daysToExpire < 0 ? '已过期' : daysToExpire + ' 天' }}</b>
          </div>
        </div>
        <div class="note-box warn" v-if="daysToExpire < 90">
          该批次距有效期不足 90 天，通过后请优先安排发放，避免过期报损。
        </div>

        <div class="sec-t">审核处理</div>
        <el-input v-model="remark" type="textarea" :rows="3" maxlength="200" show-word-limit
                  placeholder="审核备注（驳回时必填，不少于 5 字）" />
        <div class="acts">
          <el-button type="primary" :loading="busy" @click="doAudit(true)">审核通过</el-button>
          <el-button type="danger" plain :loading="busy" @click="doAudit(false)">驳回申领</el-button>
          <el-button plain @click="askProfile">要求补充肤质档案</el-button>
        </div>
      </div>

      <div class="card detail" v-else>
        <el-empty description="从左侧队列选择一条申领单开始审核" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { Refresh } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { applyPage, applyDetail, applyAudit, applyRequireProfile } from '../../api'

const q = reactive({ page: 1, size: 10, status: '待审核' })
const rows = ref([])
const total = ref(0)
const loading = ref(false)
const busy = ref(false)
const cur = ref(null)
const remark = ref('')

const daysToExpire = computed(() => {
  if (!cur.value?.expireDate) return 999
  return Math.ceil((new Date(cur.value.expireDate) - new Date()) / 86400000)
})

const load = async () => {
  loading.value = true
  try {
    const r = await applyPage(q)
    rows.value = r.data.records || []
    total.value = r.data.total || 0
    if (rows.value.length && (!cur.value || !rows.value.some((x) => x.id === cur.value.id))) {
      pick(rows.value[0])
    }
  } finally {
    loading.value = false
  }
}

const pick = async (r) => {
  const res = await applyDetail(r.id)
  cur.value = res.data
  remark.value = ''
}

const doAudit = async (pass) => {
  if (!pass && remark.value.trim().length < 5) return ElMessage.warning('驳回理由不少于 5 字')
  busy.value = true
  try {
    await applyAudit(cur.value.id, { pass, auditRemark: remark.value, reason: remark.value })
    ElMessage.success(pass ? '已通过，单据进入待发放' : '已驳回，已通知申领人')
    cur.value = null
    load()
  } finally {
    busy.value = false
  }
}

const askProfile = async () => {
  await applyRequireProfile(cur.value.id)
  ElMessage.success('已要求申领人补充肤质档案')
}

onMounted(load)
</script>

<style scoped>
.audit-wrap { display: grid; grid-template-columns: 360px 1fr; gap: 14px; align-items: start; }
.q-list { max-height: 620px; overflow: auto; }
.q-item { display: flex; gap: 10px; padding: 10px; border-radius: 8px; cursor: pointer; border: 1px solid transparent; }
.q-item:hover { background: #faf8fd; }
.q-item.on { background: var(--bt-primary-soft); border-color: #d9cdea; }
.q-main { flex: 1; min-width: 0; }
.q-t { font-size: 13px; font-weight: 600; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.q-s { font-size: 11px; color: var(--bt-text-3); margin-top: 2px; }
.q-r { text-align: right; }
.q-t2 { font-size: 11px; color: var(--bt-text-3); margin-top: 6px; }
.sec-t { font-size: 13px; font-weight: 600; margin: 16px 0 8px; color: var(--bt-text); }
.sec-t:first-of-type { margin-top: 4px; }
.sum-row { display: flex; gap: 28px; font-size: 13px; }
.sum-row b { font-size: 16px; margin: 0 4px; }
.ok-t { color: var(--bt-ok); }
.warn-t { color: var(--bt-warn); }
.acts { display: flex; gap: 10px; margin-top: 14px; }
.detail { min-height: 420px; }
</style>
