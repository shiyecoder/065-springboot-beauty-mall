<template>
  <div class="pt">
    <header class="pt-hd">
      <div class="wrap">
        <div class="brand" @click="$router.push('/portal/home')">
          <span class="dot"></span> LUMA 美妆 <small>SKIN FIRST BEAUTY</small>
        </div>
        <nav class="nav">
          <router-link v-for="n in NAV" :key="n.p" :to="n.p" :class="{ on: $route.path === n.p }">{{ n.t }}</router-link>
        </nav>
        <div class="ops">
          <el-badge :value="unread" :hidden="!unread">
            <el-icon class="ic" @click="$router.push('/portal/my')"><ChatDotRound /></el-icon>
          </el-badge>
          <div class="who" v-if="store.user" @click="$router.push('/portal/my')">
            <img class="avatar" :src="store.user.avatar || ''" alt="" />
            <span>{{ store.user.realName }}</span>
          </div>
          <el-dropdown trigger="click" @command="onCmd">
            <el-icon class="ic"><ArrowDown /></el-icon>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="skin">我的肤质档案</el-dropdown-item>
                <el-dropdown-item command="admin" v-if="isBackend">进入运营后台</el-dropdown-item>
                <el-dropdown-item command="logout" divided>退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </div>
    </header>

    <main class="pt-main">
      <router-view v-slot="{ Component }">
        <component :is="Component" :key="$route.fullPath" />
      </router-view>
    </main>

    <footer class="pt-ft">
      <div class="wrap">
        <div>
          <b>LUMA 美妆 · 先试后买</b>
          <p>试用装由品牌方免费提供，申领成功后按批次寄出，收到后 30 天内提交试用报告可提升信用分。</p>
        </div>
        <div class="cols">
          <div><span>关于我们</span><span>品牌合作</span><span>隐私政策</span></div>
          <div class="cp">© 2026 LUMA 美妆护肤商城与试用装派发系统 · 毕业设计演示</div>
        </div>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { store, isBackend } from '../store/user'
import { clearToken } from '../api/request'
import { messageList } from '../api'

const router = useRouter()
const unread = ref(0)
const NAV = [
  { p: '/portal/home', t: '商城首页' },
  { p: '/portal/trial', t: '试用活动' },
  { p: '/portal/my', t: '我的试用' },
  { p: '/portal/orders', t: '我的订单' },
  { p: '/portal/skin-test', t: '肤质测评' }
]

const onCmd = (c) => {
  if (c === 'skin') router.push('/portal/skin-test')
  else if (c === 'admin') router.push('/admin')
  else if (c === 'logout') {
    clearToken()
    router.replace('/login')
  }
}

onMounted(async () => {
  try {
    const r = await messageList()
    // /system/message/list 直接返回数组（最多 50 条），不是分页结构
    const list = Array.isArray(r.data) ? r.data : r.data?.records || []
    unread.value = list.filter((m) => !m.readFlag).length
  } catch (e) {
    unread.value = 0
  }
})
</script>

<style scoped>
.pt { min-height: 100vh; display: flex; flex-direction: column; background: #fff; }
.wrap { width: 1200px; margin: 0 auto; }
.pt-hd { border-bottom: 1px solid var(--bt-line); position: sticky; top: 0; background: rgba(255,255,255,.94); backdrop-filter: blur(8px); z-index: 20; }
.pt-hd .wrap { height: 64px; display: flex; align-items: center; justify-content: space-between; }
.brand { font-size: 18px; font-weight: 700; letter-spacing: .5px; cursor: pointer; display: flex; align-items: center; gap: 8px; }
.brand small { font-size: 9px; letter-spacing: 1.6px; color: var(--bt-text-3); font-weight: 400; }
.dot { width: 10px; height: 10px; border-radius: 50%; background: linear-gradient(135deg, #7a5aa6, #c9a6e0); }
.nav { display: flex; gap: 30px; font-size: 14px; }
.nav a { color: var(--bt-text-2); padding: 6px 0; position: relative; }
.nav a.on { color: var(--bt-primary); font-weight: 600; }
.nav a.on::after { content: ''; position: absolute; left: 0; right: 0; bottom: -2px; height: 2px; background: var(--bt-primary); border-radius: 2px; }
.ops { display: flex; align-items: center; gap: 16px; }
.ic { font-size: 18px; color: var(--bt-text-2); cursor: pointer; }
.who { display: flex; align-items: center; gap: 7px; cursor: pointer; font-size: 13px; color: var(--bt-text-2); }
.pt-main { flex: 1; }
.pt-ft { border-top: 1px solid var(--bt-line); background: #faf8fd; padding: 26px 0; font-size: 12px; color: var(--bt-text-3); }
.pt-ft .wrap { display: flex; justify-content: space-between; gap: 40px; }
.pt-ft b { color: var(--bt-text-2); font-size: 13px; }
.pt-ft p { margin: 6px 0 0; max-width: 520px; line-height: 1.8; }
.cols { text-align: right; display: flex; flex-direction: column; gap: 8px; }
.cols span { margin-left: 14px; }
</style>
