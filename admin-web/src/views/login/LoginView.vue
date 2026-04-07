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
          <el-form-item prop="phone" label="手机号" class="login-form-item">
            <el-input
              v-model="form.phone"
              placeholder="请输入手机号"
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
              @keyup.enter="handleLogin"
            >
              <template #prefix>
                <el-icon class="input-icon"><Lock /></el-icon>
              </template>
            </el-input>
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
import { ref, reactive } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import { User, Lock } from '@element-plus/icons-vue'
import { loginByPassword } from '@/api/auth'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const formRef = ref<FormInstance>()
const loading = ref(false)

const form = reactive({
  phone: '',
  password: '',
})

const rules: FormRules = {
  phone: [
    { required: true, message: '请输入手机号', trigger: 'blur' },
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
  ],
}

async function handleLogin() {
  if (!formRef.value) return
  await formRef.value.validate()

  loading.value = true
  try {
    const res: any = await loginByPassword({
      phone: form.phone,
      password: form.password,
    })

    const { access_token, user } = res.data
    if (user.role !== 9) {
      ElMessage.error('权限不足，仅管理员可登录')
      return
    }

    userStore.setToken(access_token)
    userStore.setUser(user)
    ElMessage.success('登录成功')

    const redirect = route.query.redirect as string
    const safeRedirect = redirect && redirect.startsWith('/') && !redirect.startsWith('//') ? redirect : '/dashboard'
    router.push(safeRedirect)
  } catch {
    // handled by interceptor
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
