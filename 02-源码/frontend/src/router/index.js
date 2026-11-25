import { createRouter, createWebHashHistory } from 'vue-router'
import { h, defineComponent, defineAsyncComponent } from 'vue'
import { store } from '../store/user'
import AdminLayout from '../layout/AdminLayout.vue'
import PortalLayout from '../layout/PortalLayout.vue'

// 所有视图按需加载：菜单里的 component 形如 goods/list，对应 views/goods/list.vue
const views = import.meta.glob('../views/**/*.vue')
const cache = new Map()

const loadView = (comp) => {
  if (cache.has(comp)) return cache.get(comp)
  const loader = views[`../views/${comp}.vue`] || (() => import('../views/404.vue'))
  const c = defineAsyncComponent(loader)
  cache.set(comp, c)
  return c
}

// 后台采用单条动态路由 /admin/:comp，避免登录后重建 matcher 导致的 404
const AdminHost = defineComponent({
  name: 'AdminHost',
  setup() {
    return () => h(loadView(store.currentComp))
  }
})

const routes = [
  { path: '/login', name: 'login', component: () => import('../views/Login.vue') },
  {
    path: '/portal',
    component: PortalLayout,
    redirect: '/portal/home',
    children: [
      { path: 'home', component: () => import('../views/portal/Home.vue'), meta: { title: '商城首页' } },
      { path: 'trial', component: () => import('../views/portal/Trial.vue'), meta: { title: '试用活动' } },
      { path: 'goods/:id', component: () => import('../views/portal/GoodsDetail.vue'), meta: { title: '商品详情' } },
      { path: 'apply/:id', component: () => import('../views/portal/ApplyDetail.vue'), meta: { title: '申领详情' } },
      { path: 'my', component: () => import('../views/portal/MyTrial.vue'), meta: { title: '我的试用' } },
      { path: 'report/:id', component: () => import('../views/portal/ReportForm.vue'), meta: { title: '提交试用报告' } },
      { path: 'orders', component: () => import('../views/portal/Orders.vue'), meta: { title: '我的订单' } },
      { path: 'checkout/:id', component: () => import('../views/portal/Checkout.vue'), meta: { title: '确认下单' } },
      { path: 'skin-test', component: () => import('../views/portal/SkinTest.vue'), meta: { title: '肤质测评' } }
    ]
  },
  {
    path: '/admin',
    component: AdminLayout,
    redirect: '/admin/dashboard/index',
    children: [{ path: ':comp(.*)', name: 'admin-dyn', component: AdminHost }]
  },
  { path: '/', redirect: '/login' },
  { path: '/:pathMatch(.*)*', component: () => import('../views/404.vue') }
]

const router = createRouter({ history: createWebHashHistory(), routes })

// 菜单里所有「菜单」类型项的 component 列表，用于权限校验
function allowedComponents() {
  const out = []
  const walk = (list) => {
    for (const m of list || []) {
      if (m.type === '菜单' && m.component) out.push(m.component)
      if (m.children && m.children.length) walk(m.children)
    }
  }
  walk(store.menus)
  return out
}

router.beforeEach((to) => {
  const token = localStorage.getItem('bt_token')
  if (to.path === '/login') return true
  if (!token) return '/login'

  if (to.path.startsWith('/admin')) {
    // 每次进入后台都用最新菜单，换角色登录后侧边栏与权限同步
    const allowed = allowedComponents()
    const comp = Array.isArray(to.params.comp) ? to.params.comp.join('/') : to.params.comp
    if (!comp) {
      return allowed.length ? `/admin/${allowed[0]}` : true
    }
    if (allowed.length && !allowed.includes(comp)) {
      return `/admin/${allowed[0]}`
    }
    store.currentComp = comp
  }
  return true
})

export default router
