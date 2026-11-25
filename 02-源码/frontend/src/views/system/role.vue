<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">角色管理</h3>
        <div class="page-sub">6 个内置角色，菜单按角色动态下发；修改后相关账号重新登录即生效</div>
      </div>
      <el-button :icon="Refresh" @click="load">刷新</el-button>
    </div>

    <div class="card">
      <el-table :data="rows" v-loading="loading" stripe>
        <el-table-column prop="roleName" label="角色名称" min-width="140" />
        <el-table-column prop="roleCode" label="角色标识" width="150">
          <template #default="{ row }"><span class="mono">{{ row.roleCode }}</span></template>
        </el-table-column>
        <el-table-column prop="dataScope" label="数据范围" width="130">
          <template #default="{ row }">{{ row.dataScope || '本人及下级' }}</template>
        </el-table-column>
        <el-table-column prop="remark" label="职责说明" min-width="260" show-overflow-tooltip />
        <el-table-column label="菜单数" width="90">
          <template #default="{ row }">{{ (row.menuIds || []).length }}</template>
        </el-table-column>
        <el-table-column label="状态" width="90">
          <template #default="{ row }">
            <span class="tag" :class="row.status === 1 ? 'ok' : 'info'">{{ row.status === 1 ? '启用' : '停用' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openAssign(row)">分配菜单</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <el-dialog v-model="dlg" :title="`为「${cur.roleName || ''}」分配菜单`" width="560px">
      <div class="note-box" style="margin-bottom: 10px">
        勾选后该角色登录时只看到被授权的菜单；「菜单管理」「分配菜单」自身不对任何角色开放。
      </div>
      <el-tree ref="treeRef" :data="tree" node-key="id" show-checkbox default-expand-all
               :props="{ label: 'menuName', children: 'children' }" style="max-height: 420px; overflow: auto" />
      <template #footer>
        <el-button @click="dlg = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">保存授权</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, nextTick, onMounted } from 'vue'
import { Refresh } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { roleList, menuTree, assignMenus } from '../../api'

const rows = ref([])
const tree = ref([])
const loading = ref(false)
const dlg = ref(false)
const saving = ref(false)
const cur = ref({})
const treeRef = ref(null)

const load = async () => {
  loading.value = true
  try {
    const r = await roleList()
    rows.value = r.data || []
  } finally {
    loading.value = false
  }
}

const openAssign = async (row) => {
  cur.value = row
  if (!tree.value.length) {
    const t = await menuTree()
    tree.value = t.data || []
  }
  dlg.value = true
  await nextTick()
  const ids = row.menuIds || []
  treeRef.value?.setCheckedKeys(ids, false)
}

const save = async () => {
  const checked = treeRef.value.getCheckedKeys()
  const half = treeRef.value.getHalfCheckedKeys()
  saving.value = true
  try {
    await assignMenus(cur.value.id, { menuIds: [...checked, ...half] })
    ElMessage.success('菜单授权已保存')
    dlg.value = false
    load()
  } finally {
    saving.value = false
  }
}

onMounted(load)
</script>
