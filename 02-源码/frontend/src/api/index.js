import http from './request'

// ---------- 认证 ----------
export const login = (data) => http.post('/auth/login', data)
export const me = () => http.get('/auth/me')
export const menus = () => http.get('/auth/menus')
export const updateProfile = (data) => http.put('/auth/profile', data)
export const changePassword = (data) => http.put('/auth/password', data)

// ---------- 元数据 ----------
export const dicts = () => http.get('/meta/dicts')
export const notices = () => http.get('/meta/notices')

// ---------- 商品 ----------
export const goodsPage = (params) => http.get('/cosmetic-goods/page', { params })
export const goodsDetail = (id) => http.get(`/cosmetic-goods/${id}`)
export const goodsSave = (data) => (data.id ? http.put(`/cosmetic-goods/${data.id}`, data) : http.post('/cosmetic-goods', data))
export const goodsDelete = (id) => http.delete(`/cosmetic-goods/${id}`)

// ---------- 试用装 ----------
export const samplePage = (params) => http.get('/sample-sku/page', { params })
export const sampleDetail = (id) => http.get(`/sample-sku/${id}`)
export const sampleSave = (data) => (data.id ? http.put(`/sample-sku/${data.id}`, data) : http.post('/sample-sku', data))
export const sampleDelete = (id) => http.delete(`/sample-sku/${id}`)
export const stockChange = (data) => http.post('/sample-sku/stock', data)
export const stockLogPage = (params) => http.get('/sample-sku/log/page', { params })

// ---------- 申领 ----------
export const applyPage = (params) => http.get('/sample-apply/page', { params })
export const applyDetail = (id) => http.get(`/sample-apply/${id}`)
export const applyCreate = (data) => http.post('/sample-apply', data)
export const applyAudit = (id, data) => http.post(`/sample-apply/${id}/audit`, data)
export const applySend = (id, data) => http.post(`/sample-apply/${id}/send`, data)
export const applyRequireProfile = (id) => http.post(`/sample-apply/${id}/require-profile`)

// ---------- 报告 ----------
export const reportPage = (params) => http.get('/trial-report/page', { params })
export const reportCreate = (data) => http.post('/trial-report', data)
export const reportAudit = (id, data) => http.post(`/trial-report/${id}/audit`, data)

// ---------- 订单 ----------
export const orderPage = (params) => http.get('/makeup-order/page', { params })
export const orderDetail = (id) => http.get(`/makeup-order/${id}`)
export const orderCreate = (data) => http.post('/makeup-order', data)
export const orderPay = (id) => http.post(`/makeup-order/${id}/pay`)
export const orderShip = (id) => http.post(`/makeup-order/${id}/ship`)
export const orderCancel = (id) => http.post(`/makeup-order/${id}/cancel`)
export const orderRefund = (id, data) => http.post(`/makeup-order/${id}/refund`, data)

// ---------- 转化 ----------
export const trackPage = (params) => http.get('/convert-track/page', { params })
export const trackScore = (id) => http.get(`/convert-track/${id}/score`)
export const trackSnapshot = (id) => http.get(`/convert-track/${id}/snapshot`)
export const trackFollow = (id, data) => http.post(`/convert-track/${id}/follow`, data)
export const trackCorrect = (id, data) => http.post(`/convert-track/${id}/correction`, data)
export const ruleCurrent = () => http.get('/convert-rule/current')
export const ruleList = () => http.get('/convert-rule/list')
export const ruleSave = (data) => http.post('/convert-rule', data)
export const convertBoard = () => http.get('/convert-board')

// ---------- 看板 / 报表 ----------
export const overview = () => http.get('/dashboard/overview')
export const stockWarning = () => http.get('/dashboard/stock-warning')
export const statReport = (params) => http.get('/stat/report', { params })

// ---------- 系统 ----------
export const userPage = (params) => http.get('/system/user/page', { params })
export const userSave = (data) => http.post('/system/user', data)
export const userReset = (id) => http.post(`/system/user/${id}/reset`)
export const roleList = () => http.get('/system/role/list')
export const assignMenus = (id, data) => http.post(`/system/role/${id}/menus`, data)
export const menuTree = () => http.get('/system/menu/tree')
export const dictList = (params) => http.get('/system/dict/list', { params })
export const logPage = (params) => http.get('/system/log/page', { params })
export const messageList = (params) => http.get('/system/message/list', { params })
export const readMessage = (id) => http.post(`/system/message/${id}/read`)
export const readAllMessage = () => http.post('/system/message/read-all')

// ---------- 肤质档案 ----------
export const myProfile = () => http.get('/skin-profile/mine')
export const profilePage = (params) => http.get('/skin-profile/page', { params })
export const skinSubmit = (data) => http.post('/skin-profile', data)

// ---------- 文件上传（只用返回值，禁止外链） ----------
export const upload = (file, bizType = 'common') => {
  const fd = new FormData()
  fd.append('file', file)
  return http.post('/file/upload', fd, {
    params: { bizType },
    headers: { 'Content-Type': 'multipart/form-data' }
  })
}
