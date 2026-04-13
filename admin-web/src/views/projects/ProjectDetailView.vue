<template>
  <div>
    <div class="page-header">
      <div class="header-back">
        <el-button text @click="router.back()">
          <el-icon><ArrowLeft /></el-icon>
          返回
        </el-button>
        <div class="title-block">
          <h2 class="page-title">{{ project?.title || '项目详情' }}</h2>
          <el-tag v-if="project" :type="statusTagType(project.status)" size="small">
            {{ PROJECT_STATUS[project.status]?.label || '未知' }}
          </el-tag>
        </div>
      </div>
      <div class="header-actions">
        <el-button type="primary" :loading="reviewLoading" @click="handleApprove">
          审核通过
        </el-button>
        <el-button :loading="reviewLoading" @click="handleReject">下架</el-button>
        <el-button @click="openProjectEditDialog">编辑项目</el-button>
        <el-button type="danger" plain :loading="reviewLoading" @click="openCloseDialog">
          关闭项目
        </el-button>
      </div>
    </div>

    <div v-loading="loadingProject" class="detail-body">
      <el-tabs v-model="activeTab" class="detail-tabs" @tab-change="onTabChange">
        <el-tab-pane label="基本信息" name="basic">
          <div class="info-grid">
            <div class="info-item span-2">
              <span class="info-label">标题</span>
              <span class="info-value">{{ project?.title || '-' }}</span>
            </div>
            <div class="info-item span-2">
              <span class="info-label">描述</span>
              <span class="info-value desc-block">{{ project?.description || '-' }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">预算</span>
              <span class="info-value">{{ formatBudgetRange(project) }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">成交价</span>
              <span class="info-value mono">{{ formatMoney(project?.agreed_price) }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">分类</span>
              <span class="info-value">{{ project?.category || '-' }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">发布时间</span>
              <span class="info-value">{{ formatDate(project?.published_at) }}</span>
            </div>
          </div>
        </el-tab-pane>

        <el-tab-pane label="PRD 文档" name="prd">
          <div v-loading="loadingPrd" class="prd-panel">
            <div class="prd-toolbar">
              <el-upload
                :show-file-list="false"
                :http-request="handlePrdUpload"
                :disabled="prdUploading"
              >
                <el-button type="primary" size="small" :loading="prdUploading">覆盖 PRD</el-button>
              </el-upload>
              <el-button type="primary" size="small" @click="downloadPrdText">下载 PRD</el-button>
              <el-button
                size="small"
                :loading="prdReanalyzing"
                :disabled="!prdText || prdUploading || !project || project.status < 3"
                :title="project && project.status < 3 ? '仅已撮合(status≥3)的项目可触发拆解' : ''"
                @click="handleReanalyze"
              >
                EARS 拆解
              </el-button>
              <el-button size="small" :disabled="!project || project.status < 3" @click="downloadEarsDoc">
                下载 EARS 文档
              </el-button>
            </div>
            <pre v-if="prdText" class="prd-text">{{ prdText }}</pre>
            <el-empty v-else-if="!loadingPrd" description="暂无 PRD 内容" :image-size="80" />
          </div>
          <div v-if="aiDocs.length" class="ai-docs-section">
            <h3 class="sub-title">AI 生成文档</h3>
            <el-table :data="aiDocs" stripe size="small">
              <el-table-column prop="filename" label="文件名" min-width="200" />
              <el-table-column prop="stage" label="阶段" width="120" />
              <el-table-column label="版本" width="80" align="center">
                <template #default="{ row }">v{{ row.version }}</template>
              </el-table-column>
              <el-table-column label="大小" width="100">
                <template #default="{ row }">{{ formatFileSize(row.size_bytes) }}</template>
              </el-table-column>
              <el-table-column label="生成时间" width="170">
                <template #default="{ row }">{{ formatDate(row.created_at) }}</template>
              </el-table-column>
              <el-table-column label="操作" width="100" align="center">
                <template #default="{ row }">
                  <el-button type="primary" link :loading="row._downloading" @click="downloadAIDoc(row)">
                    下载
                  </el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
          <div class="ears-tasks-section">
            <div class="ears-tasks-header">
              <h3 class="sub-title">EARS 任务</h3>
              <el-button size="small" text :loading="loadingEarsTasks" :disabled="earsPolling" @click="fetchEarsTasks">
                刷新
              </el-button>
            </div>
            <div v-if="earsPolling" class="ears-polling-bar">
              <el-progress
                :percentage="earsPollingProgress"
                :stroke-width="18"
                :text-inside="true"
                striped
                striped-flow
              />
              <p class="ears-polling-msg">{{ earsPollingMsg }}</p>
            </div>
            <el-table v-if="earsTasks.length" v-loading="loadingEarsTasks" :data="earsTasks" stripe size="small" :default-sort="{ prop: 'feature_item_id', order: 'ascending' }">
              <el-table-column prop="feature_item_id" label="关联需求" width="120" sortable>
                <template #default="{ row }">
                  <span v-if="row.feature_item_id" class="feature-item-tag">{{ row.feature_item_id }}</span>
                  <span v-else style="color: #ccc">—</span>
                </template>
              </el-table-column>
              <el-table-column prop="task_code" label="编号" width="100" />
              <el-table-column prop="title" label="EARS 描述" min-width="200" show-overflow-tooltip />
              <el-table-column prop="ears_type" label="EARS 类型" width="120">
                <template #default="{ row }">
                  {{ earsTypeLabel(row.ears_type) }}
                </template>
              </el-table-column>
              <el-table-column prop="module" label="模块" width="120" show-overflow-tooltip />
              <el-table-column prop="priority" label="优先级" width="80" align="center" />
              <el-table-column label="预估工时" width="100" align="right">
                <template #default="{ row }">
                  {{ row.estimated_hours != null ? `${row.estimated_hours}h` : '-' }}
                </template>
              </el-table-column>
              <el-table-column label="状态" width="100">
                <template #default="{ row }">
                  {{ earsStatusLabel(row.status) }}
                </template>
              </el-table-column>
            </el-table>
            <el-empty v-else-if="!loadingEarsTasks && !earsPolling" description="暂无 EARS 任务，请先执行拆解" :image-size="64" />
          </div>
        </el-tab-pane>

        <el-tab-pane label="项目文档" name="files">
          <div v-loading="loadingFiles" class="files-panel">
            <div class="files-toolbar">
              <el-upload
                :show-file-list="false"
                :http-request="handleFileUpload"
                :disabled="uploading"
              >
                <el-button type="primary" :loading="uploading">上传文档</el-button>
              </el-upload>
            </div>
            <el-table v-if="files.length" :data="files" stripe>
              <el-table-column prop="file_name" label="文件名" min-width="200" show-overflow-tooltip />
              <el-table-column label="大小" width="100">
                <template #default="{ row }">
                  {{ formatFileSize(row.file_size) }}
                </template>
              </el-table-column>
              <el-table-column prop="file_type" label="类型" width="100" />
              <el-table-column prop="uploaded_by" label="上传者" width="140" show-overflow-tooltip />
              <el-table-column label="上传时间" width="170">
                <template #default="{ row }">
                  {{ formatDate(row.created_at) }}
                </template>
              </el-table-column>
              <el-table-column label="操作" width="100" align="center">
                <template #default="{ row }">
                  <el-link :href="row.download_url" type="primary" target="_blank" :underline="false">
                    下载
                  </el-link>
                </template>
              </el-table-column>
            </el-table>
            <el-empty v-else description="暂无项目文档" :image-size="80" />
          </div>
        </el-tab-pane>

        <el-tab-pane label="投标记录" name="bids">
          <div v-loading="loadingBids">
            <el-table v-if="bids.length" :data="bids" stripe>
              <el-table-column label="投标方" min-width="160" show-overflow-tooltip>
                <template #default="{ row }">
                  {{
                    row.bidder_nickname ||
                    row.provider_nickname ||
                    row.team_name ||
                    row.team_id ||
                    '-'
                  }}
                </template>
              </el-table-column>
              <el-table-column label="报价" width="120" align="right">
                <template #default="{ row }">
                  {{ formatMoney(row.quoted_price ?? row.amount ?? row.bid_amount) }}
                </template>
              </el-table-column>
              <el-table-column label="状态" width="100" align="center">
                <template #default="{ row }">
                  {{ row.status_label ?? row.status ?? '-' }}
                </template>
              </el-table-column>
              <el-table-column prop="remark" label="备注" min-width="160" show-overflow-tooltip />
              <el-table-column label="时间" width="170">
                <template #default="{ row }">
                  {{ formatDate(row.created_at) }}
                </template>
              </el-table-column>
            </el-table>
            <el-empty v-else description="暂无投标记录" :image-size="80" />
          </div>
        </el-tab-pane>

        <el-tab-pane label="里程碑 & 任务" name="milestones">
          <div v-loading="loadingMilestones" class="split-panels">
            <div class="sub-section">
              <h3 class="sub-title">里程碑</h3>
              <el-table v-if="milestones.length" :data="milestones" stripe size="small">
                <el-table-column label="名称" min-width="160" show-overflow-tooltip>
                  <template #default="{ row }">
                    {{ row.title ?? row.name ?? '-' }}
                  </template>
                </el-table-column>
                <el-table-column label="金额" width="120" align="right">
                  <template #default="{ row }">
                    {{ formatMoney(row.amount) }}
                  </template>
                </el-table-column>
                <el-table-column label="状态" width="100">
                  <template #default="{ row }">
                    {{ row.status_label ?? row.status ?? '-' }}
                  </template>
                </el-table-column>
                <el-table-column label="计划日期" width="140">
                  <template #default="{ row }">
                    {{ formatDate(row.due_at ?? row.due_date, 'YYYY-MM-DD') }}
                  </template>
                </el-table-column>
              </el-table>
              <el-empty v-else description="暂无里程碑" :image-size="64" />
            </div>
            <div class="sub-section">
              <h3 class="sub-title">任务</h3>
              <el-table v-if="tasks.length" :data="tasks" stripe size="small">
                <el-table-column label="任务" min-width="180" show-overflow-tooltip>
                  <template #default="{ row }">
                    {{ row.title ?? row.name ?? '-' }}
                  </template>
                </el-table-column>
                <el-table-column label="状态" width="100">
                  <template #default="{ row }">
                    {{ row.status_label ?? row.status ?? '-' }}
                  </template>
                </el-table-column>
                <el-table-column label="里程碑" width="140" show-overflow-tooltip>
                  <template #default="{ row }">
                    {{ row.milestone_title ?? row.milestone_id ?? '-' }}
                  </template>
                </el-table-column>
                <el-table-column label="更新时间" width="170">
                  <template #default="{ row }">
                    {{ formatDate(row.updated_at ?? row.created_at) }}
                  </template>
                </el-table-column>
              </el-table>
              <el-empty v-else description="暂无任务" :image-size="64" />
            </div>
          </div>
        </el-tab-pane>

        <el-tab-pane label="评价" name="reviews">
          <div v-loading="loadingReviews">
            <div v-if="reviews.length" class="review-list">
              <div v-for="(item, idx) in reviews" :key="item.uuid ?? idx" class="review-card stat-card">
                <div class="review-head">
                  <span class="reviewer">{{
                    item.reviewer_nickname ?? item.user_nickname ?? item.nickname ?? '-'
                  }}</span>
                  <span v-if="item.rating != null" class="rating">评分 {{ item.rating }}</span>
                  <span class="review-time">{{ formatDate(item.created_at) }}</span>
                </div>
                <p class="review-content">{{ item.content ?? item.comment ?? '-' }}</p>
              </div>
            </div>
            <el-empty v-else description="暂无评价" :image-size="80" />
          </div>
        </el-tab-pane>
      </el-tabs>
    </div>

    <el-dialog v-model="projectEditVisible" title="编辑项目" width="520px" destroy-on-close>
      <el-form label-position="top">
        <el-form-item label="预算范围">
          <div style="display: flex; gap: 12px; align-items: center">
            <el-input-number v-model="projectEditForm.budget_min" :min="0" :precision="0" placeholder="最低" />
            <span>~</span>
            <el-input-number v-model="projectEditForm.budget_max" :min="0" :precision="0" placeholder="最高" />
          </div>
        </el-form-item>
        <el-form-item label="截止日期">
          <el-date-picker
            v-model="projectEditForm.deadline"
            type="date"
            placeholder="选择日期"
            format="YYYY-MM-DD"
            value-format="YYYY-MM-DD"
            style="width: 100%"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="projectEditVisible = false">取消</el-button>
        <el-button type="primary" :loading="projectEditSaving" @click="submitProjectEdit">保存</el-button>
      </template>
    </el-dialog>

    <el-dialog
      v-model="closeDialogVisible"
      title="关闭项目"
      width="480px"
      destroy-on-close
      @closed="closeReason = ''"
    >
      <el-form label-position="top">
        <el-form-item label="关闭原因" required>
          <el-input
            v-model="closeReason"
            type="textarea"
            :rows="4"
            placeholder="请填写关闭原因"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="closeDialogVisible = false">取消</el-button>
        <el-button
          type="danger"
          :loading="reviewLoading"
          :disabled="!closeReason.trim()"
          @click="confirmClose"
        >
          确认关闭
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ArrowLeft } from '@element-plus/icons-vue'
import type { UploadRequestOptions } from 'element-plus'
import { formatDate, formatMoney } from '@/utils/format'
import { PROJECT_STATUS } from '@/utils/constants'
import {
  getProjectDetail,
  getProjectFiles,
  uploadProjectFile,
  uploadProjectPrdDocument,
  reanalyzePRD,
  decomposePRD,
  getEarsTasks,
  getProjectBids,
  getProjectMilestones,
  getProjectTasks,
  getProjectReviews,
  getProjectPRD,
  getAIDocuments,
  reviewProject,
  updateProject,
} from '@/api/projects'
import type { Project, ProjectFile } from '@/types/project'

type ProjectDetail = Project & { description?: string | null }

const route = useRoute()
const router = useRouter()
const uuid = route.params.uuid as string

const loadingProject = ref(true)
const project = ref<ProjectDetail | null>(null)
const activeTab = ref('basic')

const reviewLoading = ref(false)
const closeDialogVisible = ref(false)
const closeReason = ref('')

const prdText = ref('')
const aiDocs = ref<Record<string, any>[]>([])
const loadingPrd = ref(false)
const tabPrdLoaded = ref(false)
const prdUploading = ref(false)
const prdReanalyzing = ref(false)
const earsTasks = ref<Record<string, any>[]>([])
const loadingEarsTasks = ref(false)
const earsPolling = ref(false)
const earsPollingProgress = ref(0)
const earsPollingMsg = ref('')
let earsPollingTimer: ReturnType<typeof setInterval> | null = null

const files = ref<ProjectFile[]>([])
const loadingFiles = ref(false)
const tabFilesLoaded = ref(false)
const uploading = ref(false)

const bids = ref<Record<string, any>[]>([])
const loadingBids = ref(false)
const tabBidsLoaded = ref(false)

const milestones = ref<Record<string, any>[]>([])
const tasks = ref<Record<string, any>[]>([])
const loadingMilestones = ref(false)
const tabMilestonesLoaded = ref(false)

const reviews = ref<Record<string, any>[]>([])
const loadingReviews = ref(false)
const tabReviewsLoaded = ref(false)

type ElTagType = 'info' | 'primary' | 'success' | 'warning' | 'danger'

function statusTagType(status: number): ElTagType | undefined {
  const t = PROJECT_STATUS[status]?.type
  if (t === 'info' || t === 'primary' || t === 'success' || t === 'warning' || t === 'danger') {
    return t
  }
  return undefined
}

function formatBudgetRange(p: ProjectDetail | null) {
  if (!p) return '-'
  const min = p.budget_min
  const max = p.budget_max
  if (min == null && max == null) return '-'
  if (min != null && max != null) return `${formatMoney(min)} ~ ${formatMoney(max)}`
  if (min != null) return `${formatMoney(min)} ~`
  return `~ ${formatMoney(max)}`
}

const EARS_TYPE_MAP: Record<string, string> = {
  ubiquitous: '普适性需求',
  event: '事件驱动',
  state: '状态驱动',
  optional: '可选功能',
  unwanted: '异常处理',
}

const EARS_STATUS_MAP: Record<string | number, string> = {
  1: '待开始',
  2: '进行中',
  3: '已完成',
  todo: '待开始',
  in_progress: '进行中',
  completed: '已完成',
}

function earsTypeLabel(type: string) {
  return EARS_TYPE_MAP[type] || type || '-'
}

function earsStatusLabel(status: string | number) {
  return EARS_STATUS_MAP[status] || String(status || '-')
}

function formatFileSize(bytes: number) {
  if (bytes == null || Number.isNaN(bytes)) return '-'
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}


async function loadProject() {
  loadingProject.value = true
  try {
    const res: { data?: ProjectDetail } = await getProjectDetail(uuid)
    project.value = res.data ?? null
  } catch {
    project.value = null
  } finally {
    loadingProject.value = false
  }
}

function normalizePrdPayload(payload: unknown): string {
  if (payload == null) return ''
  if (typeof payload === 'string') return payload
  if (typeof payload === 'object') {
    const o = payload as Record<string, unknown>
    if (typeof o.content === 'string') return o.content
    if (typeof o.body === 'string') return o.body
    if (typeof o.markdown === 'string') return o.markdown
    if (typeof o.text === 'string') return o.text
    if (typeof o.data === 'string') return o.data
  }
  try {
    return JSON.stringify(payload, null, 2)
  } catch {
    return String(payload)
  }
}

async function loadPrd() {
  if (tabPrdLoaded.value) return
  await Promise.all([refreshPrdAndDocs(), fetchEarsTasks()])
  tabPrdLoaded.value = true
}

function normalizeAIDocPayload(payload: unknown): Record<string, any>[] {
  if (Array.isArray(payload)) return payload as Record<string, any>[]
  if (payload && typeof payload === 'object') {
    const obj = payload as Record<string, unknown>
    if (Array.isArray(obj.documents)) return obj.documents as Record<string, any>[]
    if (Array.isArray(obj.list)) return obj.list as Record<string, any>[]
  }
  return []
}

async function refreshPrdAndDocs() {
  loadingPrd.value = true
  try {
    const [prdRes, docsRes] = await Promise.allSettled([
      getProjectPRD(uuid),
      getAIDocuments(uuid),
    ])
    if (prdRes.status === 'fulfilled') {
      prdText.value = normalizePrdPayload((prdRes.value as any)?.data)
    }
    if (docsRes.status === 'fulfilled') {
      const docs = normalizeAIDocPayload((docsRes.value as any)?.data)
      aiDocs.value = docs.map((d: any) => ({ ...d, _downloading: false }))
    }
  } finally {
    loadingPrd.value = false
  }
}

function downloadPrdText() {
  if (!prdText.value) return
  const title = project.value?.title || '项目'
  const blob = new Blob([prdText.value], { type: 'text/plain;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `${title}-PRD.txt`
  a.click()
  URL.revokeObjectURL(url)
}

async function downloadAIDoc(row: Record<string, any>) {
  row._downloading = true
  try {
    const token = localStorage.getItem('admin_token')
    const baseURL = import.meta.env.VITE_API_BASE_URL || ''
    const url = `${baseURL}/admin/projects/${uuid}/ai-documents/${row.id}/download`
    const resp = await fetch(url, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    })
    if (!resp.ok) {
      ElMessage.error('下载失败')
      return
    }
    const blob = await resp.blob()
    const blobUrl = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = blobUrl
    a.download = row.filename || 'document.md'
    a.click()
    URL.revokeObjectURL(blobUrl)
  } catch {
    ElMessage.error('下载失败')
  } finally {
    row._downloading = false
  }
}

function stopEarsPolling() {
  if (earsPollingTimer) {
    clearInterval(earsPollingTimer)
    earsPollingTimer = null
  }
  earsPolling.value = false
  earsPollingProgress.value = 0
  earsPollingMsg.value = ''
}

function startEarsPolling() {
  // 只启动轮询阶段（不重置进度条状态，由 runReanalyzeAndDecompose 统一管理）
  if (earsPollingTimer) {
    clearInterval(earsPollingTimer)
    earsPollingTimer = null
  }

  earsPollingMsg.value = 'AI 正在拆解需求，通常需要 30~90 秒...'

  const startTime = Date.now()
  const maxDuration = 150_000 // 2.5 min timeout
  const pollInterval = 4_000 // 4s

  earsPollingTimer = setInterval(async () => {
    const elapsed = Date.now() - startTime
    // 轮询阶段进度：从 40% 到 95%
    earsPollingProgress.value = Math.min(95, Math.round(40 + 55 * (1 - Math.exp(-elapsed / 60_000))))

    if (elapsed > 30_000) {
      earsPollingMsg.value = '拆解进行中，请耐心等待...'
    }
    if (elapsed > 70_000) {
      earsPollingMsg.value = '即将完成...'
    }

    try {
      const res = await getEarsTasks(uuid)
      const tasks = normalizeEarsTasksPayload((res as any)?.data)
      if (tasks.length > 0) {
        earsTasks.value = tasks
        earsPollingProgress.value = 100
        earsPollingMsg.value = `拆解完成，共 ${tasks.length} 个任务`
        await refreshPrdAndDocs()
        setTimeout(() => stopEarsPolling(), 1500)
        return
      }
    } catch {
      // ignore, keep polling
    }

    if (elapsed >= maxDuration) {
      earsPollingMsg.value = '拆解超时，请稍后手动刷新'
      setTimeout(() => stopEarsPolling(), 2000)
    }
  }, pollInterval)
}

async function runReanalyzeAndDecompose() {
  prdReanalyzing.value = true
  // 立即显示进度条
  earsPolling.value = true
  earsPollingProgress.value = 5
  earsPollingMsg.value = '正在提取 PRD 结构化数据...'

  try {
    // 阶段 1：reanalyze（非关键，失败可跳过）
    try {
      await reanalyzePRD(uuid)
      earsPollingProgress.value = 20
      earsPollingMsg.value = '结构化提取完成，正在启动 EARS 拆解...'
    } catch {
      earsPollingProgress.value = 15
      earsPollingMsg.value = '结构化提取跳过，直接启动 EARS 拆解...'
    }

    // 阶段 2：decompose
    await decomposePRD(uuid)
    earsPollingProgress.value = 35
    earsPollingMsg.value = 'EARS 拆解已启动，等待 AI 处理...'
    prdReanalyzing.value = false

    // 阶段 3：轮询等待结果
    startEarsPolling()
  } catch {
    ElMessage.warning('EARS 拆解失败，可稍后手动重试')
    prdReanalyzing.value = false
    stopEarsPolling()
  }
}

async function handlePrdUpload(options: UploadRequestOptions) {
  prdUploading.value = true
  try {
    const formData = new FormData()
    formData.append('file', options.file)
    await uploadProjectPrdDocument(uuid, formData)
    ElMessage.success('PRD 上传成功，正在分析...')
    options.onSuccess?.({})
    await refreshPrdAndDocs()
    tabPrdLoaded.value = true
    await runReanalyzeAndDecompose()
  } catch {
    ElMessage.error('PRD 上传失败')
    options.onError?.(new Error('upload failed') as any)
  } finally {
    prdUploading.value = false
  }
}

async function handleReanalyze() {
  await runReanalyzeAndDecompose()
}

function normalizeEarsTasksPayload(payload: unknown): Record<string, any>[] {
  if (Array.isArray(payload)) return payload as Record<string, any>[]
  if (payload && typeof payload === 'object') {
    const obj = payload as Record<string, unknown>
    if (Array.isArray(obj.tasks)) return obj.tasks as Record<string, any>[]
    if (Array.isArray(obj.data)) return obj.data as Record<string, any>[]
    if (Array.isArray(obj.list)) return obj.list as Record<string, any>[]
  }
  return []
}

async function fetchEarsTasks() {
  loadingEarsTasks.value = true
  try {
    const res = await getEarsTasks(uuid)
    earsTasks.value = normalizeEarsTasksPayload((res as any)?.data)
  } catch {
    earsTasks.value = []
  } finally {
    loadingEarsTasks.value = false
  }
}

function downloadEarsDoc() {
  const doc = aiDocs.value.find((d) => d.filename === 'ears-tasks.md')
  if (doc) {
    downloadAIDoc(doc)
  } else {
    ElMessage.warning('未找到 EARS 文档，请先执行 EARS 拆解')
  }
}

async function loadFiles() {
  if (tabFilesLoaded.value) return
  loadingFiles.value = true
  try {
    const res: { data?: ProjectFile[] } = await getProjectFiles(uuid)
    files.value = res.data ?? []
    tabFilesLoaded.value = true
  } catch {
    files.value = []
  } finally {
    loadingFiles.value = false
  }
}

async function refreshFiles() {
  loadingFiles.value = true
  try {
    const res: { data?: ProjectFile[] } = await getProjectFiles(uuid)
    files.value = res.data ?? []
    tabFilesLoaded.value = true
  } catch {
    /* handled */
  } finally {
    loadingFiles.value = false
  }
}

async function handleFileUpload(options: UploadRequestOptions) {
  uploading.value = true
  try {
    const formData = new FormData()
    formData.append('file', options.file)
    await uploadProjectFile(uuid, formData)
    ElMessage.success('上传成功')
    options.onSuccess?.({})
    await refreshFiles()
  } catch {
    options.onError?.(new Error('upload failed') as any)
  } finally {
    uploading.value = false
  }
}

async function loadBids() {
  if (tabBidsLoaded.value) return
  loadingBids.value = true
  try {
    const res: { data?: Record<string, any>[] } = await getProjectBids(uuid)
    bids.value = res.data ?? []
    tabBidsLoaded.value = true
  } catch {
    bids.value = []
  } finally {
    loadingBids.value = false
  }
}

async function loadMilestonesAndTasks() {
  if (tabMilestonesLoaded.value) return
  loadingMilestones.value = true
  try {
    const [ms, ts] = await Promise.all([
      getProjectMilestones(uuid),
      getProjectTasks(uuid),
    ])
    milestones.value = (ms as { data?: Record<string, any>[] }).data ?? []
    tasks.value = (ts as { data?: Record<string, any>[] }).data ?? []
    tabMilestonesLoaded.value = true
  } catch {
    milestones.value = []
    tasks.value = []
  } finally {
    loadingMilestones.value = false
  }
}

async function loadReviews() {
  if (tabReviewsLoaded.value) return
  loadingReviews.value = true
  try {
    const res: { data?: Record<string, any>[] } = await getProjectReviews(uuid)
    reviews.value = res.data ?? []
    tabReviewsLoaded.value = true
  } catch {
    reviews.value = []
  } finally {
    loadingReviews.value = false
  }
}

function onTabChange(name: string | number) {
  const tab = String(name)
  if (tab === 'prd') void loadPrd()
  if (tab === 'files') void loadFiles()
  if (tab === 'bids') void loadBids()
  if (tab === 'milestones') void loadMilestonesAndTasks()
  if (tab === 'reviews') void loadReviews()
}

async function handleApprove() {
  try {
    await ElMessageBox.confirm('确认审核通过该项目？', '审核通过', {
      confirmButtonText: '确认',
      cancelButtonText: '取消',
      type: 'warning',
    })
    reviewLoading.value = true
    await reviewProject(uuid, { action: 'approve' })
    ElMessage.success('操作成功')
    await loadProject()
  } catch {
    /* cancel */
  } finally {
    reviewLoading.value = false
  }
}

async function handleReject() {
  try {
    const { value } = await ElMessageBox.prompt('请输入下架原因', '下架项目', {
      confirmButtonText: '确认下架',
      cancelButtonText: '取消',
      inputType: 'textarea',
      inputPlaceholder: '原因将记录在审核日志中',
      inputValidator: (val) => {
        if (!val || !val.trim()) return '请填写原因'
        return true
      },
    })
    reviewLoading.value = true
    await reviewProject(uuid, { action: 'reject', reason: value.trim() })
    ElMessage.success('已下架')
    await loadProject()
  } catch {
    /* cancel */
  } finally {
    reviewLoading.value = false
  }
}

function openCloseDialog() {
  closeReason.value = ''
  closeDialogVisible.value = true
}

async function confirmClose() {
  if (!closeReason.value.trim()) return
  reviewLoading.value = true
  try {
    await reviewProject(uuid, { action: 'close', reason: closeReason.value.trim() })
    ElMessage.success('项目已关闭')
    closeDialogVisible.value = false
    await loadProject()
  } catch {
    /* handled */
  } finally {
    reviewLoading.value = false
  }
}

// ──── 编辑项目对话框 ────
const projectEditVisible = ref(false)
const projectEditSaving = ref(false)
const projectEditForm = ref({
  budget_min: undefined as number | undefined,
  budget_max: undefined as number | undefined,
  deadline: undefined as string | undefined,
})

function openProjectEditDialog() {
  projectEditForm.value = {
    budget_min: project.value?.budget_min ?? undefined,
    budget_max: project.value?.budget_max ?? undefined,
    deadline: (project.value as any)?.deadline ?? undefined,
  }
  projectEditVisible.value = true
}

async function submitProjectEdit() {
  const payload: Record<string, any> = {}
  const f = projectEditForm.value
  if (f.budget_min != null) payload.budget_min = f.budget_min
  if (f.budget_max != null) payload.budget_max = f.budget_max
  if (f.deadline) payload.deadline = f.deadline
  if (Object.keys(payload).length === 0) {
    ElMessage.warning('请至少修改一个字段')
    return
  }
  projectEditSaving.value = true
  try {
    await updateProject(uuid, payload)
    ElMessage.success('已更新')
    projectEditVisible.value = false
    await loadProject()
  } catch {
    ElMessage.error('更新失败')
  } finally {
    projectEditSaving.value = false
  }
}

onMounted(() => {
  void loadProject()
})

onBeforeUnmount(() => {
  stopEarsPolling()
})
</script>

<style scoped>
.header-back {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.title-block {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.title-block .page-title {
  margin: 0;
}

.header-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.detail-body {
  min-height: 360px;
}

.detail-tabs {
  background: #fff;
  border-radius: 10px;
  padding: 0 24px 24px;
  color: #1a1c1c;
}

.detail-tabs :deep(.el-tabs__header) {
  margin-bottom: 20px;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 20px;
}

.info-item.span-2 {
  grid-column: 1 / -1;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 6px;
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

.desc-block {
  white-space: pre-wrap;
  line-height: 1.6;
}

.prd-panel {
  min-height: 200px;
}

.prd-toolbar {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  margin-bottom: 12px;
}

.ai-docs-section {
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px solid #f0f0f0;
}

.ears-tasks-section {
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px solid #f0f0f0;
}

.ears-tasks-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.ears-polling-bar {
  margin-bottom: 16px;
}

.ears-polling-msg {
  margin: 8px 0 0;
  font-size: 12px;
  color: #999;
}

.feature-item-tag {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 4px;
  background: #f0f0f0;
  font-size: 12px;
  font-weight: 600;
  color: #333;
  font-family: 'SF Mono', monospace;
}

.prd-text {
  margin: 0;
  padding: 16px;
  background: #f9f9f9;
  border-radius: 10px;
  font-size: 13px;
  line-height: 1.6;
  color: #1a1c1c;
  white-space: pre-wrap;
  word-break: break-word;
  max-height: 560px;
  overflow: auto;
}

.files-toolbar {
  margin-bottom: 16px;
}

.split-panels {
  display: flex;
  flex-direction: column;
  gap: 28px;
}

.sub-title {
  font-size: 13px;
  font-weight: 700;
  color: #1a1c1c;
  margin: 0 0 12px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.review-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.review-card {
  margin: 0;
}

.review-head {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 12px;
  margin-bottom: 8px;
}

.reviewer {
  font-weight: 600;
  color: #1a1c1c;
}

.rating {
  font-size: 12px;
  color: #666;
}

.review-time {
  font-size: 12px;
  color: #999;
  margin-left: auto;
}

.review-content {
  margin: 0;
  font-size: 14px;
  color: #333;
  line-height: 1.6;
}
</style>
