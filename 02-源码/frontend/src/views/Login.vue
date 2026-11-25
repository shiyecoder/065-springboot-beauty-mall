<template>
  <div class="lg-page">
    <div class="lg-left">
      <div class="lg-brand">
        LUMA 美妆
        <small>BEAUTY TRIAL CLOUD</small>
      </div>
      <div class="lg-desc">
        <div style="font-size: 20px; font-weight: 600; margin-bottom: 14px;">先试后买，让每一份试用装都能被追踪</div>
        肤质档案建档 → 试用装申领 → 审核发放 → 报告回收 → 转化归因。<br />
        五个维度的转化概率计算，加上规则版本留痕与人工修正，让派发预算花在高意向用户身上。
      </div>
      <div class="lg-points">
        <div><b>26</b><span>在售商品</span></div>
        <div><b>70</b><span>申领单</span></div>
        <div><b>5</b><span>转化因素</span></div>
        <div><b>6</b><span>业务角色</span></div>
      </div>
    </div>

    <div class="lg-right">
      <div class="lg-card">
        <h2>登录运营后台</h2>
        <p>试用装派发与转化跟踪中台</p>
        <el-form :model="form" @submit.prevent>
          <el-form-item class="lg-field">
            <el-input v-model="form.username" size="large" placeholder="账号" :prefix-icon="User" />
          </el-form-item>
          <el-form-item class="lg-field">
            <el-input v-model="form.password" size="large" type="password" show-password placeholder="密码"
                      :prefix-icon="Lock" @keyup.enter="submit" />
          </el-form-item>
          <el-button type="primary" size="large" class="lg-submit" :loading="loading" @click="submit">
            登 录
          </el-button>
        </el-form>
        <div class="lg-demo">
          演示账号（admin 密码 admin123，其余均为 123456）：
          <div>
            <b v-for="a in DEMO" :key="a.u" @click="fill(a)">{{ a.n }}</b>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { User, Lock } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { login } from '../api'
import { setLogin, setDicts } from '../store/user'
import { setToken } from '../api/request'

const router = useRouter()
const loading = ref(false)
const form = reactive({ username: 'admin', password: '123456' })

const DEMO = [
  { u: 'admin', p: 'admin123', n: '系统管理员' },
  { u: 'operator', p: '123456', n: '品牌运营' },
  { u: 'auditor01', p: '123456', n: '内容审核员' },
  { u: 'service01', p: '123456', n: '客服专员' },
  { u: 'analyst01', p: '123456', n: '数据分析员' },
  { u: 'user22', p: '123456', n: '试用用户' }
]

// 每个演示账号自带密码：管理员为 admin123，其余统一 123456
const fill = (a) => {
  form.username = a.u
  form.password = a.p
}

const submit = async () => {
  if (!form.username || !form.password) return ElMessage.warning('请输入账号和密码')
  loading.value = true
  try {
    const r = await login({ username: form.username.trim(), password: form.password })
    setToken(r.data.token)
    setLogin(r.data)
    setDicts(r.data.dicts)
    ElMessage.success(`欢迎回来，${r.data.user.realName}`)
    router.replace(r.data.user.roleCode === 'user' ? '/portal/home' : '/admin')
  } catch (e) {
    /* 错误提示已由拦截器统一处理 */
  } finally {
    loading.value = false
  }
}
</script>
