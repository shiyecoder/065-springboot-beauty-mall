<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">出入库登记</h3>
        <div class="page-sub">入库、派发、退回、报损、过期核销均写库存流水；变动后数量必须与剩余数量一致</div>
      </div>
      <el-button :icon="Refresh" @click="loadLog">刷新流水</el-button>
    </div>

    <div class="g21">
      <div>
        <div class="card">
          <div class="card-hd">登记库存变动<span class="hint">保存后自动回写试用装剩余数量</span></div>
          <el-form :model="form" label-width="96px">
            <el-form-item label="试用装">
              <el-select v-model="form.sampleId" filterable style="width: 360px" placeholder="按编号或商品搜索" @change="pick">
                <el-option v-for="s in samples" :key="s.id" :label="`${s.sampleNo}｜${s.goodsName}｜剩 ${s.remainQty}`" :value="s.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="变动类型">
              <el-radio-group v-model="form.changeType">
                <el-radio-button v-for="t in TYPES" :key="t" :label="t">{{ t }}</el-radio-button>
              </el-radio-group>
            </el-form-item>
            <el-form-item :label="form.changeType === '入库' ? '入库数量' : '变动数量'">
              <el-input-number v-model="form.qty" :min="1" style="width: 200px" />
              <span class="muted" style="margin-left: 10px">报损与过期核销按减少处理</span>
            </el-form-item>
            <el-form-item label="关联单号">
              <el-input v-model="form.bizNo" placeholder="申领单号 / 采购单号，可留空" style="width: 360px" />
            </el-form-item>
            <el-form-item label="备注">
              <el-input v-model="form.remark" type="textarea" :rows="2" style="width: 460px" placeholder="核销、报损必须说明原因" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="saving" @click="submit">提交登记</el-button>
              <el-button @click="reset">清空</el-button>
            </el-form-item>
          </el-form>
        </div>

        <div class="card">
          <div class="card-hd">库存流水<span class="hint">共 {{ total }} 条</span></div>
          <el-table :data="rows" v-loading="loading" stripe size="small">
            <el-table-column prop="logNo" label="流水号" width="140" />
            <el-table-column prop="sampleNo" label="试用装" width="130" />
            <el-table-column prop="goodsName" label="商品" min-width="160" show-overflow-tooltip />
            <el-table-column label="类型" width="90">
              <template #default="{ row }"><span class="tag" :class="T_CLS[row.changeType] || 'info'">{{ row.changeType }}</span></template>
            </el-table-column>
            <el-table-column label="变动" width="80">
              <template #default="{ row }">
                <b :style="{ color: row.changeQty > 0 ? 'var(--bt-ok)' : 'var(--bt-bad)' }">{{ row.changeQty > 0 ? '+' : '' }}{{ row.changeQty }}</b>
              </template>
            </el-table-column>
            <el-table-column label="变动前 → 后" width="120">
              <template #default="{ row }" class="mono">{{ row.beforeQty }} → {{ row.afterQty }}</template>
            </el-table-column>
            <el-table-column prop="bizNo" label="关联单号" width="140" />
            <el-table-column label="时间" width="150">
              <template #default="{ row }">{{ fmt(row.createTime) }}</template>
            </el-table-column>
          </el-table>
          <div class="pager">
            <el-pagination background layout="total, prev, pager, next" :total="total"
                           v-model:current-page="lq.page" :page-size="lq.size" @current-change="loadLog" />
          </div>
        </div>
      </div>

      <div>
        <div class="card">
          <div class="card-hd">当前试用装<span class="hint">按剩余升序</span></div>
          <div v-for="s in samples.slice(0, 9)" :key="s.id" class="sm-row" @click="form.sampleId = s.id; pick(s.id)">
            <img v-if="s.goodsCover" class="thumb" :src="s.goodsCover" alt="" />
            <div class="sm-txt">
              <div class="sm-n">{{ s.goodsName }}</div>
              <div class="muted" style="font-size: 11px">{{ s.sampleNo }} · {{ s.expireDate }}</div>
            </div>
            <div class="sm-q" :class="{ low: s.remainQty <= 20 }">{{ s.remainQty }}</div>
          </div>
        </div>
        <div class="card">
          <div class="card-hd">登记规则</div>
          <div class="note-box">派发与扣减必须在同一事务；剩余数量与流水变动后数量不一致时禁止派发，需先做库存校准并记录原因。</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { Refresh } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { useRoute } from 'vue-router'
import { samplePage, stockChange, stockLogPage } from '../../api'

const route = useRoute()
const TYPES = ['入库', '派发', '退回', '报损', '过期核销']
const T_CLS = { 入库: 'ok', 派发: 'info', 退回: 'warn', 报损: 'bad', 过期核销: 'bad' }

const samples = ref([])
const rows = ref([])
const total = ref(0)
const loading = ref(false)
const saving = ref(false)
const lq = reactive({ page: 1, size: 10 })
const form = reactive({ sampleId: null, changeType: '入库', qty: 10, bizNo: '', remark: '' })

const pick = (id) => {
  const s = samples.value.find((x) => x.id === id)
  if (s) form.qty = form.changeType === '入库' ? 50 : 1
}

const loadSamples = async () => {
  const r = await samplePage({ page: 1, size: 100 })
  samples.value = (r.data.records || []).sort((a, b) => a.remainQty - b.remainQty)
  if (route.query.sampleNo) {
    const hit = samples.value.find((s) => s.sampleNo === route.query.sampleNo)
    if (hit) form.sampleId = hit.id
  } else if (!form.sampleId && samples.value.length) {
    form.sampleId = samples.value[0].id
  }
}

const loadLog = async () => {
  loading.value = true
  try {
    const r = await stockLogPage(lq)
    rows.value = r.data.records || []
    total.value = r.data.total || 0
  } finally {
    loading.value = false
  }
}

const submit = async () => {
  if (!form.sampleId) return ElMessage.warning('请选择试用装')
  if (!form.qty || form.qty <= 0) return ElMessage.warning('变动数量必须大于 0')
  if ((form.changeType === '报损' || form.changeType === '过期核销') && !form.remark) {
    return ElMessage.warning('报损与过期核销必须填写原因')
  }
  const sign = form.changeType === '入库' ? 1 : form.changeType === '退回' ? 1 : -1
  saving.value = true
  try {
    await stockChange({
      sampleId: form.sampleId, changeType: form.changeType,
      changeQty: sign * form.qty, bizNo: form.bizNo, remark: form.remark
    })
    ElMessage.success('登记成功，已写入库存流水')
    reset()
    await Promise.all([loadSamples(), loadLog()])
  } finally {
    saving.value = false
  }
}

const reset = () => {
  Object.assign(form, { sampleId: samples.value[0]?.id || null, changeType: '入库', qty: 10, bizNo: '', remark: '' })
}

const fmt = (t) => (t ? String(t).replace('T', ' ').slice(0, 16) : '-')

onMounted(async () => {
  await loadSamples()
  await loadLog()
})
</script>

<style scoped>
.sm-row { display: flex; align-items: center; gap: 9px; padding: 7px 0; border-bottom: 1px dashed var(--bt-line); cursor: pointer; }
.sm-row:last-child { border-bottom: 0; }
.sm-txt { flex: 1; min-width: 0; }
.sm-n { font-size: 12px; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.sm-q { font-size: 15px; font-weight: 700; color: var(--bt-ok); }
.sm-q.low { color: var(--bt-bad); }
</style>
