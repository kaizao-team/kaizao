<template>
  <div>
    <div class="page-header">
      <div>
        <h2 class="page-title">团队管理</h2>
        <p class="page-subtitle">查看团队方团队、Vibe 等级与成员概况</p>
      </div>
    </div>

    <div class="filter-bar">
      <el-input
        v-model="filters.keyword"
        placeholder="搜索团队名、UUID"
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
        v-model="filters.vibe_level"
        placeholder="Vibe Level"
        clearable
        style="width: 140px"
        @change="handleSearch"
      >
        <el-option
          v-for="opt in VIBE_LEVEL_OPTIONS"
          :key="opt"
          :label="opt"
          :value="opt"
        />
      </el-select>

      <el-button type="primary" @click="handleSearch">查询</el-button>
      <el-button @click="resetFilters">重置</el-button>
    </div>

    <div class="table-card">
      <el-table
        v-loading="loading"
        :data="tableData"
        stripe
        class="teams-table"
        @row-click="onRowClick"
      >
        <el-table-column label="团队" min-width="200" fixed>
          <template #default="{ row }">
            <div class="team-cell">
              <el-avatar :size="36" :src="row.avatar_url ?? undefined">
                {{ (row.team_name || '?')[0] }}
              </el-avatar>
              <div class="team-info">
                <span class="team-name">{{ row.team_name || '-' }}</span>
                <span class="team-id">{{ row.id }}</span>
              </div>
            </div>
          </template>
        </el-table-column>

        <el-table-column label="队长" width="180">
          <template #default="{ row }">
            <div class="leader-cell">
              <el-avatar :size="28" :src="row.leader_avatar_url ?? undefined">
                {{ (row.nickname || '?')[0] }}
              </el-avatar>
              <span class="leader-name">{{ row.nickname || '-' }}</span>
            </div>
          </template>
        </el-table-column>

        <el-table-column prop="member_count" label="成员数" width="88" align="center" />

        <el-table-column label="Vibe Level" width="110" align="center">
          <template #default="{ row }">
            <el-tag size="small" :type="vibeLevelTagType(row.vibe_level)">
              {{ row.vibe_level || '-' }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column prop="vibe_power" label="Vibe Power" width="110" align="center">
          <template #default="{ row }">
            <span class="mono">{{ row.vibe_power ?? '-' }}</span>
          </template>
        </el-table-column>

        <el-table-column label="平均评分" width="140" align="center">
          <template #default="{ row }">
            <el-rate
              :model-value="Number(row.avg_rating) || 0"
              disabled
              allow-half
              show-score
              text-color="#1a1c1c"
              score-template="{value}"
            />
          </template>
        </el-table-column>

        <el-table-column prop="completed_projects" label="完成项目" width="100" align="center" />

        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag size="small" :type="teamStatusTagType(row.status)">
              {{ teamStatusLabel(row.status) }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column label="创建时间" width="168">
          <template #default="{ row }">
            {{ formatDate(row.created_at) }}
          </template>
        </el-table-column>

        <el-table-column label="操作" width="100" fixed="right" align="center">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click.stop="goDetail(row.id)">
              详情
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
  </div>
</template>

<script setup lang="ts">
import { reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { Search } from '@element-plus/icons-vue'
import { useTable } from '@/composables/useTable'
import { getTeams } from '@/api/teams'
import { formatDate } from '@/utils/format'
import type { Team } from '@/types/team'

const router = useRouter()

const VIBE_LEVEL_OPTIONS = Array.from({ length: 10 }, (_, i) => `vc-T${i + 1}`)

const filters = reactive({
  keyword: '',
  vibe_level: '' as string,
})

const { loading, tableData, pagination, loadData, handlePageChange, handleSizeChange } =
  useTable<Team>(getTeams)

function buildParams() {
  const params: Record<string, any> = {}
  if (filters.keyword) params.keyword = filters.keyword
  if (filters.vibe_level) params.vibe_level = filters.vibe_level
  return params
}

function handleSearch() {
  pagination.page = 1
  loadData(buildParams())
}

function resetFilters() {
  filters.keyword = ''
  filters.vibe_level = ''
  handleSearch()
}

function goDetail(uuid: string) {
  router.push({ name: 'TeamDetail', params: { uuid } })
}

function onRowClick(row: Team) {
  if (row?.id) goDetail(row.id)
}

function vibeLevelTagType(
  level: string,
): 'info' | 'warning' | 'success' | undefined {
  const m = String(level).match(/T(\d{1,2})\b/i)
  const n = m ? parseInt(m[1], 10) : 0
  if (n >= 1 && n <= 3) return 'info'
  if (n >= 4 && n <= 6) return undefined
  if (n >= 7 && n <= 8) return 'warning'
  if (n >= 9 && n <= 10) return 'success'
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

function teamStatusLabel(status: string) {
  return STATUS_MAP[status]?.label || status || '-'
}

function teamStatusTagType(status: string): 'info' | 'warning' | 'success' | undefined {
  return STATUS_MAP[status]?.type ?? 'info'
}

onMounted(() => {
  loadData(buildParams())
})
</script>

<style scoped>
.teams-table {
  --el-table-bg-color: #fff;
  --el-table-tr-bg-color: #fff;
}

.team-cell,
.leader-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}

.team-cell {
  cursor: pointer;
}

.team-info {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.team-name {
  font-size: 13px;
  font-weight: 600;
  color: #1a1c1c;
}

.team-id {
  font-size: 11px;
  color: #bbb;
  font-family: 'SF Mono', monospace;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.leader-name {
  font-size: 13px;
  color: #333;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.mono {
  font-family: 'SF Mono', monospace;
  font-weight: 600;
}
</style>
