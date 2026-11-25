/**
 * 全局时间/金额格式化函数（需求 7.4-9：全系统统一调用，不各写各的）
 * 后端返回 LocalDateTime 序列化为 "2026-10-31T15:20:00"，这里统一转成 "2026-10-31 15:20"
 */
export function fmt(t) {
  if (!t) return '-'
  return String(t).replace('T', ' ').slice(0, 16)
}

export function fmtDate(t) {
  if (!t) return '-'
  return String(t).replace('T', ' ').slice(0, 10)
}

export function fmtFull(t) {
  if (!t) return '-'
  return String(t).replace('T', ' ').slice(0, 19)
}

export function money(v) {
  if (v === null || v === undefined || v === '') return '0.00'
  return Number(v).toFixed(2)
}

/** 距今天数，用于临期提示 */
export function daysLeft(date) {
  if (!date) return null
  const d = new Date(String(date).replace('T', ' ').replace(/-/g, '/'))
  return Math.ceil((d.getTime() - Date.now()) / 86400000)
}

export default { fmt, fmtDate, fmtFull, money, daysLeft }
