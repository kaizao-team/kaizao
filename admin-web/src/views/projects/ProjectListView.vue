<template>
  <div>
    <div class="page-header">
      <div>
        <h2 class="page-title">项目管理</h2>
        <p class="page-subtitle">管理平台项目与审核</p>
      </div>
    </div>

    <div class="filter-bar">
      <el-input
        v-model="filters.keyword"
        placeholder="搜索标题、UUID"
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
        v-model="filters.status"
        placeholder="状态"
        clearable
        style="width: 130px"
        @change="handleSearch"
      >
        <el-option
          v-for="(cfg, key) in PROJECT_STATUS"
          :key="key"
          :label="cfg.label"
          :value="Number(key)"
        />
      </el-select>

      <el-input
        v-model="filters.category"
        placeholder="分类"
        clearable
        style="width: 140px"
        @clear="handleSearch"
        @keyup.enter="handleSearch"
      />

      <div class="budget-range">
        <el-input-number
          v-model="filters.budget_min"
          :min="0"
          :controls="false"
          placeholder="预算最低"
          class="budget-input"
          @change="handleSearch"
        />
        <span class="budget-sep">~</span>
        <el-input-number
          v-model="filters.budget_max"
          :min="0"
          :controls="false"
          placeholder="预算最高"
          class="budget-input"
          @change="handleSearch"
        />
      </div>

      <el-date-picker
        v-model="publishedRange"
        type="daterange"
        range-separator="至"
        start-placeholder="创建开始"
        end-placeholder="创建结束"
        value-format="YYYY-MM-DD"
        style="width: 280px"
        @change="handleSearch"
      />

      <el-button type="primary" @click="handleSearch">查询</el-button>
      <el-button @click="resetFilters">重置</el-button>
    </div>

    <div class="table-card">
      <el-table v-loading="loading" :data="tableData" stripe>
        <el-table-column
          prop="title"
          label="标题"
          min-width="200"
          show-overflow-tooltip
        />

        <el-table-column label="项目方" width="200">
          <template #default="{ row }">
            <div class="owner-cell">
              <el-avatar :size="32" :src="row.owner_avatar ?? undefined">
                {{ (row.owner_nickname || '?')[0] }}
              </el-avatar>
              <span class="owner-name">{{ row.owner_nickname || '-' }}</span>
            </div>
          </template>
        </el-table-column>

        <el-table-column prop="category" label="分类" width="120" show-overflow-tooltip />

        <el-table-column label="预算范围" min-width="160">
          <template #default="{ row }">
            {{ formatBudgetRange(row) }}
          </template>
        </el-table-column>

        <el-table-column label="成交价" width="110" align="right">
          <template #default="{ row }">
            {{ formatMoney(row.agreed_price) }}
          </template>
        </el-table-column>

        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag
              :type="tagType(row.status)"
              size="small"
            >
              {{ PROJECT_STATUS[row.status]?.label || '未知' }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column prop="bid_count" label="投标数" width="80" align="center" />

        <el-table-column prop="view_count" label="浏览量" width="80" align="center" />

        <el-table-column label="发布时间" width="160">
          <template #default="{ row }">
            {{ formatDate(row.published_at) }}
          </template>
        </el-table-column>

        <el-table-column label="操作" width="180" fixed="right" align="center">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click="goDetail(row.uuid)">
              详情
            </el-button>
            <el-dropdown trigger="click" @command="(cmd: string) => handleReviewCommand(row, cmd)">
              <el-button link size="small" type="primary">
                审核
                <el-icon class="el-icon--right"><ArrowDown /></el-icon>
              </el-button>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="approve">审核通过</el-dropdown-item>
                  <el-dropdown-item command="reject">下架</el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
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
import { ref, reactive, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, ArrowDown } from '@element-plus/icons-vue'
import { useTable } from '@/composables/useTable'
import { getAdminProjects, reviewProject } from '@/api/projects'
import { formatDate, formatMoney } from '@/utils/format'
import { PROJECT_STATUS } from '@/utils/constants'
import type { Project } from '@/types/project'

const router = useRouter()
const route = useRoute()

const filters = reactive({
  keyword: '',
  status: undefined as number | undefined,
  category: '',
  budget_min: undefined as number | undefined,
  budget_max: undefined as number | undefined,
})
const publishedRange = ref<string[]>([])

const { loading, tableData, pagination, loadData, handlePageChange, handleSizeChange } =
  useTable<Project>(getAdminProjects)

type ElTagType = 'info' | 'primary' | 'success' | 'warning' | 'danger'

function tagType(status: number): ElTagType | undefined {
  const t = PROJECT_STATUS[status]?.type
  if (t === 'info' || t === 'primary' || t === 'success' || t === 'warning' || t === 'danger') {
    return t
  }
  return undefined
}

function formatBudgetRange(row: Project) {
  const min = row.budget_min
  const max = row.budget_max
  if (min == null && max == null) return '-'
  if (min != null && max != null) return `${formatMoney(min)} ~ ${formatMoney(max)}`
  if (min != null) return `${formatMoney(min)} ~`
  return `~ ${formatMoney(max)}`
}

function buildParams() {
  const params: Record<string, any> = {}
  if (filters.keyword) params.keyword = filters.keyword
  if (filters.status !== undefined) params.status = filters.status
  if (filters.category.trim()) params.category = filters.category.trim()
  if (filters.budget_min != null) params.budget_min = filters.budget_min
  if (filters.budget_max != null) params.budget_max = filters.budget_max
  if (publishedRange.value?.length === 2) {
    params.start_date = publishedRange.value[0]
    params.end_date = publishedRange.value[1]
  }
  return params
}

function handleSearch() {
  pagination.page = 1
  loadData(buildParams())
}

function resetFilters() {
  filters.keyword = ''
  filters.status = undefined
  filters.category = ''
  filters.budget_min = undefined
  filters.budget_max = undefined
  publishedRange.value = []
  handleSearch()
}

function goDetail(uuid: string) {
  router.push({ name: 'ProjectDetail', params: { uuid } })
}

async function handleReviewCommand(row: Project, cmd: string) {
  if (cmd === 'approve') {
    try {
      await ElMessageBox.confirm(
        `确认审核通过项目「${row.title}」？`,
        '审核通过',
        { confirmButtonText: '确认', cancelButtonText: '取消', type: 'warning' },
      )
      await reviewProject(row.uuid, { action: 'approve' })
      ElMessage.success('操作成功')
      loadData(buildParams())
    } catch {
      /* cancel or error */
    }
    return
  }
  if (cmd === 'reject') {
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
      await reviewProject(row.uuid, { action: 'reject', reason: value.trim() })
      ElMessage.success('已下架')
      loadData(buildParams())
    } catch {
      /* cancel or error */
    }
  }
}

onMounted(() => {
  const queryStatus = route.query.status
  if (queryStatus != null && queryStatus !== '') {
    filters.status = Number(queryStatus)
  }
  loadData(buildParams())
})
</script>

<style scoped>
.budget-range {
  display: flex;
  align-items: center;
  gap: 8px;
}

.budget-input {
  width: 120px;
}

.budget-sep {
  color: #999;
  font-size: 13px;
}

.owner-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}

.owner-name {
  font-size: 13px;
  font-weight: 500;
  color: #1a1c1c;
}
</style>
