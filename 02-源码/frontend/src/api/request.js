import axios from 'axios'
import { ElMessage } from 'element-plus'
import router from '../router'

const TOKEN_KEY = 'bt_token'

export const getToken = () => localStorage.getItem(TOKEN_KEY) || ''
export const setToken = (t) => localStorage.setItem(TOKEN_KEY, t)
export const clearToken = () => {
  localStorage.removeItem(TOKEN_KEY)
  localStorage.removeItem('bt_user')
  localStorage.removeItem('bt_menus')
}

const http = axios.create({ baseURL: '/api', timeout: 20000 })

http.interceptors.request.use((cfg) => {
  const t = getToken()
  if (t) cfg.headers.Authorization = 'Bearer ' + t
  return cfg
})

// 后端统一返回 { code, message, data }，code === 0 才算成功（需求 7.1）
http.interceptors.response.use(
  (res) => {
    const body = res.data
    if (body && typeof body.code !== 'undefined') {
      if (body.code === 0) return body
      if (body.code === 4010 || body.code === 401) {
        clearToken()
        ElMessage.error('登录已过期，请重新登录')
        router.replace('/login')
        return Promise.reject(new Error(body.message))
      }
      ElMessage.error(body.message || '操作失败')
      return Promise.reject(Object.assign(new Error(body.message || '操作失败'), { code: body.code }))
    }
    return body
  },
  (err) => {
    const code = err?.response?.status
    if (code === 401) {
      clearToken()
      router.replace('/login')
    }
    ElMessage.error(err?.response?.data?.message || '网络异常，请稍后再试')
    return Promise.reject(err)
  }
)

export default http
