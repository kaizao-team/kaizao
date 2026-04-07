<template>
  <div>
    <div class="page-header">
      <div class="header-back">
        <el-button text @click="router.back()">
          <el-icon><ArrowLeft /></el-icon>
          返回
        </el-button>
        <h2 class="page-title">用户详情</h2>
      </div>
      <div class="header-actions">
        <el-button
          v-if="user?.status === 1 && user?.role !== 9"
          type="danger"
          plain
          @click="handleFreeze"
        >
          冻结用户
        </el-button>
        <el-button
          v-if="user?.status === 0"
          type="success"
          plain
          @click="handleUnfreeze"
        >
          解冻用户
        </el-button>
      </div>
    </div>

    <div v-loading="loadingUser" class="detail-content">
      <!-- Profile Header -->
      <div class="profile-header">
        <el-avatar :size="64" :src="user?.avatar_url ?? undefined">
          {{ (user?.nickname || '?')[0] }}
        </el-avatar>
        <div class="profile-info">
          <div class="profile-name-row">
            <h3 class="profile-name">{{ user?.nickname || '-' }}</h3>
            <el-tag size="small">{{ USER_ROLES[user?.role ?? 0] || '未知' }}</el-tag>
            <el-tag
              :type="USER_STATUS[user?.status ?? 1]?.type ?? 'info'"
              size="small"
              round
            >
              {{ USER_STATUS[user?.status ?? 1]?.label || '未知' }}
            </el-tag>
          </div>
          <div class="profile-meta">
            <span>UUID: <code>{{ user?.uuid }}</code></span>
            <span>手机号: {{ maskPhone(user?.phone || '') }}</span>
            <span>注册时间: {{ formatDate(user?.created_at) }}</span>
          </div>
        </div>
      </div>

      <!-- Tabs -->
      <el-tabs v-model="activeTab" class="detail-tabs">
        <el-tab-pane label="基本信息" name="basic">
          <div class="info-grid">
            <div class="info-item">
              <span class="info-label">入驻状态</span>
              <el-tag
                :type="ONBOARDING_STATUS[user?.onboarding_status ?? 0]?.type ?? 'info'"
                size="small"
              >
                {{ ONBOARDING_STATUS[user?.onboarding_status ?? 0]?.label || '未知' }}
              </el-tag>
            </div>
            <div class="info-item">
              <span class="info-label">信用分</span>
              <span class="info-value mono">{{ user?.credit_score ?? '-' }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">等级</span>
              <span class="info-value">Lv.{{ user?.level ?? 0 }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">完成订单</span>
              <span class="info-value mono">{{ user?.completed_orders ?? 0 }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">最近登录</span>
              <span class="info-value">{{ formatDate(user?.last_login_at) }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">入驻申请备注</span>
              <span class="info-value">{{ user?.onboarding_application_note || '-' }}</span>
            </div>
          </div>
        </el-tab-pane>

        <el-tab-pane label="技能标签" name="skills">
          <div v-if="skills.length" class="skill-tags">
            <el-tag v-for="skill in skills" :key="skill" class="skill-tag">
              {{ skill }}
            </el-tag>
          </div>
          <el-empty v-else description="暂无技能标签" :image-size="80" />
        </el-tab-pane>

        <el-tab-pane label="作品集" name="portfolios">
          <div v-if="portfolios.length" class="portfolio-list">
            <div v-for="item in portfolios" :key="item.uuid" class="portfolio-item">
              <div class="portfolio-title">{{ item.title || '未命名作品' }}</div>
              <div class="portfolio-desc">{{ item.description || '-' }}</div>
              <div class="portfolio-meta">
                <span>{{ formatDate(item.created_at) }}</span>
              </div>
            </div>
          </div>
          <el-empty v-else description="暂无作品集" :image-size="80" />
        </el-tab-pane>

        <!-- Wallet tab: pending backend API implementation -->

      </el-tabs>
    </div>

    <!-- Freeze Dialog -->
    <el-dialog
      v-model="showFreezeDialog"
      title="冻结用户"
      width="480px"
      destroy-on-close
    >
      <p style="color: #666; margin-bottom: 16px; line-height: 1.6">
        确认冻结用户 <strong>{{ user?.nickname }}</strong>？
      </p>
      <el-form label-position="top">
        <el-form-item label="冻结原因" required>
          <el-input
            v-model="freezeReason"
            type="textarea"
            :rows="3"
            placeholder="请输入冻结原因"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showFreezeDialog = false">取消</el-button>
        <el-button
          type="danger"
          :loading="submitting"
          :disabled="!freezeReason.trim()"
          @click="confirmFreeze"
        >
          确认冻结
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ArrowLeft } from '@element-plus/icons-vue'
import { formatDate, maskPhone } from '@/utils/format'
import { USER_ROLES, USER_STATUS, ONBOARDING_STATUS } from '@/utils/constants'
import { getUserDetail, getUserSkills, getUserPortfolios, updateUserStatus } from '@/api/users'
import type { User } from '@/types/user'

const route = useRoute()
const router = useRouter()
const uuid = route.params.uuid as string

const loadingUser = ref(true)
const user = ref<User | null>(null)
const activeTab = ref('basic')
const skills = ref<string[]>([])
const portfolios = ref<any[]>([])

async function loadUser() {
  loadingUser.value = true
  try {
    const res: any = await getUserDetail(uuid)
    user.value = res.data
  } catch {
    // handled
  } finally {
    loadingUser.value = false
  }
}

async function loadSkills() {
  try {
    const res: any = await getUserSkills(uuid)
    skills.value = (res.data || []).map((s: any) => s.name || s.skill_name || s)
  } catch {
    skills.value = []
  }
}

async function loadPortfolios() {
  try {
    const res: any = await getUserPortfolios(uuid)
    portfolios.value = res.data || []
  } catch {
    portfolios.value = []
  }
}

// ---- Freeze / Unfreeze ----
const showFreezeDialog = ref(false)
const freezeReason = ref('')
const submitting = ref(false)

function handleFreeze() {
  freezeReason.value = ''
  showFreezeDialog.value = true
}

async function confirmFreeze() {
  if (!freezeReason.value.trim()) return
  submitting.value = true
  try {
    await updateUserStatus(uuid, { status: 0, reason: freezeReason.value.trim() })
    ElMessage.success('用户已冻结')
    showFreezeDialog.value = false
    loadUser()
  } catch {
    // handled
  } finally {
    submitting.value = false
  }
}

async function handleUnfreeze() {
  try {
    await ElMessageBox.confirm('确认解冻该用户？', '解冻确认', {
      confirmButtonText: '确认解冻',
      cancelButtonText: '取消',
      type: 'warning',
    })
    await updateUserStatus(uuid, { status: 1 })
    ElMessage.success('用户已解冻')
    loadUser()
  } catch {
    // cancelled
  }
}

onMounted(() => {
  loadUser()
  loadSkills()
  loadPortfolios()
})
</script>

<style scoped>
.header-back {
  display: flex;
  align-items: center;
  gap: 8px;
}

.header-actions {
  display: flex;
  gap: 8px;
}

.detail-content {
  min-height: 400px;
}

.profile-header {
  display: flex;
  gap: 20px;
  align-items: flex-start;
  background: #fff;
  border-radius: 10px;
  padding: 24px;
  margin-bottom: 20px;
}

.profile-info {
  flex: 1;
}

.profile-name-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
}

.profile-name {
  font-size: 20px;
  font-weight: 700;
  color: #1a1c1c;
  margin: 0;
}

.profile-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  font-size: 12px;
  color: #999;
}

.profile-meta code {
  font-family: 'SF Mono', monospace;
  font-size: 11px;
  background: #f3f3f3;
  padding: 1px 6px;
  border-radius: 4px;
}

.detail-tabs {
  background: #fff;
  border-radius: 10px;
  padding: 0 24px 24px;
}

.detail-tabs :deep(.el-tabs__header) {
  margin-bottom: 20px;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 20px;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.info-label {
  font-size: 12px;
  font-weight: 600;
  color: #999;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.info-value {
  font-size: 14px;
  color: #1a1c1c;
  font-weight: 500;
}

.info-value.mono {
  font-family: 'SF Mono', monospace;
}

.skill-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.skill-tag {
  font-size: 13px;
}

.portfolio-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 16px;
}

.portfolio-item {
  background: #f9f9f9;
  border-radius: 8px;
  padding: 16px;
}

.portfolio-title {
  font-size: 14px;
  font-weight: 600;
  color: #1a1c1c;
  margin-bottom: 4px;
}

.portfolio-desc {
  font-size: 13px;
  color: #666;
  margin-bottom: 8px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.portfolio-meta {
  font-size: 11px;
  color: #bbb;
}

</style>
