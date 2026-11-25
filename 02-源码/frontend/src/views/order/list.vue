<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">正装订单</h3>
        <div class="page-sub">只登记支付方式与支付状态，不调用真实支付；支付超时 30 分钟自动取消并回补库存</div>
      </div>
      <el-button :icon="Refresh" @click="load">刷新</el-button>
    </div>

    <div class="kpi-grid" style="grid-template-columns: repeat(4, 1fr)">
      <div class="kpi"><div class="lb">订单总数</div><div class="vl">{{ total }}<small>单</small></div></div>
      <div class="kpi"><div class="lb">待发货</div><div class="vl" style="color: var(--bt-warn)">{{ cnt('待发货') }}<small>单</small></div></div>
      <div class="kpi"><div class="lb">已完成销售额</div><div class="vl">¥{{ sales.toFixed(0) }}</div></div>
      <div class="kpi"><div class="lb">退款订单</div><div class="vl" style="color: var(--bt-bad)">{{ cnt('已退款') }}<small>单</small></div></div>
    </div>

    <div class="filter-bar">
      <el-input v-model="q.keyword" placeholder="订单号 / 商品 / 用户" clearable style="width: 220px" @keyup.enter="search" />
      <el-select v-model="q.status" placeholder="全部状态" clearable style="width: 160px">
        <el-option v-for="t in STATUS" :key="t" :label="t" :value="t" />
      </el-select>
      <el-select v-model="q.payType" placeholder="全部支付方式" clearable style="width: 180px">
        <el-option v-for="t in PAYS" :key="t" :label="t" :value="t" />
      </el-select>
      <el-button type="primary" :icon="Search" @click="search">查询</el-button>
      <el-button @click="reset">重置</el-button>
    </div>

    <div class="card">
      <el-table :data="rows" v-loading="loading" stripe>
        <el-table-column label="商品" width="72">
          <template #default="{ row }"><img v-if="row.goodsCover" class="thumb" :src="row.goodsCover" alt="" /></template>
        </el-table-column>
        <el-table-column prop="orderNo" label="订单号" width="150" />
        <el-table-column prop="userName" label="下单人" width="100" />
        <el-table-column label="商品" min-width="190">
          <template #default="{ row }">
            <div>{{ row.goodsName }}</div>
            <div class="muted" style="font-size: 11px">{{ row.goodsType }} · {{ row.buyQty }} 件</div>
          </template>
        </el-table-column>
        <el-table-column label="金额" width="130">
          <template #default="{ row }">
            <div class="price">¥{{ row.payAmount }}</div>
            <div v-if="row.discountAmount > 0" class="muted" style="font-size: 11px">优惠 ¥{{ row.discountAmount }}</div>
          </template>
        </el-table-column>
        <el-table-column label="来源申领" width="140">
          <template #default="{ row }">
            <span v-if="row.sourceApplyId" class="tag ok">归因 #{{ row.sourceApplyId }}</span>
            <span v-else class="muted">自然流量</span>
          </template>
        </el-table-column>
        <el-table-column prop="payType" label="支付方式" width="100" />
        <el-table-column label="支付状态" width="100">
          <template #default="{ row }">
            <span class="tag" :class="row.payStatus === '已支付' ? 'ok' : row.payStatus === '已退款' ? 'bad' : 'warn'">{{ row.payStatus }}</span>
          </template>
        </el-table-column>
        <el-table-column label="订单状态" width="100">
          <template #default="{ row }"><span class="tag" :class="ST_CLS[row.status] || 'info'">{{ row.status }}</span></template>
        </el-table-column>
        <el-table-column label="下单时间" width="150">
          <template #default="{ row }">{{ fmt(row.createTime) }}</template>
        </el-table-column>
        <el-table-column label="操作" width="140" fixed="right">
          <template #default="{ row }">
            <el-button v-if="row.status === '待支付'" link type="primary" @click="pay(row)">确认支付</el-button>
            <el-button v-if="row.status === '待发货'" link type="primary" @click="ship(row)">发货</el-button>
            <el-button v-if="row.status === '待支付'" link type="danger" @click="cancel(row)">取消</el-button>
            <el-button v-if="['已发货', '已完成'].includes(row.status)" link type="danger" @click="refund(row)">退款</el-button>
          </template>
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
import { ref, reactive, computed, onMounted } from 'vue'
import { Search, Refresh } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { orderPage, orderPay, orderShip, orderCancel, orderRefund } from '../../api'

const STATUS = ['待支付', '待发货', '已发货', '已完成', '已退款', '已取消']
const PAYS = ['微信', '支付宝', '储值卡']
const ST_CLS = { 待支付: 'warn', 待发货: 'info', 已发货: 'info', 已完成: 'ok', 已退款: 'bad', 已取消: 'info' }

const q = reactive({ page: 1, size: 10, keyword: '', status: '', payType: '' })
const rows = ref([])
const total = ref(0)
const loading = ref(false)

const cnt = (s) => rows.value.filter((r) => r.status === s).length
const sales = computed(() => rows.value.filter((r) => r.status === '已完成').reduce((s, r) => s + Number(r.payAmount || 0), 0))

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
const search = () => { q.page = 1; load() }
const reset = () => { q.keyword = ''; q.status = ''; q.payType = ''; search() }

const pay = async (row) => {
  await ElMessageBox.confirm(`确认为订单 ${row.orderNo} 登记支付成功（¥${row.payAmount}，${row.payType}）？`, '登记支付', { type: 'info' })
  await orderPay(row.id)
  ElMessage.success('支付已登记')
  load()
}
const ship = async (row) => {
  await ElMessageBox.confirm(`确认订单 ${row.orderNo} 已出库并发货？`, '发货', { type: 'info' })
  await orderShip(row.id)
  ElMessage.success('已发货')
  load()
}
const cancel = async (row) => {
  await ElMessageBox.confirm(`取消订单 ${row.orderNo} 并回补库存？`, '取消订单', { type: 'warning' })
  await orderCancel(row.id)
  ElMessage.success('订单已取消')
  load()
}
const refund = async (row) => {
  const { value } = await ElMessageBox.prompt(`登记订单 ${row.orderNo} 退款，退款后自动冲减对应试用转化归因`, '退款登记', {
    inputPlaceholder: '退款原因（不少于 5 字）', inputPattern: /^.{5,}$/, inputErrorMessage: '原因不少于 5 字'
  })
  await orderRefund(row.id, { reason: value })
  ElMessage.success('退款已登记，库存已回补')
  load()
}
const fmt = (t) => (t ? String(t).replace('T', ' ').slice(0, 16) : '-')

onMounted(load)
</script>
