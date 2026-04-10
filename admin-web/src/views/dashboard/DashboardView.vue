<template>
  <div class="dashboard-page">
    <div class="page-header">
      <div>
        <h2 class="page-title">数据看板</h2>
        <p class="page-subtitle">平台运营核心指标概览</p>
      </div>
    </div>

    <div v-loading="loading" class="dashboard-body">
      <div class="stat-cards-row">
        <div class="stat-card">
          <div class="stat-label">注册用户</div>
          <div class="stat-value">{{ data.user_count }}</div>
          <div class="stat-sub">今日新增 {{ data.user_today }}</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">项目总数</div>
          <div class="stat-value">{{ data.project_count }}</div>
          <div class="stat-sub">本周新增 {{ data.project_week }}</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">活跃团队数</div>
          <div class="stat-value">{{ data.active_team_count }}</div>
          <div class="stat-sub">当前活跃承接方团队</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">订单总额</div>
          <div class="stat-value stat-value--money">{{ formatMoney(data.order_total_amount) }}</div>
          <div class="stat-sub">本月 GMV {{ formatMoney(data.order_month_amount) }}</div>
        </div>
        <div
          class="stat-card stat-card--clickable"
          role="button"
          tabindex="0"
          @click="goOnboarding"
          @keydown.enter="goOnboarding"
        >
          <div class="stat-label">
            待审核入驻
            <el-badge v-if="data.pending_onboarding_count > 0" :value="data.pending_onboarding_count" type="danger" />
          </div>
          <div class="stat-value">{{ data.pending_onboarding_count }}</div>
          <div class="stat-sub">点击进入入驻审核</div>
        </div>
      </div>

      <div class="ai-model-card">
        <div class="ai-model-card__header">
          <div>
            <div class="ai-model-card__title">AI 模型</div>
            <div class="ai-model-card__sub">当前激活的 LLM 模型，切换后立即生效</div>
          </div>
          <el-tag v-if="modelConfig.active_provider" type="info" size="small">
            {{ activeProviderName }}
          </el-tag>
        </div>
        <div class="ai-model-card__body">
          <el-select
            v-model="modelConfig.active_provider"
            placeholder="选择模型"
            :loading="modelSwitching"
            style="width: 280px"
            @change="handleModelChange"
          >
            <el-option
              v-for="p in modelConfig.providers"
              :key="p.id"
              :label="`${p.name}${p.available ? '' : ' (不可用)'}`"
              :value="p.id"
              :disabled="!p.available"
            />
          </el-select>
        </div>
      </div>

      <div class="charts-row">
        <div class="charts-left">
          <div class="chart-panel">
            <div class="chart-panel__title">用户注册趋势</div>
            <div class="chart-panel__sub">近 30 天</div>
            <v-chart class="chart" :option="userTrendOption" autoresize />
          </div>
          <div class="chart-panel">
            <div class="chart-panel__title">订单金额趋势</div>
            <div class="chart-panel__sub">近 30 天</div>
            <v-chart class="chart" :option="orderTrendOption" autoresize />
          </div>
        </div>
        <div class="charts-right">
          <div class="chart-panel chart-panel--tall">
            <div class="chart-panel__title">项目发布趋势</div>
            <div class="chart-panel__sub">近 30 天</div>
            <v-chart class="chart chart--tall" :option="projectTrendOption" autoresize />
          </div>
        </div>
      </div>

      <div class="quick-row">
        <div
          class="quick-card"
          role="button"
          tabindex="0"
          @click="router.push('/onboarding')"
          @keydown.enter="router.push('/onboarding')"
        >
          <el-icon class="quick-card__icon" :size="28"><CircleCheck /></el-icon>
          <div class="quick-card__body">
            <div class="quick-card__title">待审核入驻申请</div>
            <div class="quick-card__meta">{{ data.pending_onboarding_count }} 条待处理</div>
          </div>
          <el-icon class="quick-card__arrow"><ArrowRight /></el-icon>
        </div>
        <div
          class="quick-card"
          role="button"
          tabindex="0"
          @click="router.push({ path: '/projects', query: { status: '4' } })"
          @keydown.enter="router.push({ path: '/projects', query: { status: '4' } })"
        >
          <el-icon class="quick-card__icon" :size="28"><FolderOpened /></el-icon>
          <div class="quick-card__body">
            <div class="quick-card__title">进行中项目</div>
            <div class="quick-card__meta">按状态筛选查看</div>
          </div>
          <el-icon class="quick-card__arrow"><ArrowRight /></el-icon>
        </div>
        <div
          class="quick-card"
          role="button"
          tabindex="0"
          @click="router.push('/reports')"
          @keydown.enter="router.push('/reports')"
        >
          <el-icon class="quick-card__icon" :size="28"><Warning /></el-icon>
          <div class="quick-card__body">
            <div class="quick-card__title">待处理举报</div>
            <div class="quick-card__meta">{{ data.pending_report_count }} 条待处理</div>
          </div>
          <el-icon class="quick-card__arrow"><ArrowRight /></el-icon>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, shallowRef } from 'vue'
import { useRouter } from 'vue-router'
import VChart from 'vue-echarts'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { LineChart, BarChart } from 'echarts/charts'
import { GridComponent, TooltipComponent, LegendComponent } from 'echarts/components'
import type { EChartsCoreOption } from 'echarts/core'
import { ArrowRight, CircleCheck, FolderOpened, Warning } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { getDashboard } from '@/api/dashboard'
import { getAIModelConfig, updateAIModelConfig } from '@/api/ai-models'
import type { AIProvider } from '@/api/ai-models'
import { formatMoney } from '@/utils/format'

use([CanvasRenderer, LineChart, BarChart, GridComponent, TooltipComponent, LegendComponent])

interface DashboardData {
  user_count: number
  user_today: number
  project_count: number
  project_week: number
  active_team_count: number
  order_total_amount: number
  order_month_amount: number
  pending_onboarding_count: number
  pending_report_count: number
  user_trend: Array<{ date: string; count: number }>
  project_trend: Array<{ date: string; count: number }>
  order_trend: Array<{ date: string; amount: number }>
}

const EMPTY: DashboardData = {
  user_count: 0,
  user_today: 0,
  project_count: 0,
  project_week: 0,
  active_team_count: 0,
  order_total_amount: 0,
  order_month_amount: 0,
  pending_onboarding_count: 0,
  pending_report_count: 0,
  user_trend: [],
  project_trend: [],
  order_trend: [],
}

function numField(o: Record<string, unknown>, key: string): number {
  const v = o[key]
  return typeof v === 'number' && !Number.isNaN(v) ? v : 0
}

function normalizeTrendCount(raw: unknown): Array<{ date: string; count: number }> {
  if (!Array.isArray(raw)) return []
  const out: Array<{ date: string; count: number }> = []
  for (const item of raw) {
    if (item == null || typeof item !== 'object') continue
    const row = item as Record<string, unknown>
    if (typeof row.date === 'string' && typeof row.count === 'number' && !Number.isNaN(row.count)) {
      out.push({ date: row.date, count: row.count })
    }
  }
  return out
}

function normalizeTrendAmount(raw: unknown): Array<{ date: string; amount: number }> {
  if (!Array.isArray(raw)) return []
  const out: Array<{ date: string; amount: number }> = []
  for (const item of raw) {
    if (item == null || typeof item !== 'object') continue
    const row = item as Record<string, unknown>
    if (typeof row.date === 'string' && typeof row.amount === 'number' && !Number.isNaN(row.amount)) {
      out.push({ date: row.date, amount: row.amount })
    }
  }
  return out
}

/** Placeholder `{ status: "endpoint ready" }` or partial payloads → defaults per field */
function normalizeDashboard(raw: unknown): DashboardData {
  if (raw == null || typeof raw !== 'object') {
    return { ...EMPTY }
  }
  const o = raw as Record<string, unknown>
  return {
    user_count: numField(o, 'user_count'),
    user_today: numField(o, 'user_today'),
    project_count: numField(o, 'project_count'),
    project_week: numField(o, 'project_week'),
    active_team_count: numField(o, 'active_team_count'),
    order_total_amount: numField(o, 'order_total_amount'),
    order_month_amount: numField(o, 'order_month_amount'),
    pending_onboarding_count: numField(o, 'pending_onboarding_count'),
    pending_report_count: numField(o, 'pending_report_count'),
    user_trend: normalizeTrendCount(o.user_trend),
    project_trend: normalizeTrendCount(o.project_trend),
    order_trend: normalizeTrendAmount(o.order_trend),
  }
}

const router = useRouter()
const loading = ref(false)
const data = shallowRef<DashboardData>({ ...EMPTY })

// ── AI 模型配置 ──
const modelConfig = ref<{ active_provider: string; providers: AIProvider[] }>({
  active_provider: '',
  providers: [],
})
const modelSwitching = ref(false)

const activeProviderName = computed(() => {
  const p = modelConfig.value.providers.find((x) => x.id === modelConfig.value.active_provider)
  return p ? p.name : modelConfig.value.active_provider
})

async function fetchModelConfig() {
  try {
    const res = await getAIModelConfig() as any
    if (res?.data) {
      modelConfig.value = res.data
    }
  } catch {
    // 静默失败，不影响 dashboard
  }
}

async function handleModelChange(provider: string) {
  modelSwitching.value = true
  try {
    await updateAIModelConfig(provider)
    ElMessage.success(`已切换到 ${activeProviderName.value}`)
  } catch {
    // 切换失败时重新拉取
    await fetchModelConfig()
  } finally {
    modelSwitching.value = false
  }
}

const chartTextStyle = {
  color: '#666',
  fontSize: 12,
  fontFamily: 'Inter, sans-serif',
} as const

const axisLineStyle = { color: '#e5e5e5' }
const splitLineStyle = { color: '#e5e5e5' }

function buildLineOption(dates: string[], seriesName: string, values: number[]): EChartsCoreOption {
  return {
    textStyle: chartTextStyle,
    tooltip: {
      trigger: 'axis',
      textStyle: { fontSize: 12, fontFamily: 'Inter, sans-serif' },
    },
    legend: {
      data: [seriesName],
      textStyle: chartTextStyle,
      top: 0,
    },
    grid: { left: 48, right: 16, top: 36, bottom: 28 },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: dates,
      axisLine: { lineStyle: axisLineStyle },
      axisLabel: { ...chartTextStyle, rotate: dates.length > 14 ? 40 : 0 },
    },
    yAxis: {
      type: 'value',
      axisLine: { show: false },
      axisTick: { show: false },
      splitLine: { lineStyle: splitLineStyle },
      axisLabel: { ...chartTextStyle },
    },
    series: [
      {
        name: seriesName,
        type: 'line',
        smooth: true,
        symbol: 'circle',
        symbolSize: 6,
        lineStyle: { color: '#1a1c1c', width: 2 },
        itemStyle: { color: '#1a1c1c' },
        data: values,
      },
    ],
  }
}

function buildBarOption(dates: string[], amounts: number[]): EChartsCoreOption {
  return {
    textStyle: chartTextStyle,
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'shadow' },
      textStyle: { fontSize: 12, fontFamily: 'Inter, sans-serif' },
      valueFormatter: (v: number | string) => formatMoney(Number(v)),
    },
    legend: {
      data: ['订单金额'],
      textStyle: chartTextStyle,
      top: 0,
    },
    grid: { left: 56, right: 16, top: 36, bottom: 28 },
    xAxis: {
      type: 'category',
      data: dates,
      axisLine: { lineStyle: axisLineStyle },
      axisLabel: { ...chartTextStyle, rotate: dates.length > 14 ? 40 : 0 },
    },
    yAxis: {
      type: 'value',
      axisLine: { show: false },
      axisTick: { show: false },
      splitLine: { lineStyle: splitLineStyle },
      axisLabel: {
        ...chartTextStyle,
        formatter: (val: number) => {
          if (val >= 1_000_000) return `${(val / 1_000_000).toFixed(1)}M`
          if (val >= 1_000) return `${(val / 1_000).toFixed(0)}k`
          return String(val)
        },
      },
    },
    series: [
      {
        name: '订单金额',
        type: 'bar',
        barMaxWidth: 24,
        itemStyle: { color: '#333', borderRadius: [4, 4, 0, 0] },
        data: amounts,
      },
    ],
  }
}

const userTrendOption = computed((): EChartsCoreOption => {
  const t = data.value.user_trend
  const dates = t.map((i) => i.date)
  const counts = t.map((i) => i.count)
  return buildLineOption(dates, '注册用户数', counts)
})

const orderTrendOption = computed((): EChartsCoreOption => {
  const t = data.value.order_trend
  const dates = t.map((i) => i.date)
  const amounts = t.map((i) => i.amount)
  return buildBarOption(dates, amounts)
})

const projectTrendOption = computed((): EChartsCoreOption => {
  const t = data.value.project_trend
  const dates = t.map((i) => i.date)
  const counts = t.map((i) => i.count)
  return buildLineOption(dates, '发布项目数', counts)
})

function goOnboarding() {
  router.push('/onboarding')
}

async function fetchDashboard() {
  loading.value = true
  try {
    const res = await getDashboard()
    const payload = res.data
    data.value = normalizeDashboard(payload)
  } catch {
    data.value = { ...EMPTY }
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchDashboard()
  fetchModelConfig()
})
</script>

<style scoped>
.dashboard-page {
  color: #1a1c1c;
  min-height: 100%;
}

.dashboard-body {
  min-height: 200px;
}

.stat-cards-row {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 16px;
  margin-bottom: 20px;
}

@media (max-width: 1200px) {
  .stat-cards-row {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 640px) {
  .stat-cards-row {
    grid-template-columns: 1fr;
  }
}

.stat-card--clickable {
  cursor: pointer;
}

.stat-card--clickable:focus-visible {
  outline: 2px solid #1a1c1c;
  outline-offset: 2px;
}

.stat-label {
  display: flex;
  align-items: center;
  gap: 8px;
}

.stat-label :deep(.el-badge__content) {
  border: none;
}

.stat-value--money {
  font-size: 22px;
}

.ai-model-card {
  background: #fff;
  border-radius: 10px;
  padding: 20px 24px;
  margin-bottom: 20px;
}

.ai-model-card__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.ai-model-card__title {
  font-size: 15px;
  font-weight: 600;
  color: #1a1c1c;
}

.ai-model-card__sub {
  font-size: 12px;
  color: #999;
  margin-top: 4px;
}

.ai-model-card__body {
  display: flex;
  align-items: center;
  gap: 12px;
}

.charts-row {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 16px;
  margin-bottom: 20px;
  align-items: stretch;
}

@media (max-width: 1024px) {
  .charts-row {
    grid-template-columns: 1fr;
  }
}

.charts-left {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.charts-right {
  min-height: 0;
}

.chart-panel {
  background: #fff;
  border-radius: 10px;
  padding: 20px 20px 12px;
}

.chart-panel--tall {
  height: 100%;
  min-height: 420px;
  display: flex;
  flex-direction: column;
}

.chart-panel__title {
  font-size: 15px;
  font-weight: 600;
  color: #1a1c1c;
}

.chart-panel__sub {
  font-size: 12px;
  color: #999;
  margin-top: 4px;
  margin-bottom: 8px;
}

.chart {
  width: 100%;
  height: 280px;
}

.chart--tall {
  flex: 1;
  min-height: 320px;
  height: auto;
}

.quick-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}

@media (max-width: 900px) {
  .quick-row {
    grid-template-columns: 1fr;
  }
}

.quick-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 20px 22px;
  background: #fff;
  border-radius: 10px;
  cursor: pointer;
  transition: box-shadow 0.2s;
}

.quick-card:hover {
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.04);
}

.quick-card:focus-visible {
  outline: 2px solid #1a1c1c;
  outline-offset: 2px;
}

.quick-card__icon {
  flex-shrink: 0;
  color: #1a1c1c;
}

.quick-card__body {
  flex: 1;
  min-width: 0;
}

.quick-card__title {
  font-size: 15px;
  font-weight: 600;
  color: #1a1c1c;
}

.quick-card__meta {
  font-size: 12px;
  color: #999;
  margin-top: 4px;
}

.quick-card__arrow {
  flex-shrink: 0;
  color: #999;
  font-size: 18px;
}
</style>
