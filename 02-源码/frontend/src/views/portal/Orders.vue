<template>
  <div class="wrap">
    <div class="hd">
      <div>
        <h2>我的订单</h2>
        <p>试用报告通过后 30 天内下单自动 9 折；未支付订单 24 小时后自动取消</p>
      </div>
    </div>

    <div class="tabs">
      <span v-for="t in TABS" :key="t.v" class="tb" :class="{ on: tab === t.v }" @click="pick(t.v)">{{ t.t }}</span>
    </div>

    <div v-loading="loading">
      <div v-for="o in rows" :key="o.id" class="ord">
        <div class="oh">
          <span class="mono">{{ o.orderNo }}</span>
          <span class="muted">{{ fmt(o.createTime) }}</span>
          <span class="tag" :class="ST[o.status] || 'info'" style="margin-left: auto">{{ o.status }}</span>
        </div>
        <div class="ob">
          <img :src="o.goodsCover" alt="" />
          <div class="bd">
            <div class="nm">{{ o.goodsName }}</div>
            <div class="meta">{{ o.goodsType }} · 数量 {{ o.buyQty }}</div>
            <div class="meta" v-if="o.sourceApplyNo">
              来自试用 {{ o.sourceApplyNo }}
              <span class="tag ok" v-if="o.inWindow" style="margin-left: 6px">报告归属期内 9 折</span>
            </div>
          </div>
          <div class="amt">
            <div class="price">¥{{ money(o.payAmount) }}</div>
            <div class="muted" style="font-size: 11px" v-if="Number(o.discountAmount) > 0">已优惠 ¥{{ money(o.discountAmount) }}</div>
          </div>
          <div class="ops">
            <el-button v-if="o.status === '待支付'" type="primary" size="small" @click="pay(o)">去支付</el-button>
            <el-button v-if="['待支付', '待发货'].includes(o.status)" size="small" @click="cancel(o)">取消</el-button>
            <el-button v-if="['待发货', '已发货', '已完成'].includes(o.status)" size="small" @click="refund(o)">申请退款</el-button>
          </div>
        </div>
      </div>
      <el-empty v-if="!rows.length && !loading" description="还没有订单">
        <el-button type="primary" @click="$router.push('/portal/home')">去逛逛</el-button>
      </el-empty>
    </div>

    <div class="pager" style="padding-bottom: 40px">
      <el-pagination background layout="total, prev, pager, next" :total="total"
                     v-model:current-page="q.page" :page-size="q.size" @current-change="load" />
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { orderPage, orderPay, orderCancel, orderRefund } from '../../api'
import { fmt, money } from '../../utils/format'

const ST = { 待支付: 'warn', 待发货: 'info', 已发货: 'info', 已完成: 'ok', 已取消: 'info', 已退款: 'bad' }
const TABS = [
  { t: '全部', v: '' },
  { t: '待支付', v: '待支付' },
  { t: '待发货', v: '待发货' },
  { t: '已发货', v: '已发货' },
  { t: '已完成', v: '已完成' }
]

const tab = ref('')
const q = reactive({ page: 1, size: 10, status: '' })
const rows = ref([])
const total = ref(0)
const loading = ref(false)

const load = async () => {
  loading.value = true
  try {
    const r = await orderPage(q)
    rows.value = r.data.records || []
    total.value = r.data.total || 0
  } finally {
    loading.value = false
  }
}
const pick = (v) => {
  tab.value = v
  q.status = v
  q.page = 1
  load()
}

const pay = async (o) => {
  await ElMessageBox.confirm(`确认支付 ¥${money(o.payAmount)}？演示环境不接真实支付。`, '确认支付', { type: 'info' })
  await orderPay(o.id, { payType: o.payType || '微信支付' })
  ElMessage.success('支付成功')
  load()
}

const cancel = async (o) => {
  await ElMessageBox.confirm('取消后库存将释放，确认取消该订单？', '提示', { type: 'warning' })
  await orderCancel(o.id)
  ElMessage.success('订单已取消')
  load()
}

const refund = async (o) => {
  const { value } = await ElMessageBox.prompt('请填写退款原因（不少于 5 字）', '申请退款', {
    inputPlaceholder: '如：收到的包装破损',
    inputValidator: (v) => (v && v.trim().length >= 5) || '原因至少 5 字'
  })
  await orderRefund(o.id, { reason: value })
  ElMessage.success('退款申请已提交')
  load()
}

onMounted(load)
</script>

<style scoped>
.wrap { width: 1000px; margin: 0 auto; padding: 28px 0 20px; }
.hd h2 { font-size: 22px; margin: 0 0 6px; }
.hd p { font-size: 12px; color: var(--bt-text-3); margin: 0 0 16px; }
.tabs { display: flex; gap: 20px; border-bottom: 1px solid var(--bt-line); margin-bottom: 12px; }
.tb { font-size: 13px; color: var(--bt-text-2); padding: 8px 0; cursor: pointer; }
.tb.on { color: var(--bt-primary); font-weight: 600; box-shadow: inset 0 -2px 0 var(--bt-primary); }
.ord { border: 1px solid var(--bt-line); border-radius: 12px; margin-bottom: 12px; overflow: hidden; }
.oh { display: flex; gap: 16px; align-items: center; padding: 9px 14px; background: #faf8fd; font-size: 12px; color: var(--bt-text-2); }
.ob { display: flex; gap: 14px; align-items: center; padding: 14px; }
.ob img { width: 68px; height: 68px; border-radius: 8px; object-fit: cover; background: #f7f3fb; }
.bd { flex: 1; min-width: 0; }
.nm { font-size: 14px; font-weight: 600; }
.meta { font-size: 12px; color: var(--bt-text-3); margin-top: 4px; }
.amt { text-align: right; width: 110px; }
.ops { width: 150px; display: flex; flex-wrap: wrap; gap: 6px; justify-content: flex-end; }
</style>
