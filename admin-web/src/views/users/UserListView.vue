<template>
  <div>
    <div class="page-header">
      <div>
        <h2 class="page-title">用户管理</h2>
        <p class="page-subtitle">管理平台所有注册用户</p>
      </div>
    </div>

    <div class="filter-bar">
      <el-input
        v-model="filters.keyword"
        placeholder="搜索昵称、UUID"
        clearable
        style="width: 260px"
        @clear="handleSearch"
        @keyup.enter="handleSearch"
      >
        <template #prefix>
          <el-icon><Search /></el-icon>
        </template>
      </el-input>

      <el-select
        v-model="filters.role"
        placeholder="角色"
        clearable
        style="width: 130px"
        @change="handleSearch"
      >
        <el-option
          v-for="(label, key) in USER_ROLES"
          :key="key"
          :label="label"
          :value="Number(key)"
        />
      </el-select>

      <el-select
        v-model="filters.status"
        placeholder="状态"
        clearable
        style="width: 120px"
        @change="handleSearch"
      >
        <el-option label="正常" :value="1" />
        <el-option label="已冻结" :value="0" />
      </el-select>

      <el-select
        v-model="filters.onboarding_status"
        placeholder="入驻状态"
        clearable
        style="width: 130px"
        @change="handleSearch"
      >
        <el-option label="待审核" :value="1" />
        <el-option label="已通过" :value="2" />
        <el-option label="已拒绝" :value="3" />
      </el-select>

      <el-date-picker
        v-model="dateRange"
        type="daterange"
        range-separator="至"
        start-placeholder="注册开始"
        end-placeholder="注册结束"
        value-format="YYYY-MM-DD"
        style="width: 280px"
        @change="handleSearch"
      />

      <el-button type="primary" @click="handleSearch">查询</el-button>
      <el-button @click="resetFilters">重置</el-button>
    </div>

    <div class="table-card">
      <el-table v-loading="loading" :data="tableData" stripe>
        <el-table-column label="用户" width="200" fixed>
          <template #default="{ row }">
            <div class="user-cell" @click="goDetail(row.uuid)">
              <el-avatar :size="32" :src="row.avatar_url">
                {{ (row.nickname || '?')[0] }}
              </el-avatar>
              <div class="user-info">
                <span class="user-nickname">{{ row.nickname || '-' }}</span>
                <span class="user-uuid">{{ row.uuid?.slice(0, 10) }}...</span>
              </div>
            </div>
          </template>
        </el-table-column>

        <el-table-column label="角色" width="100" align="center">
          <template #default="{ row }">
            <el-tag size="small" :type="row.role === 9 ? 'danger' : undefined">
              {{ USER_ROLES[row.role] || '未知' }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column label="手机号" width="130">
          <template #default="{ row }">
            {{ maskPhone(row.phone) }}
          </template>
        </el-table-column>

        <el-table-column label="入驻状态" width="100" align="center">
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

        <el-table-column label="信用分" width="80" align="center">
          <template #default="{ row }">
            <span class="credit-score">{{ row.credit_score ?? '-' }}</span>
          </template>
        </el-table-column>

        <el-table-column label="等级" width="60" align="center">
          <template #default="{ row }">
            {{ row.level ?? '-' }}
          </template>
        </el-table-column>

        <el-table-column label="完成订单" width="90" align="center">
          <template #default="{ row }">
            {{ row.completed_orders ?? 0 }}
          </template>
        </el-table-column>

        <el-table-column label="注册时间" width="160">
          <template #default="{ row }">
            {{ formatDate(row.created_at) }}
          </template>
        </el-table-column>

        <el-table-column label="最近登录" width="160">
          <template #default="{ row }">
            {{ formatDate(row.last_login_at) }}
          </template>
        </el-table-column>

        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag
              :type="USER_STATUS[row.status]?.type ?? 'info'"
              size="small"
              round
            >
              {{ USER_STATUS[row.status]?.label || '未知' }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column label="操作" width="160" fixed="right" align="center">
          <template #default="{ row }">
            <el-button link size="small" @click="goDetail(row.uuid)">
              详情
            </el-button>
            <el-button
              v-if="row.status === 1 && row.role !== 9"
              link
              size="small"
              type="danger"
              @click="handleFreeze(row)"
            >
              冻结
            </el-button>
            <el-button
              v-if="row.status === 0"
              link
              size="small"
              type="success"
              @click="handleUnfreeze(row)"
            >
              解冻
            </el-button>
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

    <!-- Freeze Dialog -->
    <el-dialog
      v-model="showFreezeDialog"
      title="冻结用户"
      width="480px"
      destroy-on-close
    >
      <p class="freeze-warning">
        确认冻结用户 <strong>{{ freezeTarget?.nickname }}</strong>？冻结后该用户将无法登录平台。
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
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search } from '@element-plus/icons-vue'
import { useTable } from '@/composables/useTable'
import { getUsers, updateUserStatus } from '@/api/users'
import { formatDate, maskPhone } from '@/utils/format'
import { USER_ROLES, USER_STATUS, ONBOARDING_STATUS } from '@/utils/constants'
import type { User } from '@/types/user'

const router = useRouter()

const filters = reactive({
  keyword: '',
  role: undefined as number | undefined,
  status: undefined as number | undefined,
  onboarding_status: undefined as number | undefined,
})
const dateRange = ref<string[]>([])

const { loading, tableData, pagination, loadData, handlePageChange, handleSizeChange } =
  useTable<User>(getUsers)

function buildParams() {
  const params: Record<string, any> = {}
  if (filters.keyword) params.keyword = filters.keyword
  if (filters.role !== undefined) params.role = filters.role
  if (filters.status !== undefined) params.status = filters.status
  if (filters.onboarding_status !== undefined) params.onboarding_status = filters.onboarding_status
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

function resetFilters() {
  filters.keyword = ''
  filters.role = undefined
  filters.status = undefined
  filters.onboarding_status = undefined
  dateRange.value = []
  handleSearch()
}

function goDetail(uuid: string) {
  router.push({ name: 'UserDetail', params: { uuid } })
}

// ---- Freeze ----
const showFreezeDialog = ref(false)
const freezeReason = ref('')
const submitting = ref(false)
const freezeTarget = ref<User | null>(null)

function handleFreeze(row: User) {
  freezeTarget.value = row
  freezeReason.value = ''
  showFreezeDialog.value = true
}

async function confirmFreeze() {
  if (!freezeTarget.value || !freezeReason.value.trim()) return
  submitting.value = true
  try {
    await updateUserStatus(freezeTarget.value.uuid, {
      status: 0,
      reason: freezeReason.value.trim(),
    })
    ElMessage.success('用户已冻结')
    showFreezeDialog.value = false
    loadData(buildParams())
  } catch {
    // handled by interceptor
  } finally {
    submitting.value = false
  }
}

async function handleUnfreeze(row: User) {
  try {
    await ElMessageBox.confirm(
      `确认解冻用户 ${row.nickname}？`,
      '解冻确认',
      { confirmButtonText: '确认解冻', cancelButtonText: '取消', type: 'warning' },
    )
    await updateUserStatus(row.uuid, { status: 1 })
    ElMessage.success('用户已解冻')
    loadData(buildParams())
  } catch {
    // cancelled
  }
}

onMounted(() => {
  loadData(buildParams())
})
</script>

<style scoped>
.user-cell {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
}

.user-cell:hover .user-nickname {
  color: #111;
}

.user-info {
  display: flex;
  flex-direction: column;
}

.user-nickname {
  font-size: 13px;
  font-weight: 600;
  color: #1a1c1c;
  transition: color 0.15s;
}

.user-uuid {
  font-size: 11px;
  color: #bbb;
  font-family: 'SF Mono', monospace;
}

.credit-score {
  font-weight: 600;
  font-family: 'SF Mono', monospace;
}

.freeze-warning {
  font-size: 14px;
  color: #666;
  margin-bottom: 16px;
  line-height: 1.6;
}
</style>
