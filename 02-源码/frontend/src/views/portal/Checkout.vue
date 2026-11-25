<template>
  <div class="wrap" v-loading="loading">
    <div class="crumb"><router-link to="/portal/home">首页</router-link> / 确认下单</div>
    <h2 class="tt">确认订单</h2>

    <div class="g21" v-if="g">
      <div>
        <div class="card">
          <div class="card-hd"><span>商品清单</span></div>
          <div class="line">
            <img :src="g.coverImage" alt="" />
            <div class="bd">
              <div class="nm">{{ g.goodsName }}</div>
              <div class="meta">{{ g.brand }} · {{ g.goodsType }} · {{ g.specMl }}ml</div>
              <div class="meta" v-if="applyNo">关联试用单 {{ applyNo }}，报告归属期内享 9 折</div>
            </div>
            <el-input-number v-model="qty" :min="1" :max="Math.max(1, g.stockQty)" @change="calc" />
            <div class="price" style="width: 90px; text-align: right">¥{{ money(g.salePrice * qty) }}</div>
          </div>
        </div>

        <div class="card" style="margin-top: 12px">
          <div class="card-hd"><span>收件信息</span></div>
          <el-form :model="f" label-width="86px">
            <el-form-item label="收件人"><el-input v-model="f.receiverName" /></el-form-item>
            <el-form-item label="手机号"><el-input v-model="f.receiverPhone" maxlength="11" /></el-form-item>
            <el-form-item label="地址"><el-input v-model="f.addressDesc" placeholder="省 / 市 / 区 详细地址" /></el-form-item>
          </el-form>
        </div>

        <div class="card" style="margin-top: 12px">
          <div class="card-hd"><span>支付方式</span></div>
          <div class="pays">
            <div v-for="p in PAYS" :key="p" class="pay" :class="{ on: f.payType === p }" @click="f.payType = p">
              <b>{{ p }}</b><span class="muted">演示环境仅登记支付结果</span>
            </div>
          </div>
        </div>
      </div>

      <div class="card sum">
        <div class="card-hd"><span>金额明细</span></div>
        <div class="row"><span>商品金额</span><b>¥{{ money(g.salePrice * qty) }}</b></div>
        <div class="row"><span>试用报告折扣</span><b class="cut">-¥{{ money(discount) }}</b></div>
        <div class="row"><span>运费</span><b>包邮</b></div>
        <div class="total"><span>应付</span><b class="price">¥{{ money(payable) }}</b></div>
        <el-button type="primary" size="large" style="width: 100%" :loading="saving" @click="submit">提交订单并支付</el-button>
        <div class="muted" style="font-size: 11px; margin-top: 10px; line-height: 1.7">
          提交即视为同意《正装购买须知》。演示系统不接真实支付，订单状态由后端状态机推进。
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { goodsDetail, orderCreate, orderPay } from '../../api'
import { store } from '../../store/user'
import { money } from '../../utils/format'

const route = useRoute()
const router = useRouter()
const g = ref(null)
const qty = ref(Number(route.query.qty || 1))
const saving = ref(false)
const loading = ref(false)
const applyNo = ref('')
const f = reactive({ receiverName: '', receiverPhone: '', addressDesc: '', payType: '微信支付' })
const PAYS = ['微信支付', '支付宝', '银联']

// 9 折：仅当从「已完成试用」带 apply 参数进入时生效，与后端同口径（报告归属期 30 天）
const discount = computed(() => (route.query.apply && g.value ? Number(g.value.salePrice) * qty.value * 0.1 : 0))
const payable = computed(() => (g.value ? Number(g.value.salePrice) * qty.value - discount.value : 0))

const calc = () => {}

const submit = async () => {
  if (!f.receiverName || !f.receiverPhone || !f.addressDesc) return ElMessage.warning('请完整填写收件信息')
  saving.value = true
  try {
    const r = await orderCreate({
      goodsId: g.value.id,
      buyQty: qty.value,
      payType: f.payType,
      receiverName: f.receiverName,
      receiverPhone: f.receiverPhone,
      addressDesc: f.addressDesc,
      sourceApplyNo: applyNo.value || null
    })
    const id = r.data?.id ?? r.data
    await orderPay(id, { payType: f.payType })
    ElMessage.success('下单成功，已登记支付')
    router.push('/portal/orders')
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  loading.value = true
  try {
    const r = await goodsDetail(route.params.id)
    g.value = r.data
    Object.assign(f, {
      receiverName: store.user?.realName || '',
      receiverPhone: store.user?.phone || ''
    })
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.wrap { width: 1060px; margin: 0 auto; padding: 22px 0 46px; }
.crumb { font-size: 12px; color: var(--bt-text-3); }
.tt { font-size: 22px; margin: 8px 0 16px; }
.line { display: flex; gap: 14px; align-items: center; padding: 6px 0; }
.line img { width: 72px; height: 72px; border-radius: 8px; object-fit: cover; }
.bd { flex: 1; }
.nm { font-size: 14px; font-weight: 600; }
.meta { font-size: 12px; color: var(--bt-text-3); margin-top: 4px; }
.pays { display: flex; gap: 10px; }
.pay { flex: 1; border: 1px solid var(--bt-line); border-radius: 10px; padding: 12px; cursor: pointer; }
.pay.on { border-color: var(--bt-primary); background: #faf8fd; }
.pay b { display: block; font-size: 13px; margin-bottom: 4px; }
.pay span { font-size: 11px; }
.sum { align-self: flex-start; position: sticky; top: 88px; }
.row { display: flex; justify-content: space-between; font-size: 13px; padding: 8px 0; border-bottom: 1px dashed var(--bt-line); }
.cut { color: #b6652f; }
.total { display: flex; justify-content: space-between; align-items: baseline; padding: 14px 0; }
.total b { font-size: 22px; }
</style>
