<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">转化规则配置</h3>
        <div class="page-sub">权重合计必须等于 100%，保存后生成新版本号与生效时间；历史计算不受影响</div>
      </div>
      <el-button :icon="Refresh" @click="load">刷新</el-button>
    </div>

    <div class="g21">
      <div class="card">
        <div class="card-hd">
          五因子权重
          <span class="hint">
            合计
            <b :style="{ color: sumWeight === 100 ? 'var(--bt-ok)' : 'var(--bt-bad)' }">{{ sumWeight }}%</b>
            <span v-if="sumWeight !== 100"> · 必须为 100% 才能保存</span>
          </span>
        </div>

        <div v-for="w in WEIGHTS" :key="w.key" class="wr">
          <div class="wr-h">
            <span>{{ w.label }}</span>
            <span class="muted" style="font-size: 12px">{{ w.desc }}</span>
          </div>
          <div class="wr-b">
            <el-slider v-model="form[w.key]" :min="0" :max="100" :step="5" style="flex: 1" />
            <el-input-number v-model="form[w.key]" :min="0" :max="100" size="small" style="width: 96px" />
          </div>
        </div>

        <el-divider style="margin: 12px 0" />

        <el-form :model="form" label-width="112px">
          <el-row :gutter="12">
            <el-col :span="12">
              <el-form-item label="高意向阈值">
                <el-input-number v-model="form.highThreshold" :min="0" :max="100" style="width: 100%" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="中意向阈值">
                <el-input-number v-model="form.midThreshold" :min="0" :max="100" style="width: 100%" />
              </el-form-item>
            </el-col>
            <el-col :span="24">
              <el-form-item label="版本名称">
                <el-input v-model="form.ruleName" placeholder="例如：报告完整度上调" />
              </el-form-item>
            </el-col>
          </el-row>
          <div class="note-box">
            概率分 = Σ(单项归一化得分 × 权重)/100。适配度：肤质在商品适用列表内计 100 分，部分匹配 60 分，不匹配 0 分；
            无肤质档案该项记 0 分并提示先完成自测，不做默认通过。
          </div>
          <div style="margin-top: 14px">
            <el-button type="primary" :disabled="sumWeight !== 100" :loading="saving" @click="save">保存为新版本</el-button>
            <el-button @click="reset">还原当前生效值</el-button>
          </div>
        </el-form>
      </div>

      <div>
        <div class="card">
          <div class="card-hd">当前生效版本</div>
          <div v-if="curV" class="kv">
            <span class="k">版本号</span><span><b>{{ curV.ruleVersion }}</b></span>
            <span class="k">规则编号</span><span class="mono">{{ curV.ruleNo }}</span>
            <span class="k">生效时间</span><span>{{ fmt(curV.effectTime) }}</span>
            <span class="k">判定阈值</span><span>高 {{ curV.highThreshold }} / 中 {{ curV.midThreshold }}</span>
            <span class="k">备注</span><span>{{ curV.remark || '-' }}</span>
          </div>
        </div>
        <div class="card">
          <div class="card-hd">版本历史<span class="hint">共 {{ list.length }} 版</span></div>
          <div v-for="r in list" :key="r.id" class="vr">
            <div class="vr-h">
              <b>{{ r.ruleVersion }}</b>
              <span class="tag" :class="r.status === '生效' ? 'ok' : 'info'">{{ r.status }}</span>
            </div>
            <div class="muted" style="font-size: 11px">{{ r.ruleName }} · {{ fmt(r.effectTime) }}</div>
            <div class="vr-w">肤质{{ r.wskin }} / 历史{{ r.whistory }} / 报告{{ r.wreport }} / 浏览{{ r.wbrowse }} / 客单{{ r.worder }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { Refresh } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { ruleCurrent, ruleList, ruleSave } from '../../api'

const WEIGHTS = [
  { key: 'wSkin', label: '肤质与商品适配度', desc: '肤质类型与商品适用肤质交集' },
  { key: 'wHistory', label: '历史领取与报告率', desc: '近 180 天报告提交率' },
  { key: 'wReport', label: '试用报告完整度', desc: '天数 / 评分 / 字数 / 图片' },
  { key: 'wBrowse', label: '正装详情浏览时长', desc: '浏览分钟与加购次数' },
  { key: 'wOrder', label: '正装价格与客单匹配度', desc: '售价与历史客单价对比' }
]

const form = reactive({ ruleName: '当前生效版本', wSkin: 30, wHistory: 25, wReport: 20, wBrowse: 15, wOrder: 10, highThreshold: 75, midThreshold: 50 })
const curV = ref(null)
const list = ref([])
const saving = ref(false)

const sumWeight = computed(() => WEIGHTS.reduce((s, w) => s + Number(form[w.key] || 0), 0))

const load = async () => {
  const [a, b] = await Promise.all([ruleCurrent(), ruleList()])
  curV.value = a.data
  list.value = b.data || []
  if (a.data) {
    Object.assign(form, {
      ruleName: '当前生效版本',
      wSkin: Number(a.data.wskin), wHistory: Number(a.data.whistory), wReport: Number(a.data.wreport),
      wBrowse: Number(a.data.wbrowse), wOrder: Number(a.data.worder),
      highThreshold: Number(a.data.highThreshold), midThreshold: Number(a.data.midThreshold)
    })
  }
}
const reset = load

const save = async () => {
  if (sumWeight.value !== 100) return ElMessage.warning('权重合计必须等于 100%')
  if (form.midThreshold >= form.highThreshold) return ElMessage.warning('中意向阈值必须小于高意向阈值')
  if (!form.ruleName) return ElMessage.warning('请填写版本名称')
  saving.value = true
  try {
    await ruleSave({ ...form })
    ElMessage.success('已保存为新版本，仅影响后续计算')
    load()
  } finally {
    saving.value = false
  }
}
const fmt = (t) => (t ? String(t).replace('T', ' ').slice(0, 10) : '-')

onMounted(load)
</script>

<style scoped>
.wr { margin-bottom: 14px; }
.wr-h { display: flex; justify-content: space-between; font-size: 13px; margin-bottom: 4px; }
.wr-b { display: flex; align-items: center; gap: 14px; padding-right: 6px; }
.vr { padding: 9px 0; border-bottom: 1px dashed var(--bt-line); }
.vr:last-child { border-bottom: 0; }
.vr-h { display: flex; align-items: center; gap: 8px; }
.vr-w { font-size: 11px; color: var(--bt-text-2); margin-top: 3px; }
</style>
