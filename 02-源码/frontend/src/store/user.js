import { reactive, computed } from 'vue'

// 轻量全局状态，持久化到 localStorage，键统一 bt_ 前缀
const saved = (k, d) => {
  try {
    const v = localStorage.getItem(k)
    return v ? JSON.parse(v) : d
  } catch (e) {
    return d
  }
}

export const store = reactive({
  user: saved('bt_user', null),
  menus: saved('bt_menus', []),
  dicts: {},
  unread: 0,
  // 当前后台视图的 component 路径（goods/list 这类），由路由守卫写入
  currentComp: 'dashboard/index'
})

export const isLogin = computed(() => !!store.user)
export const roleCode = computed(() => store.user?.roleCode || '')
export const isBackend = computed(() => ['admin', 'operator', 'auditor', 'service', 'analyst'].includes(roleCode.value))

export function setLogin(data) {
  store.user = data.user
  store.menus = data.menus || []
  store.unread = data.unread || 0
  store.dicts = data.dicts || {}
  localStorage.setItem('bt_user', JSON.stringify(data.user))
  localStorage.setItem('bt_menus', JSON.stringify(data.menus || []))
}

export function setMe(data) {
  store.user = data.user
  store.unread = data.unread || 0
  if (data.dicts) store.dicts = data.dicts
  localStorage.setItem('bt_user', JSON.stringify(data.user))
}

export function setMenus(list) {
  store.menus = list || []
  localStorage.setItem('bt_menus', JSON.stringify(store.menus))
}

export function setDicts(d) {
  store.dicts = d || {}
}

// 字典取选项：store.dicts[type] 形如 [{label,value}]
export function dictOptions(type) {
  const arr = store.dicts?.[type] || []
  if (arr.length) return arr
  return []
}

export function dictLabel(type, value) {
  const hit = (store.dicts?.[type] || []).find((x) => x.value === value || x.code === value)
  return hit ? hit.label || hit.name : value
}
