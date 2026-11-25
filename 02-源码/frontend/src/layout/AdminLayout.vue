<template>
  <el-container class="shell">
    <el-aside :width="collapse ? '64px' : '216px'" class="aside">
      <div class="logo">
        <div class="mark">LU</div>
        <div v-show="!collapse" class="txt">
          <b>美妆试销中台</b>
          <span>BEAUTY TRIAL CLOUD</span>
        </div>
      </div>
      <el-scrollbar class="menu-wrap">
        <el-menu :default-active="activeMenu" :collapse="collapse" :collapse-transition="false"
                 background-color="#1f1a2e" text-color="#b9b0cc" active-text-color="#fff" router>
          <template v-for="g in store.menus" :key="g.id">
            <el-sub-menu v-if="g.children && g.children.length" :index="'g' + g.id">
              <template #title>
                <el-icon><component :is="iconOf(g.icon)" /></el-icon>
                <span>{{ g.name }}</span>
              </template>
              <el-menu-item v-for="m in g.children" :key="m.id" :index="'/admin/' + m.component">
                <el-icon><component :is="iconOf(m.icon)" /></el-icon>
                <template #title>{{ m.name }}</template>
              </el-menu-item>
            </el-sub-menu>
            <el-menu-item v-else :index="'/admin/' + g.component">
              <el-icon><component :is="iconOf(g.icon)" /></el-icon>
              <template #title>{{ g.name }}</template>
            </el-menu-item>
          </template>
        </el-menu>
      </el-scrollbar>
    </el-aside>

    <el-container>
      <el-header class="hd">
        <div class="hd-l">
          <el-icon class="fold" @click="collapse = !collapse"><Fold /></el-icon>
          <span class="crumb">{{ crumb }}</span>
        </div>
        <div class="hd-r">
          <el-tooltip content="站内消息" placement="bottom">
            <el-badge :value="store.unread" :hidden="!store.unread" class="bell" @click="go('/admin/me/message')">
              <el-icon><Bell /></el-icon>
            </el-badge>
          </el-tooltip>
          <div class="who">
            <img class="avatar" :src="store.user?.avatar || ''" alt="" />
            <div class="who-txt">
              <b>{{ store.user?.realName }}</b>
              <span>{{ store.user?.roleName }}</span>
            </div>
          </div>
          <el-dropdown trigger="click" @command="onCmd">
            <el-icon class="more"><ArrowDown /></el-icon>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="profile">个人中心</el-dropdown-item>
                <el-dropdown-item command="portal">前往商城前台</el-dropdown-item>
                <el-dropdown-item command="logout" divided>退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>
      <el-main class="main">
        <router-view v-slot="{ Component }">
          <component :is="Component" :key="$route.fullPath" />
        </router-view>
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { store, setMenus } from '../store/user'
import { clearToken } from '../api/request'
import { me } from '../api'

const collapse = ref(false)
const route = useRoute()
const router = useRouter()

const ICON = {
  dashboard: 'Odometer', shop: 'Goods', order: 'Tickets', report: 'Document',
  level: 'TrendCharts', menu: 'Menu', message: 'ChatDotRound', chart: 'DataLine',
  target: 'Aim', skin: 'MagicStick', box: 'Box', truck: 'Van', gavel: 'Stamp',
  gift: 'Present', cart: 'ShoppingCart', rule: 'SetUp', calc: 'Cpu', user: 'User',
  role: 'Avatar', dict: 'Collection', log: 'Tickets'
}
const iconOf = (n) => ICON[n] || 'Grid'

const activeMenu = computed(() => route.path)
// 后台是动态路由，meta.title 不可靠，面包屑统一从菜单树反查（组名 / 菜单名）
const crumb = computed(() => {
  const comp = Array.isArray(route.params.comp) ? route.params.comp.join('/') : route.params.comp || ''
  let group = null
  let menu = null
  for (const g of store.menus || []) {
    const hit = (g.children || []).find((m) => m.component === comp)
    if (hit) {
      group = g
      menu = hit
      break
    }
    if (g.component === comp) menu = g
  }
  const name = menu?.name || route.meta?.title || ''
  return group ? `${group.name} / ${name}` : name
})

const go = (p) => router.push(p)
const onCmd = (c) => {
  if (c === 'profile') router.push('/admin/me/profile')
  else if (c === 'portal') router.push('/portal/home')
  else if (c === 'logout') {
    clearToken()
    router.replace('/login')
  }
}

// 刷新菜单与未读数，保证换角色登录后侧边栏正确
me().then((r) => {
  if (r?.data?.menus) setMenus(r.data.menus)
  if (r?.data) store.unread = r.data.unread || 0
}).catch(() => {})
</script>

<style scoped>
.shell { height: 100vh; }
.aside { background: #1f1a2e; transition: width .2s; overflow: hidden; }
.logo { height: 60px; display: flex; align-items: center; gap: 10px; padding: 0 16px; border-bottom: 1px solid rgba(255,255,255,.07); }
.mark { width: 32px; height: 32px; border-radius: 9px; background: linear-gradient(135deg, #8f6cb8, #b79ad4); color: #fff; font-weight: 700; font-size: 13px; display: flex; align-items: center; justify-content: center; letter-spacing: .5px; }
.txt b { display: block; color: #fff; font-size: 14px; letter-spacing: .5px; }
.txt span { display: block; color: #7d7395; font-size: 9px; letter-spacing: 1.2px; margin-top: 2px; }
.menu-wrap { height: calc(100vh - 60px); }
.aside :deep(.el-menu) { border-right: none; }
.aside :deep(.el-menu-item.is-active) { background: linear-gradient(90deg, #7a5aa6, #8f6cb8) !important; }
.aside :deep(.el-sub-menu .el-menu-item) { padding-left: 44px !important; height: 42px; line-height: 42px; }
.hd { height: 60px; background: #fff; border-bottom: 1px solid var(--bt-line); display: flex; align-items: center; justify-content: space-between; padding: 0 20px; }
.hd-l { display: flex; align-items: center; gap: 14px; }
.fold { font-size: 18px; color: var(--bt-text-2); cursor: pointer; }
.crumb { font-size: 14px; color: var(--bt-text-2); }
.hd-r { display: flex; align-items: center; gap: 18px; }
.bell { cursor: pointer; font-size: 18px; color: var(--bt-text-2); }
.who { display: flex; align-items: center; gap: 8px; }
.who-txt b { display: block; font-size: 13px; }
.who-txt span { display: block; font-size: 11px; color: var(--bt-text-3); }
.more { cursor: pointer; color: var(--bt-text-3); }
.main { background: var(--bt-bg); padding: 16px 18px; }
</style>
