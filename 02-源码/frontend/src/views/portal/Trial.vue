<template>
  <div class="wrap">
    <div class="hd">
      <div>
        <h2>试用活动</h2>
        <p>每个账号同一批次限领 1 份，需先完善肤质档案；审核通过后 48 小时内寄出</p>
      </div>
      <div class="fl">
        <el-input v-model="q.keyword" placeholder="搜索小样编号 / 批次" clearable style="width: 200px" @keyup.enter="search" />
        <el-button type="primary" @click="search">查询</el-button>
      </div>
    </div>

    <div class="note-box" v-if="!profile">
      尚未建立肤质档案，申领会被驳回。请先前往
      <router-link to="/portal/skin-test" style="color: var(--bt-primary)">肤质测评</router-link>
      完成建档。
    </div>

    <div class="grid4" v-loading="loading">
      <div v-for="s in rows" :key="s.id" class="card-s">
        <div class="cov">
          <img :src="s.goodsCover" alt="" />
          <span class="ml">{{ s.specMl }}ml 小样</span>
        </div>
        <div class="bd">
          <div class="nm">{{ s.goodsName }}</div>
          <div class="sub">批次 {{ s.batchNo }}</div>
          <div class="meter">
            <div class="bar"><i :style="{ width: pct(s) + '%' }"></i></div>
            <span class="muted">余 {{ s.remainQty }} / {{ s.totalQty }}</span>
          </div>
          <div class="row">
            <span class="dt" :class="{ warn: s.expiring }">效期 {{ fmtDate(s.expireDate) }}</span>
            <el-button size="small" type="primary" :disabled="s.remainQty <= 0" @click="open(s)">
              {{ s.remainQty > 0 ? '立即申领' : '已派完' }}
            </el-button>
          </div>
        </div>
      </div>
      <el-empty v-if="!rows.length && !loading" description="暂无可申领的试用装" />
    </div>

    <div class="pager" style="padding-bottom: 40px">
      <el-pagination background layout="total, prev, pager, next" :total="total"
                     v-model:current-page="q.page" :page-size="q.size" @current-change="load" />
    </div>

    <el-dialog v-model="dlg" title="申领试用装" width="520px">
      <div class="pick" v-if="cur">
        <img :src="cur.goodsCover" alt="" />
        <div>
          <div class="pn">{{ cur.goodsName }}</div>
          <div class="muted" style="font-size: 12px">{{ cur.specMl }}ml · 批次 {{ cur.batchNo }}</div>
        </div>
      </div>
      <el-form :model="form" label-width="86px">
        <el-form-item label="申领理由">
          <el-input v-model="form.applyReason" type="textarea" :rows="2" maxlength="120" show-word-limit
                    placeholder="例如：干性敏感肌，想先试用再决定是否入正装" />
        </el-form-item>
        <el-form-item label="收件人"><el-input v-model="form.receiverName" /></el-form-item>
        <el-form-item label="手机号"><el-input v-model="form.receiverPhone" maxlength="11" /></el-form-item>
        <el-form-item label="收件地址"><el-input v-model="form.addressDesc" placeholder="省 / 市 / 区 详细地址" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dlg = false">取消</el-button>
        <el-button type="primary" :loading="saving" :disabled="!profile" @click="submit">提交申领</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { samplePage, applyCreate, myProfile } from '../../api'
import { store } from '../../store/user'
import { fmtDate } from '../../utils/format'

const router = useRouter()
const q = reactive({ page: 1, size: 12, keyword: '', status: '可派发' })
const rows = ref([])
const total = ref(0)
const loading = ref(false)
const dlg = ref(false)
const saving = ref(false)
const cur = ref(null)
const profile = ref(null)
const form = reactive({ applyReason: '', receiverName: '', receiverPhone: '', addressDesc: '' })

const pct = (s) => Math.min(100, Math.round(((s.remainQty || 0) / (s.totalQty || 1)) * 100))

const load = async () => {
  loading.value = true
  try {
    const r = await samplePage(q)
    rows.value = r.data.records || []
    total.value = r.data.total || 0
  } finally {
    loading.value = false
  }
}
const search = () => {
  q.page = 1
  load()
}

const open = (s) => {
  cur.value = s
  Object.assign(form, {
    applyReason: profile.value ? `我的肤质为${profile.value.skinType}，想先试用再决定是否购买正装` : '',
    receiverName: store.user?.realName || '',
    receiverPhone: store.user?.phone || '',
    addressDesc: ''
  })
  dlg.value = true
}

const submit = async () => {
  if (!form.applyReason || !form.receiverName || !form.receiverPhone || !form.addressDesc) {
    return ElMessage.warning('请完整填写申领理由与收件信息')
  }
  saving.value = true
  try {
    const r = await applyCreate({ ...form, sampleId: cur.value.id })
    ElMessage.success('申领已提交，等待审核')
    dlg.value = false
    router.push(`/portal/apply/${r.data.id ?? r.data}`)
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  load()
  try {
    const p = await myProfile()
    profile.value = p.data || null
  } catch (e) {
    profile.value = null
  }
})
</script>

<style scoped>
.wrap { width: 1200px; margin: 0 auto; padding-top: 30px; }
.hd { display: flex; align-items: flex-end; justify-content: space-between; margin-bottom: 18px; }
.hd h2 { font-size: 22px; margin: 0 0 6px; }
.hd p { font-size: 12px; color: var(--bt-text-3); margin: 0; }
.fl { display: flex; gap: 10px; }
.grid4 { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; }
.card-s { background: #fff; border: 1px solid var(--bt-line); border-radius: 14px; overflow: hidden; }
.cov { position: relative; height: 170px; background: #f7f3fb; }
.cov img { width: 100%; height: 100%; object-fit: cover; }
.ml { position: absolute; left: 10px; top: 10px; background: rgba(122, 90, 166, .92); color: #fff; font-size: 11px; padding: 3px 8px; border-radius: 6px; }
.bd { padding: 12px 13px 14px; }
.nm { font-size: 14px; font-weight: 600; }
.sub { font-size: 11px; color: var(--bt-text-3); margin: 5px 0 10px; }
.meter { display: flex; align-items: center; gap: 8px; margin-bottom: 12px; font-size: 11px; }
.bar { flex: 1; height: 5px; background: #efe9f7; border-radius: 3px; overflow: hidden; }
.bar i { display: block; height: 100%; background: linear-gradient(90deg, #7a5aa6, #c9a6e0); }
.row { display: flex; align-items: center; justify-content: space-between; }
.dt { font-size: 11px; color: var(--bt-text-3); }
.dt.warn { color: #c9741f; }
.pick { display: flex; gap: 12px; align-items: center; padding: 10px; background: #faf8fd; border-radius: 10px; margin-bottom: 14px; }
.pick img { width: 56px; height: 56px; border-radius: 8px; object-fit: cover; }
.pn { font-size: 14px; font-weight: 600; }
</style>
