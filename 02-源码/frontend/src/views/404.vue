<template>
  <div class="nf">
    <div class="code">404</div>
    <p>页面不存在，或当前角色没有该菜单权限</p>
    <el-button type="primary" @click="$router.back()">返回上一页</el-button>
  </div>
</template>

<style scoped>
.nf { min-height: 60vh; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 14px; color: var(--bt-text-2); }
.code { font-size: 64px; font-weight: 700; color: var(--bt-primary-light); letter-spacing: 4px; }
</style>
