<template>
  <div class="wrap" v-loading="loading">
    <div class="crumb"><router-link to="/portal/my">我的试用</router-link> / 提交试用报告</div>

    <div class="card" v-if="a">
      <div class="hd">
        <div class="g">
          <img :src="a.goodsCover" alt="" />
          <div>
            <h2>{{ a.goodsName }}</h2>
            <div class="muted" style="font-size: 12px">申领单 {{ a.applyNo }} · 小样 {{ a.sampleSpec }}ml · 寄出 {{ fmt(a.sendTime) }}</div>
          </div>
        </div>
        <span class="tag ok">报告可提升信用分</span>
      </div>

      <div v-if="a.report" class="note-box" style="margin-bottom: 16px">
        本单已于 {{ fmt(a.report.createTime) }} 提交报告（{{ a.report.reportNo }}），当前状态「{{ a.report.status }}」，如需修改请联系客服。
      </div>

      <el-form :model="f" label-width="104px" :disabled="!!a.report">
        <el-form-item label="连续使用天数">
          <el-input-number v-model="f.useDays" :min="1" :max="60" />
          <span class="muted" style="margin-left: 10px; font-size: 12px">建议 7 天以上，天数越长权重越高</span>
        </el-form-item>

        <el-form-item label="吸收度评分">
          <el-rate v-model="f.absorbScore" :max="5" show-score score-template="{value} 分" />
        </el-form-item>

        <el-form-item label="温和度评分">
          <el-rate v-model="f.mildScore" :max="5" show-score score-template="{value} 分" />
        </el-form-item>

        <el-form-item label="是否过敏">
          <el-switch v-model="f.allergic" active-text="出现泛红/刺痛" inactive-text="无不适" />
        </el-form-item>
        <el-form-item label="过敏症状" v-if="f.allergic">
          <el-input v-model="f.symptom" placeholder="如：两颊轻微泛红，30 分钟后消退" />
        </el-form-item>

        <el-form-item label="回购意愿">
          <el-radio-group v-model="f.repurchaseWill">
            <el-radio-button v-for="w in WILLS" :key="w" :label="w" :value="w" />
          </el-radio-group>
        </el-form-item>

        <el-form-item label="使用感受">
          <el-input v-model="f.content" type="textarea" :rows="5" maxlength="500" show-word-limit
                    placeholder="质地、上脸感受、肤况变化、与在用的产品是否冲突……（不少于 20 字）" />
        </el-form-item>

        <el-form-item label="实拍图">
          <div class="ups">
            <div v-for="(u, i) in f.imageUrls" :key="i" class="up">
              <img :src="u" alt="" />
              <span class="del" @click="f.imageUrls.splice(i, 1)">×</span>
            </div>
            <el-upload :show-file-list="false" :http-request="doUpload" accept="image/*" v-if="f.imageUrls.length < 4">
              <div class="add">＋<br /><span>上传实拍</span></div>
            </el-upload>
          </div>
          <div class="muted" style="font-size: 11px">最多 4 张，jpg/png ≤5MB；无图也可提交，但有图审核通过率更高</div>
        </el-form-item>

        <el-form-item>
          <el-button type="primary" size="large" :loading="saving" :disabled="!!a.report" @click="submit">提交报告</el-button>
          <el-button size="large" @click="$router.push('/portal/my')">稍后再说</el-button>
        </el-form-item>
      </el-form>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { applyDetail, reportCreate, upload } from '../../api'
import { fmt } from '../../utils/format'

const WILLS = ['一定会回购', '可能会回购', '暂不考虑']
const route = useRoute()
const router = useRouter()
const a = ref(null)
const loading = ref(false)
const saving = ref(false)
const f = reactive({ useDays: 7, absorbScore: 4, mildScore: 4, allergic: false, symptom: '', repurchaseWill: '可能会回购', content: '', imageUrls: [] })

const doUpload = async ({ file }) => {
  const r = await upload(file, 'report')
  f.imageUrls.push(r.data.filePath)
}

const submit = async () => {
  if (!f.content || f.content.trim().length < 20) return ElMessage.warning('使用感受至少 20 字')
  if (f.allergic && !f.symptom) return ElMessage.warning('出现过敏时请填写症状描述')
  saving.value = true
  try {
    await reportCreate({
      applyId: Number(route.params.id),
      useDays: f.useDays,
      absorbScore: f.absorbScore,
      mildScore: f.mildScore,
      repurchaseWill: f.repurchaseWill,
      content: f.content,
      imageUrls: f.imageUrls,
      allergicFlag: f.allergic ? 1 : 0,
      symptom: f.allergic ? f.symptom : null
    })
    ElMessage.success('报告已提交，等待审核')
    router.push('/portal/my')
  } finally {
    saving.value = false
  }
}

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
.wrap { width: 860px; margin: 0 auto; padding: 22px 0 46px; }
.crumb { font-size: 12px; color: var(--bt-text-3); margin-bottom: 14px; }
.crumb a { color: var(--bt-text-3); }
.hd { display: flex; justify-content: space-between; align-items: center; padding-bottom: 16px; border-bottom: 1px solid var(--bt-line); margin-bottom: 18px; }
.g { display: flex; gap: 12px; align-items: center; }
.g img { width: 56px; height: 56px; border-radius: 10px; object-fit: cover; }
.g h2 { font-size: 18px; margin: 0 0 4px; }
.ups { display: flex; gap: 10px; }
.up { position: relative; width: 88px; height: 88px; }
.up img { width: 100%; height: 100%; object-fit: cover; border-radius: 8px; }
.del { position: absolute; right: -6px; top: -6px; width: 18px; height: 18px; border-radius: 50%; background: #c0392b; color: #fff; font-size: 12px; line-height: 18px; text-align: center; cursor: pointer; }
.add { width: 88px; height: 88px; border: 1px dashed var(--bt-line); border-radius: 8px; display: grid; place-items: center; font-size: 18px; color: var(--bt-text-3); text-align: center; line-height: 1.3; }
.add span { font-size: 11px; }
</style>
