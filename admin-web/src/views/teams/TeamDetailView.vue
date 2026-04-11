<template>
  <div>
    <div class="page-header">
      <div class="header-back">
        <el-button text @click="router.back()">
          <el-icon><ArrowLeft /></el-icon>
          返回
        </el-button>
      </div>
    </div>

    <div v-loading="loadingTeam" class="detail-content">
      <div class="profile-header">
        <el-avatar :size="64" :src="team?.avatar_url ?? undefined">
          {{ (team?.team_name || '?')[0] }}
        </el-avatar>
        <div class="profile-info">
          <div class="profile-name-row">
            <h3 class="profile-name">{{ team?.team_name || '-' }}</h3>
            <el-tag v-if="team?.vibe_level" size="small" :type="vibeLevelTagType(team.vibe_level)">
              {{ team.vibe_level }}
            </el-tag>
            <el-tag size="small" :type="teamStatusTagType(team?.status)">
              {{ teamStatusLabel(team?.status) }}
            </el-tag>
            <el-button size="small" @click="openEditDialog">编辑团队</el-button>
          </div>
          <div class="profile-meta">
            <span>UUID: <code>{{ team?.id }}</code></span>
            <span>创建时间: {{ formatDate(team?.created_at) }}</span>
          </div>
        </div>
      </div>

      <el-tabs v-model="activeTab" class="detail-tabs" @tab-change="onTabChange">
        <el-tab-pane label="基本信息" name="basic">
          <div class="info-grid">
            <div class="info-item">
              <span class="info-label">团队名称</span>
              <span class="info-value">{{ team?.team_name || '-' }}</span>
            </div>
            <div class="info-item span-2">
              <span class="info-label">描述</span>
              <span class="info-value">{{ team?.description || '-' }}</span>
            </div>
            <div class="info-item span-2">
              <span class="info-label">技能覆盖</span>
              <div v-if="skillList.length" class="skill-tags">
                <el-tag v-for="s in skillList" :key="s" class="skill-tag" size="small">
                  {{ s }}
                </el-tag>
              </div>
              <span v-else class="info-value muted">暂无</span>
            </div>
            <div class="info-item">
              <span class="info-label">时薪</span>
              <span class="info-value">{{ formatMoneyOrDash(team?.hourly_rate) }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">预算范围</span>
              <span class="info-value">
                {{ formatMoneyOrDash(team?.budget_min) }} — {{ formatMoneyOrDash(team?.budget_max) }}
              </span>
            </div>
            <div class="info-item">
              <span class="info-label">经验年限</span>
              <span class="info-value">{{ team?.experience_years ?? '-' }} 年</span>
            </div>
            <div class="info-item">
              <span class="info-label">可接单状态</span>
              <span class="info-value mono">{{ team?.available_status ?? '-' }}</span>
            </div>
            <div class="info-item span-2" v-if="team?.resume_summary">
              <span class="info-label">简历摘要</span>
              <span class="info-value">{{ team.resume_summary }}</span>
            </div>
          </div>
        </el-tab-pane>

        <el-tab-pane label="成员列表" name="members">
          <el-table :data="members" stripe empty-text="暂无成员">
            <el-table-column label="成员" min-width="200">
              <template #default="{ row }">
                <div class="member-cell">
                  <el-avatar :size="32" :src="row.avatar_url ?? undefined">
                    {{ (row.nickname || '?')[0] }}
                  </el-avatar>
                  <span>{{ row.nickname || '-' }}</span>
                </div>
              </template>
            </el-table-column>
            <el-table-column prop="role" label="角色" width="120" />
            <el-table-column label="分账比例" min-width="200">
              <template #default="{ row }">
                <el-progress :percentage="clampRatio(row.ratio)" :stroke-width="10" />
              </template>
            </el-table-column>
            <el-table-column label="队长" width="100" align="center">
              <template #default="{ row }">
                <el-tag v-if="row.is_leader" size="small" type="primary">队长</el-tag>
                <span v-else class="muted">—</span>
              </template>
            </el-table-column>
            <el-table-column prop="status" label="状态" width="120" />
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="评级详情" name="rating">
          <div class="info-grid">
            <div class="info-item">
              <span class="info-label">Vibe Power</span>
              <span class="info-value mono large">{{ team?.vibe_power ?? '-' }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">Vibe Level</span>
              <el-tag size="small" :type="team ? vibeLevelTagType(team.vibe_level) : 'info'">
                {{ team?.vibe_level || '-' }}
              </el-tag>
            </div>
            <div class="info-item">
              <span class="info-label">平均评分</span>
              <el-rate
                :model-value="Number(team?.avg_rating) || 0"
                disabled
                allow-half
                show-score
                text-color="#1a1c1c"
                score-template="{value}"
              />
            </div>
          </div>
        </el-tab-pane>

        <el-tab-pane label="邀请码" name="invite">
          <div v-loading="loadingInvite" class="invite-panel">
            <template v-if="inviteInfo?.has_active">
              <div class="info-item">
                <span class="info-label">当前有效码</span>
                <code class="code-plain">{{ inviteInfo.code_plain }}</code>
              </div>
              <div class="info-grid compact">
                <div class="info-item" v-if="inviteInfo.code_hint">
                  <span class="info-label">提示</span>
                  <span class="info-value">{{ inviteInfo.code_hint }}</span>
                </div>
                <div class="info-item">
                  <span class="info-label">过期时间</span>
                  <span class="info-value">{{ formatDate(inviteInfo.expires_at) }}</span>
                </div>
                <div class="info-item" v-if="inviteInfo.note">
                  <span class="info-label">备注</span>
                  <span class="info-value">{{ inviteInfo.note }}</span>
                </div>
              </div>
            </template>
            <el-empty v-else description="暂无有效邀请码" :image-size="72" />
            <el-button type="primary" class="gen-btn" :loading="creatingCode" @click="onCreateInviteCode">
              生成新码
            </el-button>
          </div>
        </el-tab-pane>

        <el-tab-pane label="静态资源" name="assets">
          <div v-loading="loadingAssets" class="table-card inner-table">
            <el-table :data="staticAssets" stripe empty-text="暂无文件">
              <el-table-column prop="original_name" label="文件名" min-width="200" show-overflow-tooltip />
              <el-table-column prop="content_type" label="类型" width="160" show-overflow-tooltip />
              <el-table-column label="大小" width="100">
                <template #default="{ row }">
                  {{ formatFileSize(row.size_bytes) }}
                </template>
              </el-table-column>
              <el-table-column label="上传时间" width="168">
                <template #default="{ row }">
                  {{ formatDate(row.created_at) }}
                </template>
              </el-table-column>
            </el-table>
            <div class="pagination-wrapper" v-if="assetsMeta.total > 0">
              <el-pagination
                v-model:current-page="assetsMeta.page"
                v-model:page-size="assetsMeta.page_size"
                :total="assetsMeta.total"
                :page-sizes="[20, 50, 100]"
                layout="total, sizes, prev, pager, next"
                @current-change="loadStaticAssets"
                @size-change="onAssetsSizeChange"
              />
            </div>
          </div>
        </el-tab-pane>
      </el-tabs>
    </div>

    <el-dialog v-model="editDialogVisible" title="编辑团队" width="520px" destroy-on-close>
      <el-form label-position="top">
        <el-form-item label="Vibe Level">
          <el-select v-model="editForm.vibe_level" clearable placeholder="选择等级">
            <el-option
              v-for="i in 10"
              :key="i"
              :label="`vc-T${i}`"
              :value="`vc-T${i}`"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="Vibe Power">
          <el-input-number v-model="editForm.vibe_power" :min="0" :max="750" />
        </el-form-item>
        <el-form-item label="预算范围">
          <div style="display: flex; gap: 12px; align-items: center">
            <el-input-number v-model="editForm.budget_min" :min="0" :precision="0" placeholder="最低" />
            <span>—</span>
            <el-input-number v-model="editForm.budget_max" :min="0" :precision="0" placeholder="最高" />
          </div>
        </el-form-item>
        <el-form-item label="团队状态">
          <el-select v-model="editForm.status" clearable placeholder="选择状态">
            <el-option label="活跃 (1)" :value="1" />
            <el-option label="禁用 (3)" :value="3" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="editSaving" @click="submitEditTeam">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ArrowLeft } from '@element-plus/icons-vue'
import { formatDate, formatMoney, formatFileSize } from '@/utils/format'
import {
  getTeamDetail,
  getTeamStaticAssets,
  getTeamCurrentInviteCode,
  createInviteCodeForTeam,
  updateTeam,
} from '@/api/teams'
import type { Team, TeamMember } from '@/types/team'

interface InviteInfo {
  has_active: boolean
  code_plain?: string
  code_hint?: string
  expires_at?: string
  note?: string
}

interface StaticAssetRow {
  id: string
  original_name: string
  content_type: string
  size_bytes: number
  created_at: string
}

const route = useRoute()
const router = useRouter()
const uuid = route.params.uuid as string

const loadingTeam = ref(true)
const team = ref<Team | null>(null)
const activeTab = ref('basic')

const members = computed<TeamMember[]>(() => team.value?.members ?? [])
const skillList = computed(() => team.value?.skills ?? [])

const loadingInvite = ref(false)
const inviteInfo = ref<InviteInfo | null>(null)
const creatingCode = ref(false)

const loadingAssets = ref(false)
const staticAssets = ref<StaticAssetRow[]>([])
const assetsMeta = ref({ page: 1, page_size: 20, total: 0 })
const assetsTabVisited = ref(false)

async function loadTeam() {
  loadingTeam.value = true
  try {
    const res = (await getTeamDetail(uuid)) as { data: Team }
    team.value = res.data
  } catch {
    team.value = null
  } finally {
    loadingTeam.value = false
  }
}

async function loadInvite() {
  loadingInvite.value = true
  try {
    const res = (await getTeamCurrentInviteCode(uuid)) as { data: InviteInfo }
    inviteInfo.value = res.data
  } catch {
    inviteInfo.value = { has_active: false }
  } finally {
    loadingInvite.value = false
  }
}

async function loadStaticAssets() {
  loadingAssets.value = true
  try {
    const res = (await getTeamStaticAssets(uuid, {
      page: assetsMeta.value.page,
      page_size: assetsMeta.value.page_size,
    })) as { data: StaticAssetRow[]; meta?: { total: number } }
    staticAssets.value = res.data ?? []
    assetsMeta.value.total = res.meta?.total ?? staticAssets.value.length
  } catch {
    staticAssets.value = []
    assetsMeta.value.total = 0
  } finally {
    loadingAssets.value = false
  }
}

function onAssetsSizeChange() {
  assetsMeta.value.page = 1
  loadStaticAssets()
}

function onTabChange(name: string | number) {
  const n = String(name)
  if (n === 'invite' && inviteInfo.value === null) loadInvite()
  if (n === 'assets' && !assetsTabVisited.value) {
    assetsTabVisited.value = true
    loadStaticAssets()
  }
}

function vibeLevelTagType(
  level: string,
): 'info' | 'warning' | 'success' | undefined {
  const m = String(level).match(/T(\d{1,2})\b/i)
  const num = m ? parseInt(m[1], 10) : 0
  if (num >= 1 && num <= 3) return 'info'
  if (num >= 4 && num <= 6) return undefined
  if (num >= 7 && num <= 8) return 'warning'
  if (num >= 9 && num <= 10) return 'success'
  return 'info'
}

const STATUS_MAP: Record<
  string,
  { label: string; type?: 'info' | 'success' | 'warning' }
> = {
  recruiting: { label: '招募中', type: 'info' },
  confirming: { label: '确认中', type: 'warning' },
  active: { label: '进行中', type: 'success' },
}

function teamStatusLabel(status: string | undefined) {
  if (!status) return '-'
  return STATUS_MAP[status]?.label || status
}

function teamStatusTagType(
  status: string | undefined,
): 'info' | 'warning' | 'success' | undefined {
  if (!status) return 'info'
  return STATUS_MAP[status]?.type ?? 'info'
}

function formatMoneyOrDash(amount: number | null | undefined) {
  if (amount == null) return '-'
  return formatMoney(amount)
}

function clampRatio(ratio: number) {
  const n = Number(ratio)
  if (Number.isNaN(n)) return 0
  return Math.min(100, Math.max(0, n))
}

async function onCreateInviteCode() {
  try {
    const { value } = await ElMessageBox.prompt('可选备注（将写入邀请码记录）', '生成新邀请码', {
      confirmButtonText: '生成',
      cancelButtonText: '取消',
      inputPlaceholder: '备注',
      inputValue: '',
    })
    creatingCode.value = true
    await createInviteCodeForTeam(uuid, value || undefined)
    ElMessage.success('已生成新邀请码')
    await loadInvite()
  } catch (e: unknown) {
    if (e === 'cancel' || e === 'close') return
  } finally {
    creatingCode.value = false
  }
}

// ──── 编辑团队对话框 ────
const editDialogVisible = ref(false)
const editSaving = ref(false)
const editForm = ref({
  vibe_level: undefined as string | undefined,
  vibe_power: undefined as number | undefined,
  budget_min: undefined as number | undefined,
  budget_max: undefined as number | undefined,
  status: undefined as number | undefined,
})

function openEditDialog() {
  editForm.value = {
    vibe_level: team.value?.vibe_level ?? undefined,
    vibe_power: team.value?.vibe_power ?? undefined,
    budget_min: team.value?.budget_min ?? undefined,
    budget_max: team.value?.budget_max ?? undefined,
    status: team.value?.status != null ? (typeof team.value.status === 'number' ? team.value.status : undefined) : undefined,
  }
  editDialogVisible.value = true
}

async function submitEditTeam() {
  const payload: Record<string, any> = {}
  const f = editForm.value
  if (f.vibe_level != null) payload.vibe_level = f.vibe_level
  if (f.vibe_power != null) payload.vibe_power = f.vibe_power
  if (f.budget_min != null) payload.budget_min = f.budget_min
  if (f.budget_max != null) payload.budget_max = f.budget_max
  if (f.status != null) payload.status = f.status
  if (Object.keys(payload).length === 0) {
    ElMessage.warning('请至少修改一个字段')
    return
  }
  editSaving.value = true
  try {
    await updateTeam(uuid, payload)
    ElMessage.success('已更新')
    editDialogVisible.value = false
    await loadTeam()
  } catch {
    ElMessage.error('更新失败')
  } finally {
    editSaving.value = false
  }
}

onMounted(() => {
  loadTeam()
})
</script>

<style scoped>
.header-back {
  display: flex;
  align-items: center;
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
  min-width: 0;
}

.profile-name-row {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
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

.info-grid.compact {
  margin-top: 16px;
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

.info-value.large {
  font-size: 22px;
  font-weight: 700;
}

.info-value.muted,
.muted {
  color: #999;
}

.mono {
  font-family: 'SF Mono', monospace;
}

.skill-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.member-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}

.inner-table {
  padding: 0;
  overflow: hidden;
}

.invite-panel {
  max-width: 560px;
}

.code-plain {
  display: inline-block;
  font-size: 15px;
  font-family: 'SF Mono', monospace;
  background: #f3f3f3;
  padding: 8px 12px;
  border-radius: 8px;
  color: #1a1c1c;
}

.gen-btn {
  margin-top: 20px;
}
</style>
