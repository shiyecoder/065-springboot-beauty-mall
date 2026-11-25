<template>
  <div>
    <div class="page-head">
      <div>
        <h3 class="page-title">个人中心</h3>
        <div class="page-sub">头像与资料会同步到右上角，改密码后需要重新登录</div>
      </div>
    </div>

    <div class="g21">
      <div class="card">
        <div class="card-hd"><span>基本资料</span></div>
        <div class="prof">
          <div class="ava-wrap">
            <img class="ava" :src="form.avatar || ''" alt="" />
            <el-upload :show-file-list="false" :http-request="doUpload" accept="image/*">
              <el-button size="small" :icon="Upload">更换头像</el-button>
            </el-upload>
            <div class="muted" style="font-size: 11px; margin-top: 6px">jpg/png，≤5MB</div>
          </div>
          <el-form :model="form" label-width="80px" style="flex: 1">
            <el-form-item label="账号">
              <el-input :model-value="store.user?.username" disabled />
            </el-form-item>
            <el-form-item label="姓名"><el-input v-model="form.realName" /></el-form-item>
            <el-form-item label="手机号"><el-input v-model="form.phone" maxlength="11" /></el-form-item>
            <el-form-item label="邮箱"><el-input v-model="form.email" /></el-form-item>
            <el-form-item label="角色">
              <span class="tag ok">{{ store.user?.roleName || store.user?.roleCode }}</span>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="saving" @click="save">保存资料</el-button>
            </el-form-item>
          </el-form>
        </div>
      </div>

      <div>
        <div class="card">
          <div class="card-hd"><span>账户安全</span></div>
          <el-form :model="pwd" label-width="80px">
            <el-form-item label="原密码">
              <el-input v-model="pwd.oldPassword" type="password" show-password />
            </el-form-item>
            <el-form-item label="新密码">
              <el-input v-model="pwd.newPassword" type="password" show-password placeholder="至少 6 位" />
            </el-form-item>
            <el-form-item label="确认密码">
              <el-input v-model="pwd.confirm" type="password" show-password />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="pwdSaving" @click="savePwd">修改密码</el-button>
            </el-form-item>
          </el-form>
        </div>

        <div class="card" style="margin-top: 12px">
          <div class="card-hd"><span>我的肤质档案</span></div>
          <div v-if="profile" class="kv-list">
            <div><span class="k">肤质类型</span><span>{{ profile.skinType }}</span></div>
            <div><span class="k">敏感等级</span><span>{{ profile.sensitiveLevel }}</span></div>
            <div><span class="k">主要诉求</span><span>{{ profile.demandTags }}</span></div>
            <div><span class="k">自测得分</span><span class="price">{{ profile.selfTestScore }}</span></div>
            <div><span class="k">问卷版本</span><span>{{ profile.paperVersion }}</span></div>
            <div><span class="k">更新日期</span><span>{{ fmt(profile.updateDate) }}</span></div>
          </div>
          <el-empty v-else :image-size="60" description="尚未建档，申领试用装前需先完成肤质测评" />
          <el-button size="small" @click="$router.push('/portal/skin-test')">前往测评</el-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Upload } from '@element-plus/icons-vue'
import { store, setMe } from '../../store/user'
import { updateProfile, changePassword, myProfile, upload } from '../../api'
import { clearToken } from '../../api/request'
import { fmt } from '../../utils/format'

const form = reactive({ realName: '', phone: '', email: '', avatar: '' })
const pwd = reactive({ oldPassword: '', newPassword: '', confirm: '' })
const profile = ref(null)
const saving = ref(false)
const pwdSaving = ref(false)

const load = async () => {
  Object.assign(form, {
    realName: store.user?.realName || '',
    phone: store.user?.phone || '',
    email: store.user?.email || '',
    avatar: store.user?.avatar || ''
  })
  try {
    const r = await myProfile()
    profile.value = r.data || null
  } catch (e) {
    profile.value = null
  }
}

const doUpload = async ({ file }) => {
  const r = await upload(file, 'avatar')
  form.avatar = r.data.filePath
  ElMessage.success('头像已上传，保存后生效')
}

const save = async () => {
  if (!form.realName) return ElMessage.warning('姓名不能为空')
  saving.value = true
  try {
    const r = await updateProfile({ ...form })
    setMe({ user: r.data?.user || { ...store.user, ...form } })
    ElMessage.success('资料已保存')
  } finally {
    saving.value = false
  }
}

const savePwd = async () => {
  if (!pwd.oldPassword || !pwd.newPassword) return ElMessage.warning('请填写原密码与新密码')
  if (pwd.newPassword.length < 6) return ElMessage.warning('新密码至少 6 位')
  if (pwd.newPassword !== pwd.confirm) return ElMessage.warning('两次输入的新密码不一致')
  pwdSaving.value = true
  try {
    await changePassword({ oldPassword: pwd.oldPassword, newPassword: pwd.newPassword })
    ElMessage.success('密码已修改，请重新登录')
    clearToken()
    setTimeout(() => (location.hash = '#/login'), 600)
  } finally {
    pwdSaving.value = false
  }
}

onMounted(load)
</script>

<style scoped>
.prof { display: flex; gap: 26px; }
.ava-wrap { width: 150px; text-align: center; flex: none; }
.ava { width: 96px; height: 96px; border-radius: 50%; object-fit: cover; background: #f1eaf9; display: block; margin: 0 auto 10px; }
.kv-list > div { display: flex; justify-content: space-between; padding: 7px 0; border-bottom: 1px dashed var(--bt-line); font-size: 13px; }
.kv-list .k { color: var(--bt-text-3); }
</style>
