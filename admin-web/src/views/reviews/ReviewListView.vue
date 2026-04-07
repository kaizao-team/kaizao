<template>
  <div>
    <div class="page-header">
      <div>
        <h2 class="page-title">评价管理</h2>
        <p class="page-subtitle">用户评价展示与内容审核</p>
      </div>
    </div>

    <div class="filter-bar filter-bar--wrap">
      <el-select
        v-model="filters.status"
        placeholder="状态"
        clearable
        style="width: 130px"
        @change="handleSearch"
      >
        <el-option label="正常" :value="1" />
        <el-option label="已隐藏" :value="2" />
      </el-select>

      <div class="rating-slider-wrap">
        <span class="slider-label">评分</span>
        <el-slider
          v-model="ratingRange"
          range
          :min="1"
          :max="5"
          :step="1"
          show-stops
          style="width: 220px"
          @change="handleSearch"
        />
      </div>

      <el-date-picker
        v-model="dateRange"
        type="daterange"
        range-separator="至"
        start-placeholder="开始"
        end-placeholder="结束"
        value-format="YYYY-MM-DD"
        style="width: 280px"
        @change="handleSearch"
      />

      <el-select
        v-model="filters.anonymous"
        placeholder="是否匿名"
        clearable
        style="width: 130px"
        @change="handleSearch"
      >
        <el-option label="匿名" value="true" />
        <el-option label="非匿名" value="false" />
      </el-select>

      <el-button type="primary" @click="handleSearch">查询</el-button>
      <el-button @click="resetFilters">重置</el-button>
    </div>

    <div class="table-card">
      <el-table stripe :data="tableData" v-loading="loading" @row-click="onRowClick">
        <el-table-column label="UUID" min-width="120" show-overflow-tooltip>
          <template #default="{ row }">
            {{ truncateUuid(row.uuid) }}
          </template>
        </el-table-column>
        <el-table-column prop="project_title" label="关联项目" min-width="160" show-overflow-tooltip />
        <el-table-column label="评价人" min-width="160">
          <template #default="{ row }">
            <div class="reviewer-cell">
              <span>{{ row.reviewer_nickname || '-' }}</span>
              <el-tag
                v-if="USER_ROLES[row.reviewer_role] != null"
                :type="reviewerRoleTagType(row.reviewer_role)"
                size="small"
                class="role-tag"
              >
                {{ USER_ROLES[row.reviewer_role] }}
              </el-tag>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="reviewee_nickname" label="被评价人" width="120" show-overflow-tooltip />
        <el-table-column label="综合评分" width="140" align="center">
          <template #default="{ row }">
            <el-rate :model-value="row.overall_rating" disabled show-score text-color="#1a1c1c" />
          </template>
        </el-table-column>
        <el-table-column
          prop="content"
          label="内容"
          min-width="200"
          width="200"
          show-overflow-tooltip
        />
        <el-table-column label="标签" min-width="160">
          <template #default="{ row }">
            <el-tag
              v-for="(tag, i) in row.tags || []"
              :key="i"
              size="small"
              class="tag-item"
            >
              {{ tag }}
            </el-tag>
            <span v-if="!row.tags?.length" class="text-muted">—</span>
          </template>
        </el-table-column>
        <el-table-column label="匿名" width="80" align="center">
          <template #default="{ row }">
            {{ row.is_anonymous ? '是' : '否' }}
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="reviewTagType(row.status)" size="small">
              {{ REVIEW_STATUS[row.status]?.label || '未知' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="时间" width="160">
          <template #default="{ row }">
            {{ formatDate(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" fixed="right" align="center">
          <template #default="{ row }">
            <el-button
              v-if="row.status === 1"
              link
              type="primary"
              size="small"
              @click.stop="confirmHide(row)"
            >
              隐藏
            </el-button>
            <el-button
              v-else-if="row.status === 2"
              link
              type="primary"
              size="small"
              @click.stop="confirmRestore(row)"
            >
              恢复
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

    <el-drawer v-model="drawerVisible" title="评价详情" size="420px" destroy-on-close>
      <template v-if="activeReview">
        <section class="drawer-section">
          <h4 class="drawer-heading">维度评分</h4>
          <ul v-if="dimensionEntries.length" class="kv-list">
            <li v-for="item in dimensionEntries" :key="item[0]">
              <span class="k">{{ item[0] }}</span>
              <span class="v">{{ item[1] }}</span>
            </li>
          </ul>
          <p v-else class="text-muted">暂无</p>
        </section>
        <section class="drawer-section">
          <h4 class="drawer-heading">成员评分</h4>
          <pre v-if="memberRatingsText" class="json-block">{{ memberRatingsText }}</pre>
          <p v-else class="text-muted">暂无</p>
        </section>
        <section class="drawer-section">
          <h4 class="drawer-heading">完整内容</h4>
          <p class="body-text">{{ activeReview.content }}</p>
        </section>
        <section class="drawer-section">
          <h4 class="drawer-heading">回复内容</h4>
          <p class="body-text">{{ activeReview.reply_content || '—' }}</p>
        </section>
      </template>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useTable } from '@/composables/useTable'
import { getAdminReviews, updateReviewStatus } from '@/api/reviews'
import { formatDate } from '@/utils/format'
import { REVIEW_STATUS, USER_ROLES } from '@/utils/constants'
import type { Review } from '@/types/review'

const filters = reactive({
  status: undefined as number | undefined,
  anonymous: '' as '' | 'true' | 'false',
})
const ratingRange = ref<[number, number]>([1, 5])
const dateRange = ref<string[]>([])

const { loading, tableData, pagination, loadData, handlePageChange, handleSizeChange } =
  useTable<Review>(getAdminReviews)

type ElTagType = 'info' | 'primary' | 'success' | 'warning' | 'danger'

function reviewTagType(status: number): ElTagType | undefined {
  const t = REVIEW_STATUS[status]?.type
  if (t === 'info' || t === 'primary' || t === 'success' || t === 'warning' || t === 'danger') {
    return t
  }
  return undefined
}

function reviewerRoleTagType(role: number): ElTagType {
  if (role === 1) return 'info'
  if (role === 2) return 'primary'
  return 'info'
}

function truncateUuid(uuid: string) {
  if (!uuid) return '-'
  return uuid.length > 12 ? `${uuid.slice(0, 8)}…${uuid.slice(-4)}` : uuid
}

function buildParams() {
  const params: Record<string, any> = {}
  if (filters.status !== undefined) params.status = filters.status
  const [rMin, rMax] = ratingRange.value
  if (rMin != null) params.rating_min = rMin
  if (rMax != null) params.rating_max = rMax
  if (dateRange.value?.length === 2) {
    params.start_date = dateRange.value[0]
    params.end_date = dateRange.value[1]
  }
  if (filters.anonymous === 'true') params.is_anonymous = true
  if (filters.anonymous === 'false') params.is_anonymous = false
  return params
}

function handleSearch() {
  pagination.page = 1
  loadData(buildParams())
}

function resetFilters() {
  filters.status = undefined
  filters.anonymous = ''
  ratingRange.value = [1, 5]
  dateRange.value = []
  handleSearch()
}

const drawerVisible = ref(false)
const activeReview = ref<Review | null>(null)

const dimensionEntries = computed(() => {
  const dr = activeReview.value?.dimension_ratings
  if (!dr || typeof dr !== 'object') return [] as [string, number][]
  return Object.entries(dr)
})

const memberRatingsText = computed(() => {
  const m = activeReview.value?.member_ratings
  if (m == null) return ''
  try {
    return JSON.stringify(m, null, 2)
  } catch {
    return String(m)
  }
})

function onRowClick(row: Review) {
  activeReview.value = row
  drawerVisible.value = true
}

async function confirmHide(row: Review) {
  try {
    await ElMessageBox.confirm('确认隐藏该条评价？', '隐藏评价', {
      confirmButtonText: '确认',
      cancelButtonText: '取消',
      type: 'warning',
    })
    await updateReviewStatus(row.uuid, { status: 2 })
    ElMessage.success('已隐藏')
    loadData(buildParams())
  } catch {
    /* cancel */
  }
}

async function confirmRestore(row: Review) {
  try {
    await ElMessageBox.confirm('确认恢复该条评价为正常展示？', '恢复评价', {
      confirmButtonText: '确认',
      cancelButtonText: '取消',
      type: 'warning',
    })
    await updateReviewStatus(row.uuid, { status: 1 })
    ElMessage.success('已恢复')
    loadData(buildParams())
  } catch {
    /* cancel */
  }
}

onMounted(() => {
  loadData(buildParams())
})
</script>

<style scoped>
.filter-bar--wrap {
  align-items: center;
}

.rating-slider-wrap {
  display: flex;
  align-items: center;
  gap: 12px;
}

.slider-label {
  font-size: 12px;
  font-weight: 600;
  color: #999;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  white-space: nowrap;
}

.reviewer-cell {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.role-tag {
  flex-shrink: 0;
}

.tag-item {
  margin-right: 6px;
  margin-bottom: 4px;
}

.text-muted {
  color: #bbb;
  font-size: 13px;
}

.drawer-section {
  margin-bottom: 24px;
}

.drawer-heading {
  font-size: 11px;
  font-weight: 600;
  color: #999;
  text-transform: uppercase;
  letter-spacing: 0.6px;
  margin-bottom: 10px;
}

.kv-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.kv-list li {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  font-size: 13px;
  padding: 6px 0;
  border-bottom: 1px solid #f0f0f0;
}

.kv-list .k {
  color: #666;
}

.kv-list .v {
  font-weight: 600;
  color: #1a1c1c;
}

.json-block {
  font-size: 12px;
  background: #f9f9f9;
  padding: 12px;
  border-radius: 8px;
  overflow: auto;
  max-height: 200px;
  margin: 0;
  color: #333;
}

.body-text {
  font-size: 14px;
  line-height: 1.6;
  color: #1a1c1c;
  white-space: pre-wrap;
  word-break: break-word;
  margin: 0;
}
</style>
