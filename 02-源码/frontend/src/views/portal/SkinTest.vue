<template>
  <div class="page">
    <div class="wrap">
      <div class="hero">
        <div>
          <div class="eyebrow">SKIN PROFILE · 3 分钟</div>
          <h1>肤质测评</h1>
          <p>测评结果是试用装匹配与转化评分的依据，一人一档；重新测评会覆盖旧档案（历史报告不重算）。</p>
        </div>
        <div class="now" v-if="profile">
          <div class="lb">当前档案</div>
          <div class="row"><span>肤质</span><b>{{ profile.skinType }}</b></div>
          <div class="row"><span>敏感度</span><b>{{ profile.sensitiveLevel }}</b></div>
          <div class="row"><span>诉求</span><b>{{ profile.demandTags }}</b></div>
          <div class="row"><span>自测分</span><b class="price">{{ profile.selfTestScore }}</b></div>
          <div class="row"><span>版本</span><b>{{ profile.paperVersion }} · {{ fmtDate(profile.updateDate) }}</b></div>
        </div>
        <div class="now empty" v-else>
          <div class="lb">尚未建档</div>
          <p class="muted" style="font-size: 12px; line-height: 1.8">完成右侧问卷即可生成档案，之后才能申领试用装。</p>
        </div>
      </div>

      <div class="card quiz">
        <div class="q" v-for="(q, qi) in QS" :key="qi">
          <div class="qh"><span class="idx">{{ qi + 1 }}</span>{{ q.q }}</div>
          <div class="opts">
            <div v-for="(o, oi) in q.opts" :key="oi" class="opt" :class="{ on: ans[qi] === oi }" @click="ans[qi] = oi">
              {{ o.t }}
            </div>
          </div>
        </div>

        <div class="q">
          <div class="qh"><span class="idx">6</span>你的主要护肤诉求（可多选）</div>
          <div class="opts">
            <div v-for="d in DEMANDS" :key="d" class="opt" :class="{ on: demand.includes(d) }" @click="toggle(d)">{{ d }}</div>
          </div>
        </div>

        <div class="q">
          <div class="qh"><span class="idx">7</span>已知过敏成分（没有可留空）</div>
          <el-input v-model="allergy" placeholder="如：酒精、香精、某些防腐剂" />
        </div>

        <div class="result">
          <div class="sc">
            <div class="lb">预计自测得分</div>
            <div class="num">{{ score }}</div>
            <div class="muted" style="font-size: 11px">得分越高代表肤况越稳定</div>
          </div>
          <div class="rs">
            <div><span>判定肤质</span><b>{{ skinType }}</b></div>
            <div><span>敏感等级</span><b>{{ sensitive }}</b></div>
            <div><span>匹配诉求</span><b>{{ demand.join('、') || '—' }}</b></div>
          </div>
          <el-button type="primary" size="large" :loading="saving" @click="submit">生成我的肤质档案</el-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { skinSubmit, myProfile } from '../../api'
import { fmtDate } from '../../utils/format'

const DEMANDS = ['保湿', '舒缓修护', '控油', '提亮', '抗初老', '防晒']
const QS = [
  { q: '洁面后 30 分钟，面部感受是？', opts: [{ t: '全脸紧绷、起皮', v: 1 }, { t: '两颊干、T 区正常', v: 2 }, { t: '整体舒适不油不干', v: 4 }, { t: 'T 区泛油、两颊正常', v: 3 }, { t: '全脸油光明显', v: 2 }] },
  { q: '毛孔与出油情况？', opts: [{ t: '几乎看不到毛孔', v: 3 }, { t: '鼻翼少量出油', v: 4 }, { t: 'T 区毛孔明显、午后泛油', v: 3 }, { t: '全脸毛孔粗大', v: 2 }] },
  { q: '换季或换新产品时？', opts: [{ t: '从不过敏', v: 5 }, { t: '偶尔轻微泛红', v: 4 }, { t: '经常泛红刺痛', v: 2 }, { t: '一定出现脱皮或红疹', v: 1 }] },
  { q: '面部泛红/红血丝？', opts: [{ t: '没有', v: 5 }, { t: '遇热偶发', v: 4 }, { t: '两颊长期泛红', v: 2 }] },
  { q: '日常作息与饮水？', opts: [{ t: '规律作息、饮水充足', v: 5 }, { t: '偶尔熬夜', v: 4 }, { t: '长期熬夜、饮水少', v: 2 }] }
]

const ans = reactive({ 0: 2, 1: 1, 2: 1, 3: 1, 4: 1 })
const demand = ref(['保湿'])
const allergy = ref('')
const profile = ref(null)
const saving = ref(false)

const total = computed(() => QS.reduce((s, q, i) => s + (q.opts[ans[i]]?.v || 0), 0))
const score = computed(() => Math.min(100, Math.round((total.value / 22) * 100)))
const skinType = computed(() => {
  const a = ans[0]
  if (a === 0) return '干性'
  if (a === 1) return '混合偏干'
  if (a === 3) return '混合偏油'
  if (a === 4) return '油性'
  return '中性'
})
const sensitive = computed(() => {
  const s = (QS[2].opts[ans[2]]?.v || 0) + (QS[3].opts[ans[3]]?.v || 0)
  if (s >= 9) return '不敏感'
  if (s >= 6) return '轻度敏感'
  return '高度敏感'
})

const toggle = (d) => {
  const i = demand.value.indexOf(d)
  if (i >= 0) demand.value.splice(i, 1)
  else demand.value.push(d)
}

const submit = async () => {
  if (!demand.value.length) return ElMessage.warning('请至少选择一个护肤诉求')
  saving.value = true
  try {
    await skinSubmit({
      skinType: skinType.value,
      sensitiveLevel: sensitive.value,
      demandTags: demand.value.join(','),
      allergyIngredients: allergy.value || null,
      selfTestScore: score.value,
      paperVersion: 'V2',
      answers: Object.fromEntries(QS.map((q, i) => [`q${i + 1}`, q.opts[ans[i]]?.t || '']))
    })
    ElMessage.success('肤质档案已生成')
    const r = await myProfile()
    profile.value = r.data || null
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  try {
    const r = await myProfile()
    profile.value = r.data || null
  } catch (e) {
    profile.value = null
  }
})
</script>

<style scoped>
.page { background: linear-gradient(180deg, #f8f4fc 0%, #fff 340px); padding: 30px 0 50px; }
.wrap { width: 1060px; margin: 0 auto; }
.hero { display: flex; gap: 40px; align-items: center; margin-bottom: 20px; }
.hero > div:first-child { flex: 1; }
.eyebrow { font-size: 11px; letter-spacing: 2.2px; color: var(--bt-primary); font-weight: 600; }
.hero h1 { font-size: 32px; margin: 10px 0 10px; }
.hero p { font-size: 13px; color: var(--bt-text-2); line-height: 1.9; max-width: 520px; }
.now { width: 300px; background: #fff; border: 1px solid var(--bt-line); border-radius: 14px; padding: 16px; box-shadow: 0 10px 26px rgba(90, 60, 130, .07); }
.now .lb { font-size: 12px; color: var(--bt-text-3); margin-bottom: 10px; }
.now .row { display: flex; justify-content: space-between; font-size: 12px; padding: 5px 0; border-bottom: 1px dashed var(--bt-line); }
.quiz { padding: 22px 26px; }
.q { margin-bottom: 22px; }
.qh { font-size: 14px; font-weight: 600; display: flex; align-items: center; gap: 8px; margin-bottom: 10px; }
.idx { width: 20px; height: 20px; border-radius: 6px; background: #f0e9f9; color: var(--bt-primary); font-size: 11px; display: grid; place-items: center; }
.opts { display: flex; flex-wrap: wrap; gap: 10px; }
.opt { border: 1px solid var(--bt-line); border-radius: 999px; padding: 8px 16px; font-size: 13px; cursor: pointer; color: var(--bt-text-2); transition: .15s; }
.opt:hover { border-color: #d9c9ee; }
.opt.on { border-color: var(--bt-primary); background: #f6f1fb; color: var(--bt-primary); font-weight: 600; }
.result { display: flex; align-items: center; gap: 28px; background: #faf8fd; border-radius: 14px; padding: 18px 22px; }
.sc { text-align: center; }
.sc .lb { font-size: 11px; color: var(--bt-text-3); }
.sc .num { font-size: 34px; font-weight: 700; color: var(--bt-primary); line-height: 1.2; }
.rs { flex: 1; font-size: 13px; }
.rs > div { display: flex; gap: 10px; padding: 4px 0; }
.rs span { color: var(--bt-text-3); width: 74px; }
</style>
