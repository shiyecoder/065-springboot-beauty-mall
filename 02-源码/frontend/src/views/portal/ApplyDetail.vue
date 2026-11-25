<template>
  <div class="wrap" v-loading="loading">
    <div class="crumb"><router-link to="/portal/my">我的试用</router-link> / 申领详情</div>

    <div class="card" v-if="a">
      <div class="hd">
        <div>
          <div class="no mono">申领单 {{ a.applyNo }}</div>
          <h2>{{ a.goodsName }}</h2>
          <div class="muted">{{ a.brand }} · 小样 {{ a.sampleSpec }}ml · 提交于 {{ fmt(a.createTime) }}</div>
        </div>
        <span class="tag" :class="ST[a.status] || 'info'" style="font-size: 13px; padding: 5px 12px">{{ a.status }}</span>
      </div>

      <div class="flow">
        <div v-for="(s, i) in steps" :key="s.k" class="st" :class="{ on: i <= curStep, done: i < curStep }">
          <div class="dot">{{ i < curStep ? '✓' : i + 1 }}</div>
          <div class="lb">{{ s.t }}</div>
          <div class="tm">{{ s.time || '—' }}</div>
        </div>
      </div>

      <div class="g21" style="margin-top: 6px">
        <div>
          <div class="sec">商品与批次</div>
          <div class="goods">
            <img :src="a.goodsCover" alt="" />
            <div>
              <div class="nm">{{ a.goodsName }}</div>
              <div class="muted" style="font-size: 12px">小样编号 {{ a.sampleNo }} · 规格 {{ a.sampleSpec }}ml</div>
              <div class="muted" style="font-size: 12px">申领理由：{{ a.applyReason || '—' }}</div>
            </div>
          </div>

          <div class="sec">收件信息</div>
          <div class="kvs">
            <div><span>收件人</span><b>{{ a.receiverName }}</b></div>
            <div><span>手机号</span><b>{{ a.receiverPhone }}</b></div>
            <div><span>地址</span><b>{{ a.addressDesc }}</b></div>
            <div><span>快递</span><b>{{ a.expressCompany || '—' }} {{ a.expressNo || '' }}</b></div>
            <div><span>寄出时间</span><b>{{ fmt(a.sendTime) }}</b></div>
          </div>
        </div>

        <div>
          <div class="sec">肤质档案（审核依据）</div>
          <div class="kvs" v-if="a.profile">
            <div><span>肤质</span><b>{{ a.profile.skinType }}</b></div>
            <div><span>敏感度</span><b>{{ a.profile.sensitiveLevel }}</b></div>
            <div><span>诉求</span><b>{{ a.profile.demandTags }}</b></div>
            <div><span>自测分</span><b class="price">{{ a.profile.selfTestScore }}</b></div>
          </div>
          <el-empty v-else :image-size="50" description="无档案" />

          <div class="sec">审核意见</div>
          <div class="note-box">{{ a.auditRemark || (a.status === '待审核' ? '审核员将在 24 小时内处理，请留意站内消息' : '无') }}</div>

          <div class="acts">
            <el-button v-if="a.status === '待提交报告' || a.status === '已发放'" type="primary" @click="$router.push(`/portal/report/${a.id}`)">
              提交试用报告
            </el-button>
            <el-button v-if="a.report" @click="$router.push(`/portal/report/${a.id}`)">查看已提交报告</el-button>
            <el-button v-if="a.status === '已完成'" type="primary" plain @click="$router.push(`/portal/checkout/${a.goodsId}?apply=${a.id}`)">
              以 9 折入手正装
            </el-button>
            <el-button @click="$router.push('/portal/trial')">继续逛逛</el-button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { applyDetail } from '../../api'
import { fmt } from '../../utils/format'

const route = useRoute()
const a = ref(null)
const loading = ref(false)

// 状态机：待审核 → 待发放 → 已发放/待提交报告 → 已完成，已驳回为异常分支
const ST = { 待审核: 'warn', 已驳回: 'bad', 待发放: 'info', 已发放: 'info', 待提交报告: 'warn', 已完成: 'ok' }

const steps = computed(() => [
  { t: '提交申领', time: fmt(a.value?.createTime) },
  { t: '审核', time: a.value?.auditTime ? fmt(a.value.auditTime) : '' },
  { t: '寄出', time: fmt(a.value?.sendTime) },
  { t: '提交报告', time: a.value?.report ? fmt(a.value.report.createTime) : '' },
  { t: '完成', time: a.value?.finishTime ? fmt(a.value.finishTime) : '' }
])

const curStep = computed(() => {
  const s = a.value?.status
  if (!s) return 0
  return { 待审核: 0, 已驳回: 1, 待发放: 1, 已发放: 2, TO_REPORT: 2, 待提交报告: 2, 已完成: 4 }[s] ?? 1
})

onMounted(async () => {
  loading.value = true
  try {
    const r = await applyDetail(route.params.id)
    a.value = r.data
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.wrap { width: 1060px; margin: 0 auto; padding: 22px 0 46px; }
.crumb { font-size: 12px; color: var(--bt-text-3); margin-bottom: 14px; }
.crumb a { color: var(--bt-text-3); }
.hd { display: flex; justify-content: space-between; align-items: flex-start; padding-bottom: 16px; border-bottom: 1px solid var(--bt-line); }
.no { font-size: 11px; color: var(--bt-text-3); }
.hd h2 { font-size: 22px; margin: 6px 0 4px; }
.flow { display: flex; gap: 8px; padding: 22px 0 8px; }
.st { flex: 1; text-align: center; position: relative; }
.st .dot { width: 26px; height: 26px; border-radius: 50%; background: #efeaf6; color: var(--bt-text-3); display: grid; place-items: center; margin: 0 auto 7px; font-size: 12px; }
.st.on .dot { background: var(--bt-primary); color: #fff; }
.st.done .dot { background: #e7dcf5; color: var(--bt-primary); }
.st .lb { font-size: 12px; color: var(--bt-text-2); }
.st .tm { font-size: 10px; color: var(--bt-text-3); margin-top: 3px; }
.sec { font-size: 13px; font-weight: 600; margin: 18px 0 10px; padding-left: 8px; box-shadow: inset 3px 0 0 var(--bt-primary); }
.goods { display: flex; gap: 12px; background: #faf8fd; border-radius: 10px; padding: 12px; }
.goods img { width: 64px; height: 64px; border-radius: 8px; object-fit: cover; }
.nm { font-size: 14px; font-weight: 600; margin-bottom: 4px; }
.kvs > div { display: flex; padding: 6px 0; border-bottom: 1px dashed var(--bt-line); font-size: 13px; }
.kvs span { width: 86px; color: var(--bt-text-3); flex: none; }
.acts { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 18px; }
</style>
