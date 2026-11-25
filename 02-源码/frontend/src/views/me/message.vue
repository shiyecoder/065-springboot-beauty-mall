<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">站内消息</h3>
        <div class="page-sub">审核结果、发货通知、报告驳回原因、库存临期提醒均通过站内信送达</div>
      </div>
      <el-button :disabled="!unread" @click="readAll">全部标记已读</el-button>
    </div>

    <div class="card">
      <div class="msg-tabs">
        <span class="mt" :class="{ on: tab === '' }" @click="tab = ''">全部 {{ rows.length }}</span>
        <span class="mt" :class="{ on: tab === 'unread' }" @click="tab = 'unread'">未读 {{ unread }}</span>
      </div>
      <div v-loading="loading">
        <div v-for="m in shown" :key="m.id" class="msg" :class="{ unread: !m.readFlag }" @click="open(m)">
          <div class="ic" :class="m.readFlag ? 'r' : 'u'">{{ (m.msgType || '通')[0] }}</div>
          <div class="bd">
            <div class="tt">{{ m.title }}</div>
            <div class="ct">{{ m.content }}</div>
            <div class="mt3">{{ fmt(m.createTime) }} · {{ m.msgType || '通知' }}</div>
          </div>
          <span class="tag" :class="m.readFlag ? 'info' : 'warn'">{{ m.readFlag ? '已读' : '未读' }}</span>
        </div>
        <el-empty v-if="!shown.length" description="暂无消息" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { messageList, readMessage, readAllMessage } from '../../api'
import { fmt } from '../../utils/format'

const rows = ref([])
const tab = ref('')
const loading = ref(false)

const unread = computed(() => rows.value.filter((m) => !m.readFlag).length)
const shown = computed(() => (tab.value === 'unread' ? rows.value.filter((m) => !m.readFlag) : rows.value))

const load = async () => {
  loading.value = true
  try {
    const r = await messageList()
    rows.value = Array.isArray(r.data) ? r.data : r.data?.records || []
  } finally {
    loading.value = false
  }
}

const open = async (m) => {
  if (!m.readFlag) {
    await readMessage(m.id)
    m.readFlag = 1
  }
  ElMessage({ message: m.content, duration: 5000, showClose: true })
}

const readAll = async () => {
  await readAllMessage()
  rows.value.forEach((m) => (m.readFlag = 1))
  ElMessage.success('已全部标记为已读')
}

onMounted(load)
</script>

<style scoped>
.msg-tabs { display: flex; gap: 18px; padding-bottom: 12px; border-bottom: 1px solid var(--bt-line); margin-bottom: 6px; }
.mt { font-size: 13px; color: var(--bt-text-2); cursor: pointer; padding: 4px 0; }
.mt.on { color: var(--bt-primary); font-weight: 600; box-shadow: inset 0 -2px 0 var(--bt-primary); }
.msg { display: flex; gap: 12px; align-items: flex-start; padding: 14px 8px; border-bottom: 1px dashed var(--bt-line); cursor: pointer; }
.msg:hover { background: #faf8fd; }
.msg.unread .tt { font-weight: 700; }
.ic { width: 34px; height: 34px; border-radius: 10px; display: grid; place-items: center; font-size: 13px; color: #fff; flex: none; }
.ic.u { background: linear-gradient(135deg, #7a5aa6, #c9a6e0); }
.ic.r { background: #cfc8da; }
.bd { flex: 1; min-width: 0; }
.tt { font-size: 14px; margin-bottom: 4px; }
.ct { font-size: 13px; color: var(--bt-text-2); line-height: 1.7; }
.mt3 { font-size: 11px; color: var(--bt-text-3); margin-top: 6px; }
</style>
