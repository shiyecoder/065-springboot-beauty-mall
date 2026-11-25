<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">用户管理</h3>
        <div class="page-sub">账号与角色绑定、信用分与状态维护；重置密码后为默认密码 123456</div>
      </div>
      <div>
        <el-button :icon="Refresh" @click="load">刷新</el-button>
        <el-button type="primary" :icon="Plus" @click="open()">新增用户</el-button>
      </div>
    </div>

    <div class="filter-bar">
      <el-input v-model="q.keyword" placeholder="用户名 / 姓名 / 手机号" clearable style="width: 220px" @keyup.enter="search" />
      <el-select v-model="q.roleId" placeholder="全部角色" clearable style="width: 180px">
        <el-option v-for="r in roles" :key="r.id" :label="r.roleName" :value="r.id" />
      </el-select>
      <el-button type="primary" :icon="Search" @click="search">查询</el-button>
      <el-button @click="reset">重置</el-button>
      <span class="muted" style="margin-left: auto; font-size: 12px">共 {{ total }} 个账号</span>
    </div>

    <div class="card">
      <el-table :data="rows" v-loading="loading" stripe>
        <el-table-column label="头像" width="70">
          <template #default="{ row }">
            <img v-if="row.avatar" class="avatar" :src="row.avatar" alt="" />
            <div v-else class="avatar ph">{{ (row.realName || '?').slice(0, 1) }}</div>
          </template>
        </el-table-column>
        <el-table-column prop="username" label="登录名" width="120" />
        <el-table-column prop="realName" label="姓名" width="110" />
        <el-table-column prop="phone" label="手机号" width="140" />
        <el-table-column label="角色" width="120">
          <template #default="{ row }"><span class="tag">{{ row.roleName || '-' }}</span></template>
        </el-table-column>
        <el-table-column label="信用分" width="110">
          <template #default="{ row }">
            <b :style="{ color: (row.creditScore || 0) < 80 ? 'var(--bt-bad)' : 'var(--bt-ok)' }">{{ row.creditScore ?? '-' }}</b>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="90">
          <template #default="{ row }">
            <span class="tag" :class="row.status === 1 ? 'ok' : 'bad'">{{ row.status === 1 ? '启用' : '停用' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="创建时间" width="150">
          <template #default="{ row }">{{ fmt(row.createTime) }}</template>
        </el-table-column>
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="open(row)">编辑</el-button>
            <el-button link type="warning" @click="resetPwd(row)">重置密码</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next, sizes" :total="total"
                       v-model:current-page="q.page" v-model:page-size="q.size"
                       :page-sizes="[10, 20, 50]" @current-change="load" @size-change="search" />
      </div>
    </div>

    <el-dialog v-model="dlg" :title="form.id ? '编辑用户' : '新增用户'" width="520px">
      <el-form :model="form" label-width="90px">
        <el-form-item label="登录名"><el-input v-model="form.username" :disabled="!!form.id" /></el-form-item>
        <el-form-item label="姓名"><el-input v-model="form.realName" /></el-form-item>
        <el-form-item label="手机号"><el-input v-model="form.phone" /></el-form-item>
        <el-form-item label="角色">
          <el-select v-model="form.roleId" style="width: 100%">
            <el-option v-for="r in roles" :key="r.id" :label="r.roleName" :value="r.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="信用分"><el-input-number v-model="form.creditScore" :min="0" :max="100" style="width: 100%" /></el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="form.status">
            <el-radio :label="1">启用</el-radio>
            <el-radio :label="0">停用</el-radio>
          </el-radio-group>
        </el-form-item>
        <div class="note-box">新增用户默认密码 123456；信用分低于 80 的用户申领需人工复核。</div>
      </el-form>
      <template #footer>
        <el-button @click="dlg = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { Plus, Search, Refresh } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { userPage, userSave, userReset, roleList } from '../../api'

const q = reactive({ page: 1, size: 10, keyword: '', roleId: '' })
const rows = ref([])
const total = ref(0)
const loading = ref(false)
const dlg = ref(false)
const saving = ref(false)
const form = reactive({})
const roles = ref([])

const load = async () => {
  loading.value = true
  try {
    const r = await userPage(q)
    rows.value = r.data.records || []
    total.value = r.data.total || 0
  } finally {
    loading.value = false
  }
}
const search = () => { q.page = 1; load() }
const reset = () => { q.keyword = ''; q.roleId = ''; search() }

const open = (row) => {
  Object.keys(form).forEach((k) => delete form[k])
  Object.assign(form, row ? { ...row } : { username: '', realName: '', phone: '', roleId: 6, creditScore: 90, status: 1 })
  dlg.value = true
}
const save = async () => {
  if (!form.username || !form.realName) return ElMessage.warning('登录名与姓名不能为空')
  saving.value = true
  try {
    await userSave({ ...form })
    ElMessage.success('保存成功')
    dlg.value = false
    load()
  } finally {
    saving.value = false
  }
}
const resetPwd = async (row) => {
  await ElMessageBox.confirm(`确认将 ${row.realName}（${row.username}）的密码重置为 123456？`, '重置密码', { type: 'warning' })
  await userReset(row.id)
  ElMessage.success('密码已重置为 123456')
}
const fmt = (t) => (t ? String(t).replace('T', ' ').slice(0, 10) : '-')

onMounted(async () => {
  roles.value = (await roleList()).data || []
  load()
})
</script>

<style scoped>
.avatar.ph { display: flex; align-items: center; justify-content: center; background: var(--bt-primary-soft); color: var(--bt-primary); font-size: 12px; }
</style>
