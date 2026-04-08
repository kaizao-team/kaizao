<template>
  <div class="login-wrapper">
    <div class="login-left">
      <div class="brand-area">
        <div class="brand-mark">K</div>
        <h1 class="brand-name">开造</h1>
        <p class="brand-tagline">AI 驱动的软件需求撮合平台</p>
      </div>
      <div class="brand-decoration">
        <div class="deco-line" />
        <div class="deco-line" />
        <div class="deco-line" />
      </div>
    </div>

    <div class="login-right">
      <div class="login-card">
        <div class="login-header">
          <h2 class="login-title">管理后台</h2>
          <p class="login-desc">请使用管理员账号登录</p>
        </div>

        <el-form
          ref="formRef"
          :model="form"
          :rules="rules"
          label-position="top"
          size="large"
          @submit.prevent="handleLogin"
        >
          <el-form-item prop="identity" label="手机号 / 用户名" class="login-form-item">
            <el-input
              v-model="form.identity"
              placeholder="请输入手机号或用户名"
              clearable
              class="login-input"
            >
              <template #prefix>
                <el-icon class="input-icon"><User /></el-icon>
              </template>
            </el-input>
          </el-form-item>

          <el-form-item prop="password" label="密码" class="login-form-item">
            <el-input
              v-model="form.password"
              type="password"
              placeholder="请输入密码"
              show-password
              class="login-input"
            >
              <template #prefix>
                <el-icon class="input-icon"><Lock /></el-icon>
              </template>
            </el-input>
          </el-form-item>

          <el-form-item prop="captchaCode" label="验证码" class="login-form-item">
            <div class="captcha-row">
              <el-input
                v-model="form.captchaCode"
                placeholder="请输入验证码"
                clearable
                class="login-input captcha-input"
                @keyup.enter="handleLogin"
              />
              <div
                class="captcha-image"
                :class="{ loading: captchaLoading }"
                @click="refreshCaptcha"
              >
                <img
                  v-if="captchaImage"
                  :src="captchaImage"
                  alt="验证码"
                />
                <span v-else class="captcha-placeholder">加载中</span>
              </div>
            </div>
          </el-form-item>

          <el-form-item>
            <el-button
              :loading="loading"
              class="login-btn"
              @click="handleLogin"
            >
              {{ loading ? '登录中...' : '登 录' }}
            </el-button>
          </el-form-item>
        </el-form>

        <div class="login-footer">
          <span class="footer-text">开造平台运营管理系统 v1.0</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import { User, Lock } from '@element-plus/icons-vue'
import { loginByPassword, getPasswordKey, getCaptcha } from '@/api/auth'
import { useUserStore } from '@/stores/user'
import { encryptPassword } from '@/utils/crypto'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const formRef = ref<FormInstance>()
const loading = ref(false)
const captchaLoading = ref(false)

const captchaId = ref('')
const captchaImage = ref('')
const publicKeyPEM = ref('')

const form = reactive({
  identity: '',
  password: '',
  captchaCode: '',
})

const rules: FormRules = {
  identity: [{ required: true, message: '请输入手机号或用户名', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }],
  captchaCode: [{ required: true, message: '请输入验证码', trigger: 'blur' }],
}

async function refreshCaptcha() {
  captchaLoading.value = true
  try {
    const res: any = await getCaptcha()
    captchaId.value = res.data.captcha_id
    captchaImage.value = res.data.image_base64.startsWith('data:')
      ? res.data.image_base64
      : `data:image/png;base64,${res.data.image_base64}`
  } catch {
    captchaImage.value = ''
  } finally {
    captchaLoading.value = false
  }
}

async function fetchPublicKey() {
  try {
    const res: any = await getPasswordKey()
    publicKeyPEM.value = res.data.public_key_pem
  } catch {
    ElMessage.warning('无法获取加密公钥，请检查后端配置')
  }
}

onMounted(() => {
  refreshCaptcha()
  fetchPublicKey()
})

function detectLoginType(identity: string): 'phone' | 'username' {
  return /^1[3-9]\d{9}$/.test(identity) ? 'phone' : 'username'
}

async function handleLogin() {
  if (!formRef.value) return
  await formRef.value.validate()

  if (!publicKeyPEM.value) {
    ElMessage.error('加密公钥未加载，请刷新页面重试')
    return
  }

  loading.value = true
  try {
    const cipher = await encryptPassword(publicKeyPEM.value, form.password)

    const res: any = await loginByPassword({
      login_type: detectLoginType(form.identity),
      identity: form.identity,
      password_cipher: cipher,
      captcha_id: captchaId.value,
      captcha_code: form.captchaCode,
      device_type: 'web',
    })

    const data = res.data
    const role = data.role
    if (role !== 9) {
      ElMessage.error('权限不足，仅管理员可登录')
      return
    }

    userStore.setToken(data.access_token)
    userStore.setUser({
      uuid: data.user_id,
      nickname: '',
      role: data.role,
      phone: form.identity,
      status: 1,
    })
    ElMessage.success('登录成功')

    const redirect = route.query.redirect as string
    const safeRedirect =
      redirect && redirect.startsWith('/') && !redirect.startsWith('//')
        ? redirect
        : '/dashboard'
    router.push(safeRedirect)
  } catch {
    refreshCaptcha()
    form.captchaCode = ''
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-wrapper {
  display: flex;
  min-height: 100vh;
  width: 100vw;
}

.login-left {
  flex: 1;
  background: #111111;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
}

.brand-area {
  text-align: center;
  z-index: 1;
}

.brand-mark {
  width: 64px;
  height: 64px;
  border-radius: 16px;
  background: #fff;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-weight: 800;
  font-size: 28px;
  color: #111;
  margin-bottom: 24px;
}

.brand-name {
  font-size: 36px;
  font-weight: 700;
  color: #fff;
  margin: 0 0 8px;
  letter-spacing: 4px;
}

.brand-tagline {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.5);
  margin: 0;
  letter-spacing: 1px;
}

.brand-decoration {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 200px;
}

.deco-line {
  position: absolute;
  left: 0;
  right: 0;
  height: 1px;
  background: rgba(255, 255, 255, 0.04);
}

.deco-line:nth-child(1) { bottom: 60px; }
.deco-line:nth-child(2) { bottom: 120px; }
.deco-line:nth-child(3) { bottom: 180px; }

.login-right {
  width: 480px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f9f9f9;
}

.login-card {
  width: 360px;
}

.login-header {
  margin-bottom: 36px;
}

.login-title {
  font-size: 24px;
  font-weight: 700;
  color: #1a1c1c;
  margin: 0 0 8px;
}

.login-desc {
  font-size: 14px;
  color: #999;
  margin: 0;
}

.login-input :deep(.el-input__wrapper) {
  border-radius: 10px;
  padding: 4px 16px;
  box-shadow: 0 0 0 1px #e0e0e0;
  background: #fff;
  transition: box-shadow 0.2s;
}

.login-input :deep(.el-input__wrapper:hover) {
  box-shadow: 0 0 0 1px #ccc;
}

.login-input :deep(.el-input__wrapper.is-focus) {
  box-shadow: 0 0 0 1.5px #1a1c1c;
}

.login-form-item :deep(.el-form-item__label) {
  font-size: 13px;
  font-weight: 500;
  color: #666;
  padding-bottom: 4px;
}

.input-icon {
  color: #bbb;
}

.captcha-row {
  display: flex;
  gap: 12px;
  width: 100%;
}

.captcha-input {
  flex: 1;
}

.captcha-image {
  width: 120px;
  height: 40px;
  border-radius: 8px;
  overflow: hidden;
  cursor: pointer;
  background: #f3f3f3;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: opacity 0.2s;
}

.captcha-image:hover {
  opacity: 0.8;
}

.captcha-image.loading {
  opacity: 0.5;
}

.captcha-image img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.captcha-placeholder {
  font-size: 12px;
  color: #999;
}

.login-btn {
  width: 100%;
  height: 48px;
  border-radius: 10px;
  font-size: 15px;
  font-weight: 600;
  letter-spacing: 2px;
  background: #1a1c1c;
  border-color: #1a1c1c;
  color: #fff;
  transition: all 0.2s;
}

.login-btn:hover {
  background: #333;
  border-color: #333;
}

.login-btn:active {
  transform: scale(0.98);
}

.login-footer {
  margin-top: 48px;
  text-align: center;
}

.footer-text {
  font-size: 12px;
  color: #ccc;
}

@media (max-width: 900px) {
  .login-left {
    display: none;
  }
  .login-right {
    width: 100%;
  }
}
</style>
