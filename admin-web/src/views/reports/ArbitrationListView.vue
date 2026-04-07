<template>
  <div>
    <div class="page-header">
      <div>
        <h2 class="page-title">仲裁管理</h2>
        <p class="page-subtitle">争议仲裁与裁决记录</p>
      </div>
    </div>

    <div class="filter-bar">
      <el-select
        v-model="filters.status"
        placeholder="状态"
        clearable
        style="width: 140px"
        @change="handleSearch"
      >
        <el-option label="待处理" :value="1" />
        <el-option label="处理中" :value="2" />
        <el-option label="已裁决" :value="3" />
      </el-select>
      <el-button type="primary" @click="handleSearch">查询</el-button>
      <el-button @click="resetFilters">重置</el-button>
    </div>

    <div class="table-card">
      <el-table v-loading="loading" :data="tableData" stripe>
        <el-table-column prop="uuid" label="UUID" min-width="200" show-overflow-tooltip />
        <el-table-column prop="project_title" label="关联项目" min-width="180" show-overflow-tooltip />
        <el-table-column prop="applicant_nickname" label="申请人" width="120" show-overflow-tooltip />
        <el-table-column prop="respondent_nickname" label="被申请人" width="120" show-overflow-tooltip />
        <el-table-column prop="reason" label="原因" min-width="200" show-overflow-tooltip />
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="arbTagType(row.status)" size="small">
              {{ ARBITRATION_STATUS[row.status]?.label || '未知' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="verdict" label="裁决结果" min-width="160" show-overflow-tooltip>
          <template #default="{ row }">
            {{ row.verdict || '-' }}
          </template>
        </el-table-column>
        <el-table-column label="退款金额" width="120" align="right">
          <template #default="{ row }">
            {{ formatMoney(row.refund_amount) }}
          </template>
        </el-table-column>
        <el-table-column label="裁决时间" width="160">
          <template #default="{ row }">
            {{ formatDate(row.arbitrated_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100" fixed="right" align="center">
          <template #default="{ row }">
            <el-button
              v-if="row.status === 1 || row.status === 2"
              link
              type="primary"
              size="small"
              @click="openHandleDialog(row)"
            >
              处理
            </el-button>
            <span v-else class="text-muted">—</span>
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

    <el-dialog v-model="dialogVisible" title="仲裁处理" width="560px" destroy-on-close @closed="resetArbForm">
      <el-form label-position="top">
        <el-form-item label="裁决结果" required>
          <el-input v-model="arbForm.verdict" type="textarea" :rows="4" placeholder="请输入裁决说明" />
        </el-form-item>
        <el-form-item label="裁决类型" required>
          <el-select v-model="arbForm.verdict_type" placeholder="请选择" style="width: 100%">
            <el-option label="支持申请人" value="support_applicant" />
            <el-option label="支持被申请人" value="support_respondent" />
            <el-option label="部分退款" value="partial_refund" />
            <el-option label="调解" value="mediation" />
          </el-select>
        </el-form-item>
        <el-form-item label="退款金额">
          <el-input-number
            v-model="arbForm.refund_amount"
            :min="0"
            :precision="2"
            :controls="true"
            style="width: 100%"
            placeholder="可选"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="submitArbitration">提交</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { useTable } from '@/composables/useTable'
import { getArbitrations, handleArbitration } from '@/api/arbitrations'
import { formatDate, formatMoney } from '@/utils/format'
import { ARBITRATION_STATUS } from '@/utils/constants'
import type { Arbitration } from '@/types/arbitration'

const filters = reactive({
  status: undefined as number | undefined,
})

const { loading, tableData, pagination, loadData, handlePageChange, handleSizeChange } =
  useTable<Arbitration>(getArbitrations)

type ElTagType = 'info' | 'primary' | 'success' | 'warning' | 'danger'

function arbTagType(status: number): ElTagType | undefined {
  const t = ARBITRATION_STATUS[status]?.type
  if (t === 'info' || t === 'primary' || t === 'success' || t === 'warning' || t === 'danger') {
    return t
  }
  return undefined
}

function buildParams() {
  const params: Record<string, any> = {}
  if (filters.status !== undefined) params.status = filters.status
  return params
}

function handleSearch() {
  pagination.page = 1
  loadData(buildParams())
}

function resetFilters() {
  filters.status = undefined
  handleSearch()
}

const dialogVisible = ref(false)
const submitting = ref(false)
const currentArb = ref<Arbitration | null>(null)
const arbForm = reactive({
  verdict: '',
  verdict_type: '' as string,
  refund_amount: undefined as number | undefined,
})

function openHandleDialog(row: Arbitration) {
  currentArb.value = row
  arbForm.verdict = ''
  arbForm.verdict_type = ''
  arbForm.refund_amount = undefined
  dialogVisible.value = true
}

function resetArbForm() {
  currentArb.value = null
  arbForm.verdict = ''
  arbForm.verdict_type = ''
  arbForm.refund_amount = undefined
}

async function submitArbitration() {
  if (!currentArb.value) return
  const verdict = arbForm.verdict.trim()
  if (!verdict) {
    ElMessage.warning('请填写裁决结果')
    return
  }
  if (!arbForm.verdict_type) {
    ElMessage.warning('请选择裁决类型')
    return
  }
  if (arbForm.verdict_type === 'partial_refund' && (!arbForm.refund_amount || arbForm.refund_amount <= 0)) {
    ElMessage.warning('部分退款时请填写有效的退款金额')
    return
  }
  const payload: {
    verdict: string
    verdict_type: string
    refund_amount?: number
  } = {
    verdict,
    verdict_type: arbForm.verdict_type,
  }
  if (arbForm.refund_amount != null && !Number.isNaN(arbForm.refund_amount)) {
    payload.refund_amount = arbForm.refund_amount
  }
  submitting.value = true
  try {
    await handleArbitration(currentArb.value.uuid, payload)
    ElMessage.success('已提交')
    dialogVisible.value = false
    loadData(buildParams())
  } catch {
    /* interceptor */
  } finally {
    submitting.value = false
  }
}

onMounted(() => {
  loadData(buildParams())
})
</script>

<style scoped>
.text-muted {
  color: #bbb;
  font-size: 13px;
}
</style>
