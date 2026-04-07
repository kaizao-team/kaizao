<template>
  <div>
    <div class="page-header">
      <div>
        <h2 class="page-title">举报管理</h2>
        <p class="page-subtitle">用户举报受理与处理记录</p>
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
        <el-option label="已处理" :value="2" />
      </el-select>
      <el-button type="primary" @click="handleSearch">查询</el-button>
      <el-button @click="resetFilters">重置</el-button>
    </div>

    <div class="table-card">
      <el-table v-loading="loading" :data="tableData" stripe>
        <el-table-column prop="uuid" label="UUID" min-width="200" show-overflow-tooltip />
        <el-table-column prop="reporter_nickname" label="举报人" width="120" show-overflow-tooltip />
        <el-table-column prop="target_type" label="举报对象类型" width="130" show-overflow-tooltip />
        <el-table-column prop="target_id" label="举报对象 ID" min-width="160" show-overflow-tooltip />
        <el-table-column prop="reason_type" label="原因类型" width="120" show-overflow-tooltip />
        <el-table-column prop="reason_detail" label="详情" min-width="200" show-overflow-tooltip />
        <el-table-column label="证据" width="100" align="center">
          <template #default="{ row }">
            <el-button
              v-if="hasImageEvidence(row.evidence)"
              link
              type="primary"
              size="small"
              @click="openEvidence(row)"
            >
              查看
            </el-button>
            <span v-else class="text-muted">—</span>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="reportTagType(row.status)" size="small">
              {{ REPORT_STATUS[row.status]?.label || '未知' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="handler_id" label="处理人" width="120" show-overflow-tooltip>
          <template #default="{ row }">
            {{ row.handler_id || '-' }}
          </template>
        </el-table-column>
        <el-table-column label="创建时间" width="160">
          <template #default="{ row }">
            {{ formatDate(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100" fixed="right" align="center">
          <template #default="{ row }">
            <el-button
              v-if="row.status === 1"
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

    <el-dialog v-model="handleVisible" title="处理举报" width="520px" destroy-on-close @closed="resetHandleForm">
      <el-form label-position="top">
        <el-form-item label="处理结果" required>
          <el-input
            v-model="handleForm.handle_result"
            type="textarea"
            :rows="4"
            placeholder="请输入处理说明"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="handleVisible = false">取消</el-button>
        <el-button type="primary" :loading="handleSubmitting" @click="submitHandle">提交</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="evidenceVisible" title="证据图片" width="640px" destroy-on-close>
      <div class="evidence-grid">
        <el-image
          v-for="(url, i) in evidenceUrls"
          :key="i"
          :src="url"
          :preview-src-list="evidenceUrls"
          :initial-index="i"
          fit="cover"
          class="evidence-thumb"
        />
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { useTable } from '@/composables/useTable'
import { getReports, handleReport } from '@/api/reports'
import { formatDate } from '@/utils/format'
import { REPORT_STATUS } from '@/utils/constants'
import type { Report } from '@/types/report'

const filters = reactive({
  status: undefined as number | undefined,
})

const { loading, tableData, pagination, loadData, handlePageChange, handleSizeChange } =
  useTable<Report>(getReports)

type ElTagType = 'info' | 'primary' | 'success' | 'warning' | 'danger'

function reportTagType(status: number): ElTagType | undefined {
  const t = REPORT_STATUS[status]?.type
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

function collectImageUrls(evidence: any): string[] {
  const urls: string[] = []
  const pushUrl = (u: unknown) => {
    if (typeof u === 'string' && /^https?:\/\//i.test(u)) urls.push(u)
  }
  if (!evidence) return urls
  if (typeof evidence === 'string') {
    pushUrl(evidence)
    return urls
  }
  if (Array.isArray(evidence)) {
    for (const item of evidence) {
      if (typeof item === 'string') pushUrl(item)
      else if (item && typeof item === 'object' && 'url' in item) pushUrl((item as { url: string }).url)
    }
    return urls
  }
  if (typeof evidence === 'object') {
    const o = evidence as Record<string, unknown>
    if (Array.isArray(o.urls)) {
      for (const u of o.urls as unknown[]) pushUrl(u)
    }
    if (Array.isArray(o.images)) {
      for (const u of o.images as unknown[]) pushUrl(u)
    }
  }
  return [...new Set(urls)]
}

function hasImageEvidence(evidence: any) {
  return collectImageUrls(evidence).length > 0
}

const evidenceVisible = ref(false)
const evidenceUrls = ref<string[]>([])

function openEvidence(row: Report) {
  evidenceUrls.value = collectImageUrls(row.evidence)
  if (evidenceUrls.value.length) evidenceVisible.value = true
}

const handleVisible = ref(false)
const handleSubmitting = ref(false)
const currentReport = ref<Report | null>(null)
const handleForm = reactive({
  handle_result: '',
})

function openHandleDialog(row: Report) {
  currentReport.value = row
  handleForm.handle_result = ''
  handleVisible.value = true
}

function resetHandleForm() {
  currentReport.value = null
  handleForm.handle_result = ''
}

async function submitHandle() {
  if (!currentReport.value) return
  const text = handleForm.handle_result.trim()
  if (!text) {
    ElMessage.warning('请填写处理结果')
    return
  }
  handleSubmitting.value = true
  try {
    await handleReport(currentReport.value.uuid, { handle_result: text })
    ElMessage.success('已处理')
    handleVisible.value = false
    loadData(buildParams())
  } catch {
    /* handled by interceptor */
  } finally {
    handleSubmitting.value = false
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

.evidence-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}

.evidence-thumb {
  width: 160px;
  height: 120px;
  border-radius: 8px;
  overflow: hidden;
}
</style>
