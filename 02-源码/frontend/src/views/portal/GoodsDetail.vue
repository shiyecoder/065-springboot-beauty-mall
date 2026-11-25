<template>
  <div class="wrap" v-loading="loading">
    <div class="crumb">
      <router-link to="/portal/home">首页</router-link> / <router-link to="/portal/trial">试用活动</router-link> / 商品详情
    </div>

    <div class="main" v-if="g">
      <div class="gal">
        <img class="big" :src="g.coverImage" alt="" />
        <div class="thumbs">
          <img v-for="(s, i) in sampleList.slice(0, 4)" :key="i" :src="s.goodsCover || g.coverImage" alt="" />
        </div>
      </div>

      <div class="info">
        <div class="brand">{{ g.brand }}</div>
        <h1>{{ g.goodsName }}</h1>
        <div class="tags">
          <span class="tag ok">{{ g.goodsType }}</span>
          <span class="tag info" v-for="t in effectList" :key="t">{{ t }}</span>
          <span class="tag warn" v-if="g.isTrial">可领试用装</span>
        </div>
        <div class="price-row">
          <span class="price lg">¥{{ money(g.salePrice) }}</span>
          <span class="muted">规格 {{ g.specMl }}ml · 库存 {{ g.stockQty }}</span>
        </div>

        <div class="kv">
          <div><span>适合肤质</span><b>{{ g.skinType }}</b></div>
          <div><span>商品编号</span><b class="mono">{{ g.goodsNo }}</b></div>
          <div><span>当前状态</span><b>{{ g.status }}</b></div>
        </div>

        <div class="buy">
          <el-input-number v-model="qty" :min="1" :max="Math.max(1, g.stockQty)" />
          <el-button type="primary" size="large" :disabled="g.status !== '在售'" @click="buy">立即购买</el-button>
          <el-button size="large" :disabled="!trialSku" @click="applyTrial">
            {{ trialSku ? '免费领小样' : '暂无小样' }}
          </el-button>
        </div>

        <div class="serv">
          <span>顺丰包邮</span><span>7 天无理由</span><span>正品保障</span><span>试用报告可叠加 9 折</span>
        </div>
      </div>
    </div>

    <div class="blocks" v-if="g">
      <div class="card">
        <div class="card-hd"><span>试用装批次</span><span class="muted" style="font-size: 12px">每人每批次限领 1 份</span></div>
        <el-table :data="sampleList">
          <el-table-column prop="sampleNo" label="小样编号" width="160">
            <template #default="{ row }"><span class="mono">{{ row.sampleNo }}</span></template>
          </el-table-column>
          <el-table-column prop="specMl" label="规格(ml)" width="100" />
          <el-table-column prop="batchNo" label="批次号" width="150" />
          <el-table-column label="效期" width="130">
            <template #default="{ row }"><span :class="{ 'warn-t': row.expiring }">{{ fmtDate(row.expireDate) }}</span></template>
          </el-table-column>
          <el-table-column label="剩余" width="110">
            <template #default="{ row }">{{ row.remainQty }} / {{ row.totalQty }}</template>
          </el-table-column>
          <el-table-column label="状态" width="100">
            <template #default="{ row }"><span class="tag" :class="row.status === '可派发' ? 'ok' : 'info'">{{ row.status }}</span></template>
          </el-table-column>
        </el-table>
      </div>

      <div class="card" style="margin-top: 14px">
        <div class="card-hd"><span>试用建议</span></div>
        <div class="advice">
          <p><b>用量</b>小样 {{ trialSku?.specMl || 5 }}ml，早晚各一次可用 7 天左右，建议连续使用观察屏障变化。</p>
          <p><b>顺序</b>洁面 → 爽肤水 → 精华/面霜 → 防晒。敏感肌首次使用先做耳后测试。</p>
          <p><b>记录</b>收到后第 7 天提交试用报告（吸收度、温和度、回购意愿），审核通过后正装自动 9 折。</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { goodsDetail, samplePage, applyCreate, myProfile } from '../../api'
import { store } from '../../store/user'
import { money, fmtDate } from '../../utils/format'

const route = useRoute()
const router = useRouter()
const g = ref(null)
const sampleList = ref([])
const qty = ref(1)
const loading = ref(false)
const profile = ref(null)

const effectList = computed(() => (g.value?.effectTags || '').split(',').filter(Boolean))
const trialSku = computed(() => sampleList.value.find((s) => s.remainQty > 0 && s.status === '可派发'))

const load = async () => {
  loading.value = true
  try {
    const r = await goodsDetail(route.params.id)
    g.value = r.data
    sampleList.value = r.data.samples || []
    if (!sampleList.value.length) {
      const s = await samplePage({ page: 1, size: 50, goodsId: route.params.id })
      sampleList.value = s.data.records || []
    }
  } finally {
    loading.value = false
  }
}

const buy = () => router.push(`/portal/checkout/${g.value.id}?qty=${qty.value}`)

const applyTrial = async () => {
  if (!profile.value) {
    ElMessage.warning('请先完成肤质测评建档')
    return router.push('/portal/skin-test')
  }
  loading.value = true
  try {
    const r = await applyCreate({
      sampleId: trialSku.value.id,
      applyReason: `肤质${profile.value.skinType}，本单品效期与诉求匹配，希望先试用再决定`,
      receiverName: store.user?.realName || '',
      receiverPhone: store.user?.phone || '13800000000',
      addressDesc: '请在个人中心完善收件地址'
    })
    ElMessage.success('申领已提交')
    router.push(`/portal/apply/${r.data.id ?? r.data}`)
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  await load()
  try {
    const p = await myProfile()
    profile.value = p.data || null
  } catch (e) {
    profile.value = null
  }
})
</script>

<style scoped>
.wrap { width: 1160px; margin: 0 auto; padding: 22px 0 44px; }
.crumb { font-size: 12px; color: var(--bt-text-3); margin-bottom: 16px; }
.crumb a { color: var(--bt-text-3); }
.main { display: flex; gap: 36px; }
.gal { width: 440px; flex: none; }
.big { width: 440px; height: 420px; object-fit: cover; border-radius: 16px; background: #f7f3fb; }
.thumbs { display: flex; gap: 8px; margin-top: 10px; }
.thumbs img { width: 76px; height: 76px; object-fit: cover; border-radius: 8px; border: 1px solid var(--bt-line); }
.info { flex: 1; }
.brand { font-size: 12px; letter-spacing: 1.6px; color: var(--bt-text-3); }
.info h1 { font-size: 27px; margin: 8px 0 12px; }
.tags { display: flex; gap: 7px; margin-bottom: 16px; flex-wrap: wrap; }
.price-row { display: flex; align-items: baseline; gap: 14px; padding: 14px 16px; background: #faf8fd; border-radius: 12px; }
.price.lg { font-size: 28px; }
.kv { margin: 18px 0; font-size: 13px; }
.kv > div { display: flex; padding: 6px 0; border-bottom: 1px dashed var(--bt-line); }
.kv span { width: 100px; color: var(--bt-text-3); }
.buy { display: flex; gap: 10px; align-items: center; margin: 20px 0 16px; }
.serv { display: flex; gap: 16px; font-size: 12px; color: var(--bt-text-3); }
.warn-t { color: #c9741f; }
.blocks { margin-top: 30px; }
.advice p { font-size: 13px; color: var(--bt-text-2); line-height: 1.9; margin: 0 0 8px; }
.advice b { display: inline-block; width: 44px; color: var(--bt-primary); }
</style>
