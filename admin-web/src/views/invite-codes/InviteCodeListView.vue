<template>
  <div>
    <div class="page-header">
      <div>
        <h2 class="page-title">邀请码管理</h2>
        <p class="page-subtitle">管理团队入驻邀请码的创建与状态</p>
      </div>
      <el-button type="primary" @click="showCreateDialog = true">
        <el-icon><Plus /></el-icon>
        创建邀请码
      </el-button>
    </div>

    <div class="filter-bar">
      <el-input
        v-model="filters.team_uuid"
        placeholder="按团队 UUID 筛选"
        clearable
        style="width: 280px"
        @clear="handleSearch"
        @keyup.enter="handleSearch"
      >
        <template #prefix>
          <el-icon><Search /></el-icon>
        </template>
      </el-input>
      <el-select
        v-model="filters.status"
        placeholder="状态"
        clearable
        style="width: 140px"
        @change="handleSearch"
      >
        <el-option label="有效" value="active" />
        <el-option label="已用完" value="used_up" />
        <el-option label="已过期" value="expired" />
        <el-option label="已作废" value="disabled" />
      </el-select>
      <el-button @click="handleSearch">查询</el-button>
    </div>

    <div class="table-card">
      <el-table
        v-loading="loading"
        :data="filteredData"
        stripe
        :row-class-name="getRowClassName"
      >
        <el-table-column prop="uuid" label="UUID" width="140" show-overflow-tooltip>
          <template #default="{ row }">
            <span class="mono-text">{{ row.uuid?.slice(0, 12) }}...</span>
          </template>
        </el-table-column>

        <el-table-column label="邀请码" width="180">
          <template #default="{ row }">
            <div class="code-cell">
              <code class="invite-code">{{ row.code_plain }}</code>
              <el-icon class="copy-btn" @click="copyCode(row.code_plain)">
                <CopyDocument />
              </el-icon>
            </div>
          </template>
        </el-table-column>

        <el-table-column prop="team_id" label="关联团队" width="100" />

        <el-table-column prop="note" label="备注" min-width="140" show-overflow-tooltip>
          <template #default="{ row }">
            {{ row.note || '-' }}
          </template>
        </el-table-column>

        <el-table-column label="使用情况" width="120" align="center">
          <template #default="{ row }">
            <span class="usage-text">{{ row.used_count }} / {{ row.max_uses }}</span>
          </template>
        </el-table-column>

        <el-table-column label="允许角色" width="100">
          <template #default="{ row }">
            <template v-if="row.allowed_roles?.length">
              <el-tag
                v-for="r in row.allowed_roles"
                :key="r"
                size="small"
                class="role-tag"
              >
                {{ USER_ROLES[r] || r }}
              </el-tag>
            </template>
            <span v-else class="text-muted">全部</span>
          </template>
        </el-table-column>

        <el-table-column label="过期时间" width="160">
          <template #default="{ row }">
            {{ formatDate(row.expires_at) }}
          </template>
        </el-table-column>

        <el-table-column label="状态" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="getCodeStatusType(row)" size="small" round>
              {{ getCodeStatusLabel(row) }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column label="创建时间" width="160">
          <template #default="{ row }">
            {{ formatDate(row.created_at) }}
          </template>
        </el-table-column>

        <el-table-column label="操作" width="80" fixed="right" align="center">
          <template #default="{ row }">
            <el-button link size="small" @click="copyCode(row.code_plain)">
              复制
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-wrapper">
        <el-pagination
          v-model:current-page="pagination.page"
          v-model:page-size="pagination.page_size"
          :total="filters.status ? filteredData.length : pagination.total"
          :page-sizes="[20, 50, 100]"
          layout="total, sizes, prev, pager, next"
          @current-change="handlePageChange"
          @size-change="handleSizeChange"
        />
      </div>
    </div>

    <!-- Create Dialog -->
    <el-dialog
      v-model="showCreateDialog"
      title="创建邀请码"
      width="480px"
      destroy-on-close
    >
      <el-form
        ref="createFormRef"
        :model="createForm"
        :rules="createRules"
        label-width="90px"
        label-position="top"
      >
        <el-form-item label="团队 UUID" prop="team_uuid">
          <el-input
            v-model="createForm.team_uuid"
            placeholder="请输入要绑定的团队 UUID"
            clearable
          />
        </el-form-item>
        <el-form-item label="备注" prop="note">
          <el-input
            v-model="createForm.note"
            placeholder="可选备注信息"
            clearable
          />
        </el-form-item>
        <el-form-item label="过期时间" prop="expires_at">
          <el-date-picker
            v-model="createForm.expires_at"
            type="datetime"
            placeholder="可选，不填则永不过期"
            value-format="YYYY-MM-DDTHH:mm:ssZ"
            style="width: 100%"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showCreateDialog = false">取消</el-button>
        <el-button type="primary" :loading="creating" @click="handleCreate">
          创建
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import { Plus, Search, CopyDocument } from '@element-plus/icons-vue'
import { useTable } from '@/composables/useTable'
import { getInviteCodes, createInviteCode } from '@/api/invite-codes'
import { formatDate } from '@/utils/format'
import { USER_ROLES } from '@/utils/constants'
import type { InviteCode } from '@/types/invite-code'

const filters = reactive({
  team_uuid: '',
  status: '',
})

const { loading, tableData, pagination, loadData, handlePageChange, handleSizeChange } =
  useTable<InviteCode>(getInviteCodes)

const filteredData = computed(() => {
  if (!filters.status) return tableData.value
  const now = new Date()
  return tableData.value.filter((item) => {
    switch (filters.status) {
      case 'active':
        return !item.disabled_at && (!item.expires_at || new Date(item.expires_at) > now) && item.used_count < item.max_uses
      case 'used_up':
        return item.used_count >= item.max_uses
      case 'expired':
        return item.expires_at && new Date(item.expires_at) <= now && !item.disabled_at
      case 'disabled':
        return !!item.disabled_at
      default:
        return true
    }
  })
})

function handleSearch() {
  pagination.page = 1
  const params: Record<string, any> = {}
  if (filters.team_uuid) params.team_uuid = filters.team_uuid
  loadData(params)
}

function getRowClassName({ row }: { row: InviteCode }) {
  if (row.disabled_at) return 'row-disabled'
  if (row.expires_at && new Date(row.expires_at) <= new Date()) return 'row-expired'
  return ''
}

function getCodeStatusLabel(row: InviteCode): string {
  if (row.disabled_at) return '已作废'
  if (row.expires_at && new Date(row.expires_at) <= new Date()) return '已过期'
  if (row.used_count >= row.max_uses) return '已用完'
  return '有效'
}

function getCodeStatusType(row: InviteCode): 'success' | 'warning' | 'info' | 'danger' | 'primary' {
  if (row.disabled_at) return 'info'
  if (row.expires_at && new Date(row.expires_at) <= new Date()) return 'warning'
  if (row.used_count >= row.max_uses) return 'danger'
  return 'success'
}

async function copyCode(code: string) {
  try {
    await navigator.clipboard.writeText(code)
    ElMessage.success('邀请码已复制')
  } catch {
    ElMessage.error('复制失败')
  }
}

// ---- Create ----
const showCreateDialog = ref(false)
const creating = ref(false)
const createFormRef = ref<FormInstance>()
const createForm = reactive({
  team_uuid: '',
  note: '',
  expires_at: '',
})
const createRules: FormRules = {
  team_uuid: [{ required: true, message: '请输入团队 UUID', trigger: 'blur' }],
}

async function handleCreate() {
  if (!createFormRef.value) return
  await createFormRef.value.validate()
  creating.value = true
  try {
    await createInviteCode({
      team_uuid: createForm.team_uuid,
      note: createForm.note || undefined,
      expires_at: createForm.expires_at || undefined,
    })
    ElMessage.success('邀请码创建成功')
    showCreateDialog.value = false
    createForm.team_uuid = ''
    createForm.note = ''
    createForm.expires_at = ''
    handleSearch()
  } catch {
    // handled by interceptor
  } finally {
    creating.value = false
  }
}

onMounted(() => {
  loadData()
})
</script>

<style scoped>
.mono-text {
  font-family: 'SF Mono', 'Fira Code', 'Consolas', monospace;
  font-size: 12px;
  color: #666;
}

.code-cell {
  display: flex;
  align-items: center;
  gap: 6px;
}

.invite-code {
  font-family: 'SF Mono', 'Fira Code', 'Consolas', monospace;
  font-size: 13px;
  font-weight: 600;
  color: #1a1c1c;
  background: #f3f3f3;
  padding: 2px 8px;
  border-radius: 4px;
}

.copy-btn {
  cursor: pointer;
  color: #999;
  transition: color 0.2s;
}

.copy-btn:hover {
  color: #1a1c1c;
}

.usage-text {
  font-family: 'SF Mono', monospace;
  font-size: 13px;
  font-weight: 500;
}

.role-tag {
  margin-right: 4px;
}

.text-muted {
  color: #999;
  font-size: 12px;
}

:deep(.row-disabled) {
  color: #bbb;
  text-decoration: line-through;
}

:deep(.row-expired) {
  color: #bbb;
}
</style>
