<template>
  <div>
    <div class="page-header">
      <div>
        <h2 class="page-title">入驻审核</h2>
        <p class="page-subtitle">审核团队方的入驻申请</p>
      </div>
    </div>

    <!-- Status Tabs -->
    <div class="status-tabs" role="tablist">
      <div
        v-for="tab in statusTabs"
        :key="tab.value"
        :class="['status-tab', { active: activeTab === tab.value }]"
        role="tab"
        tabindex="0"
        :aria-selected="activeTab === tab.value"
        @click="switchTab(tab.value)"
        @keydown.enter="switchTab(tab.value)"
        @keydown.space.prevent="switchTab(tab.value)"
      >
        {{ tab.label }}
        <span v-if="tab.value === 1 && pendingCount > 0" class="tab-badge">
          {{ pendingCount }}
        </span>
      </div>
    </div>

    <div class="filter-bar">
      <el-date-picker
        v-model="dateRange"
        type="daterange"
        range-separator="至"
        start-placeholder="申请开始日期"
        end-placeholder="申请结束日期"
        value-format="YYYY-MM-DD"
        style="width: 300px"
        @change="handleSearch"
      />
      <el-button @click="handleSearch">查询</el-button>
    </div>

    <div class="table-card">
      <el-table v-loading="loading" :data="tableData" stripe>
        <el-table-column label="用户" width="200">
          <template #default="{ row }">
            <div class="user-cell">
              <el-avatar :size="32" :src="row.avatar_url">
                {{ (row.nickname || '?')[0] }}
              </el-avatar>
              <div class="user-info">
                <span class="user-nickname">{{ row.nickname || '-' }}</span>
                <span class="user-role">{{ USER_ROLES[row.role] || '未知' }}</span>
              </div>
            </div>
          </template>
        </el-table-column>

        <el-table-column label="申请备注" min-width="200" show-overflow-tooltip>
          <template #default="{ row }">
            {{ row.onboarding_application_note || '-' }}
          </template>
        </el-table-column>

        <el-table-column label="简历" width="100" align="center">
          <template #default="{ row }">
            <el-button
              v-if="row.resume_url"
              link
              size="small"
              @click="openUrl(row.resume_url)"
            >
              查看
            </el-button>
            <span v-else class="text-muted">无</span>
          </template>
        </el-table-column>

        <el-table-column label="申请时间" width="160">
          <template #default="{ row }">
            {{ formatDate(row.onboarding_submitted_at) }}
          </template>
        </el-table-column>

        <el-table-column label="审核状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag
              :type="ONBOARDING_STATUS[row.onboarding_status]?.type ?? 'info'"
              size="small"
              round
            >
              {{ ONBOARDING_STATUS[row.onboarding_status]?.label || '未知' }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column label="审核时间" width="160">
          <template #default="{ row }">
            {{ formatDate(row.onboarding_reviewed_at) }}
          </template>
        </el-table-column>

        <el-table-column label="操作" width="160" fixed="right" align="center">
          <template #default="{ row }">
            <template v-if="row.onboarding_status === 1">
              <el-button
                type="primary"
                size="small"
                @click="handleApprove(row)"
              >
                通过
              </el-button>
              <el-button
                type="danger"
                size="small"
                plain
                @click="handleReject(row)"
              >
                拒绝
              </el-button>
            </template>
            <span v-else class="text-muted">已处理</span>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-wrapper">
        <el-pagination
          v-model:current-page="pagination.page"
          v-model:page-size="pagination.page_size"
          :total="pagination.total"
          :page-sizes="[20, 50, 100]"
          layout="total, sizes, prev, pager, next"
          @current-change="handlePageChange"
          @size-change="handleSizeChange"
        />
      </div>
    </div>

    <!-- Reject Dialog -->
    <el-dialog
      v-model="showRejectDialog"
      title="拒绝入驻申请"
      width="480px"
      destroy-on-close
    >
      <el-form label-position="top">
        <el-form-item label="拒绝原因" required>
          <el-input
            v-model="rejectReason"
            type="textarea"
            :rows="4"
            placeholder="请输入拒绝原因（将发送给申请人）"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showRejectDialog = false">取消</el-button>
        <el-button
          type="danger"
          :loading="submitting"
          :disabled="!rejectReason.trim()"
          @click="confirmReject"
        >
          确认拒绝
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useTable } from '@/composables/useTable'
import { getUsers, updateUserOnboarding } from '@/api/users'
import { formatDate } from '@/utils/format'
import { USER_ROLES, ONBOARDING_STATUS } from '@/utils/constants'
import type { User } from '@/types/user'

function openUrl(url: string) {
  window.open(url, '_blank')
}

const activeTab = ref(1)
const pendingCount = ref(0)
const dateRange = ref<string[]>([])

const statusTabs = [
  { label: '待审核', value: 1 },
  { label: '已通过', value: 2 },
  { label: '已拒绝', value: 3 },
]

const { loading, tableData, pagination, loadData, handlePageChange, handleSizeChange } =
  useTable<User>(getUsers)

function buildParams() {
  const params: Record<string, any> = {
    onboarding_status: activeTab.value,
  }
  if (dateRange.value?.length === 2) {
    params.start_date = dateRange.value[0]
    params.end_date = dateRange.value[1]
  }
  return params
}

function handleSearch() {
  pagination.page = 1
  loadData(buildParams())
}

function switchTab(tab: number) {
  activeTab.value = tab
  pagination.page = 1
  loadData(buildParams())
}

// ---- Approve ----
async function handleApprove(row: User) {
  try {
    await ElMessageBox.confirm(
      `确认通过 ${row.nickname} 的入驻申请？`,
      '通过确认',
      { confirmButtonText: '确认通过', cancelButtonText: '取消', type: 'success' },
    )
    await updateUserOnboarding(row.uuid, { status: 'approved' })
    ElMessage.success('已通过')
    loadData(buildParams())
    loadPendingCount()
  } catch {
    // cancelled
  }
}

// ---- Reject ----
const showRejectDialog = ref(false)
const rejectReason = ref('')
const submitting = ref(false)
let rejectTarget: User | null = null

function handleReject(row: User) {
  rejectTarget = row
  rejectReason.value = ''
  showRejectDialog.value = true
}

async function confirmReject() {
  if (!rejectTarget || !rejectReason.value.trim()) return
  submitting.value = true
  try {
    await updateUserOnboarding(rejectTarget.uuid, {
      status: 'rejected',
      reason: rejectReason.value.trim(),
    })
    ElMessage.success('已拒绝')
    showRejectDialog.value = false
    loadData(buildParams())
    loadPendingCount()
  } catch {
    // handled by interceptor
  } finally {
    submitting.value = false
  }
}

async function loadPendingCount() {
  try {
    const res: any = await getUsers({ onboarding_status: 1, page: 1, page_size: 1 })
    pendingCount.value = res.meta?.total ?? 0
  } catch {
    pendingCount.value = 0
  }
}

onMounted(() => {
  loadData(buildParams())
  loadPendingCount()
})
</script>

<style scoped>
.status-tabs {
  display: flex;
  gap: 4px;
  margin-bottom: 16px;
  background: #fff;
  border-radius: 10px;
  padding: 6px;
  width: fit-content;
}

.status-tab {
  padding: 8px 20px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #666;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 6px;
}

.status-tab:hover {
  color: #333;
  background: #f5f5f5;
}

.status-tab.active {
  background: #1a1c1c;
  color: #fff;
}

.tab-badge {
  background: #ef4444;
  color: #fff;
  font-size: 11px;
  font-weight: 600;
  min-width: 18px;
  height: 18px;
  border-radius: 9px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0 5px;
}

.status-tab.active .tab-badge {
  background: #fff;
  color: #1a1c1c;
}

.user-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}

.user-info {
  display: flex;
  flex-direction: column;
}

.user-nickname {
  font-size: 13px;
  font-weight: 600;
  color: #1a1c1c;
}

.user-role {
  font-size: 11px;
  color: #999;
}

.text-muted {
  color: #ccc;
  font-size: 12px;
}
</style>
