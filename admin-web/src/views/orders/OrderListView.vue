<template>
  <div>
    <div class="page-header">
      <div>
        <h2 class="page-title">订单与财务</h2>
        <p class="page-subtitle">订单流水、托管与提现记录</p>
      </div>
    </div>

    <div class="stat-cards">
      <div class="stat-card">
        <div class="stat-label">总 GMV</div>
        <div class="stat-value">{{ formatMoney(finance.total_gmv) }}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">本月 GMV</div>
        <div class="stat-value">{{ formatMoney(finance.month_gmv) }}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">总平台手续费</div>
        <div class="stat-value">{{ formatMoney(finance.total_platform_fee) }}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">待释放托管金额</div>
        <div class="stat-value">{{ formatMoney(finance.pending_escrow_amount) }}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">待处理退款数</div>
        <div class="stat-value">{{ finance.pending_refund_count }}</div>
        <div class="stat-sub">笔</div>
      </div>
    </div>

    <el-tabs v-model="activeTab" class="order-tabs" @tab-change="onTabChange">
      <el-tab-pane label="订单列表" name="orders">
        <div class="filter-bar">
          <el-input
            v-model="orderFilters.order_no"
            placeholder="订单号"
            clearable
            style="width: 200px"
            @clear="handleOrderSearch"
            @keyup.enter="handleOrderSearch"
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>

          <el-select
            v-model="orderFilters.status"
            placeholder="状态"
            clearable
            style="width: 130px"
            @change="handleOrderSearch"
          >
            <el-option
              v-for="(cfg, key) in ORDER_STATUS"
              :key="key"
              :label="cfg.label"
              :value="Number(key)"
            />
          </el-select>

          <el-select
            v-model="orderFilters.payment_method"
            placeholder="支付方式"
            clearable
            style="width: 130px"
            @change="handleOrderSearch"
          >
            <el-option label="微信" value="wechat" />
            <el-option label="支付宝" value="alipay" />
          </el-select>

          <div class="amount-range">
            <el-input-number
              v-model="orderFilters.amount_min"
              :min="0"
              :controls="false"
              placeholder="金额最低"
              class="amount-input"
              @change="handleOrderSearch"
            />
            <span class="amount-sep">~</span>
            <el-input-number
              v-model="orderFilters.amount_max"
              :min="0"
              :controls="false"
              placeholder="金额最高"
              class="amount-input"
              @change="handleOrderSearch"
            />
          </div>

          <el-date-picker
            v-model="orderTimeRange"
            type="daterange"
            range-separator="至"
            start-placeholder="创建开始"
            end-placeholder="创建结束"
            value-format="YYYY-MM-DD"
            style="width: 280px"
            @change="handleOrderSearch"
          />

          <el-button type="primary" @click="handleOrderSearch">查询</el-button>
          <el-button @click="resetOrderFilters">重置</el-button>
        </div>

        <div class="table-card">
          <el-table v-loading="ordersLoading" :data="ordersData" stripe>
            <el-table-column prop="order_no" label="订单号" min-width="160" show-overflow-tooltip />
            <el-table-column prop="project_title" label="关联项目" min-width="180" show-overflow-tooltip />
            <el-table-column prop="payer_nickname" label="付款方" width="120" show-overflow-tooltip />
            <el-table-column label="收款方" min-width="140" show-overflow-tooltip>
              <template #default="{ row }">
                {{ formatPayee(row) }}
              </template>
            </el-table-column>
            <el-table-column label="金额" width="120" align="right">
              <template #default="{ row }">
                {{ formatMoney(row.amount) }}
              </template>
            </el-table-column>
            <el-table-column label="平台费率" width="100" align="center">
              <template #default="{ row }">
                {{ formatFeeRate(row.platform_fee_rate) }}
              </template>
            </el-table-column>
            <el-table-column label="手续费" width="110" align="right">
              <template #default="{ row }">
                {{ formatMoney(row.platform_fee) }}
              </template>
            </el-table-column>
            <el-table-column label="实付" width="110" align="right">
              <template #default="{ row }">
                {{ formatMoney(row.actual_amount) }}
              </template>
            </el-table-column>
            <el-table-column label="支付方式" width="100" align="center">
              <template #default="{ row }">
                {{ formatPaymentMethod(row.payment_method) }}
              </template>
            </el-table-column>
            <el-table-column label="状态" width="100" align="center">
              <template #default="{ row }">
                <el-tag :type="orderTagType(row.status)" size="small">
                  {{ ORDER_STATUS[row.status]?.label || '未知' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="创建时间" width="160">
              <template #default="{ row }">
                {{ formatDate(row.created_at) }}
              </template>
            </el-table-column>
            <el-table-column label="支付时间" width="160">
              <template #default="{ row }">
                {{ formatDate(row.paid_at) }}
              </template>
            </el-table-column>
          </el-table>

          <div class="pagination-wrapper">
            <el-pagination
              v-model:current-page="ordersPagination.page"
              v-model:page-size="ordersPagination.page_size"
              :total="ordersPagination.total"
              :page-sizes="[20, 50, 100]"
              layout="total, sizes, prev, pager, next"
              @current-change="handleOrdersPageChange"
              @size-change="handleOrdersSizeChange"
            />
          </div>
        </div>
      </el-tab-pane>

      <el-tab-pane label="提现记录" name="withdrawals">
        <div class="table-card">
          <el-table v-loading="wdLoading" :data="wdData" stripe>
            <el-table-column prop="user_nickname" label="用户昵称" min-width="140" show-overflow-tooltip />
            <el-table-column label="提现金额" width="120" align="right">
              <template #default="{ row }">
                {{ formatMoney(row.amount) }}
              </template>
            </el-table-column>
            <el-table-column prop="withdraw_method" label="提现方式" width="120" show-overflow-tooltip />
            <el-table-column label="提现账号" min-width="160" show-overflow-tooltip>
              <template #default="{ row }">
                {{ maskPhone(row.withdraw_account) }}
              </template>
            </el-table-column>
            <el-table-column label="状态" width="100" align="center">
              <template #default="{ row }">
                <el-tag :type="withdrawalTagType(row.status)" size="small">
                  {{ withdrawalStatusLabel(row.status) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="申请时间" width="160">
              <template #default="{ row }">
                {{ formatDate(row.created_at) }}
              </template>
            </el-table-column>
          </el-table>

          <div class="pagination-wrapper">
            <el-pagination
              v-model:current-page="wdPagination.page"
              v-model:page-size="wdPagination.page_size"
              :total="wdPagination.total"
              :page-sizes="[20, 50, 100]"
              layout="total, sizes, prev, pager, next"
              @current-change="handleWdPageChange"
              @size-change="handleWdSizeChange"
            />
          </div>
        </div>
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { Search } from '@element-plus/icons-vue'
import { useTable } from '@/composables/useTable'
import { getAdminOrders, getFinanceSummary, getWithdrawals } from '@/api/orders'
import { formatDate, formatMoney, maskPhone } from '@/utils/format'
import { ORDER_STATUS } from '@/utils/constants'
import type { Order, FinanceSummary, WithdrawalRecord } from '@/types/order'

const emptyFinance: FinanceSummary = {
  total_gmv: 0,
  month_gmv: 0,
  total_platform_fee: 0,
  pending_escrow_amount: 0,
  pending_refund_count: 0,
}

const finance = reactive<FinanceSummary>({ ...emptyFinance })
const activeTab = ref<'orders' | 'withdrawals'>('orders')

const orderFilters = reactive({
  order_no: '',
  status: undefined as number | undefined,
  payment_method: '' as string,
  amount_min: undefined as number | undefined,
  amount_max: undefined as number | undefined,
})
const orderTimeRange = ref<string[]>([])

const {
  loading: ordersLoading,
  tableData: ordersData,
  pagination: ordersPagination,
  loadData: loadOrders,
  handlePageChange: handleOrdersPageChange,
  handleSizeChange: handleOrdersSizeChange,
} = useTable<Order>(getAdminOrders)

const {
  loading: wdLoading,
  tableData: wdData,
  pagination: wdPagination,
  loadData: loadWithdrawals,
  handlePageChange: handleWdPageChange,
  handleSizeChange: handleWdSizeChange,
} = useTable<WithdrawalRecord>(getWithdrawals)

type ElTagType = 'info' | 'primary' | 'success' | 'warning' | 'danger'

function orderTagType(status: number): ElTagType | undefined {
  const t = ORDER_STATUS[status]?.type
  if (t === 'info' || t === 'primary' || t === 'success' || t === 'warning' || t === 'danger') {
    return t
  }
  return undefined
}

function withdrawalTagType(status: number): ElTagType {
  if (status === 1) return 'warning'
  if (status === 2) return 'success'
  return 'info'
}

function withdrawalStatusLabel(status: number) {
  const map: Record<number, string> = {
    0: '待审核',
    1: '处理中',
    2: '已完成',
    3: '已拒绝',
  }
  return map[status] ?? `状态 ${status}`
}

function formatPayee(row: Order) {
  if (!row.payee_id && !row.payee_team_id) return '-'
  const parts: string[] = []
  if (row.payee_id) parts.push(`用户 ${row.payee_id}`)
  if (row.payee_team_id) parts.push(`团队 ${row.payee_team_id}`)
  return parts.join(' / ')
}

function formatPaymentMethod(m: string) {
  if (m === 'wechat') return '微信'
  if (m === 'alipay') return '支付宝'
  return m || '-'
}

function formatFeeRate(rate: number | null | undefined) {
  if (rate == null) return '-'
  const n = Number(rate)
  if (Number.isNaN(n)) return '-'
  const pct = n <= 1 ? n * 100 : n
  return `${pct.toFixed(2)}%`
}

function buildOrderParams() {
  const params: Record<string, any> = {}
  if (orderFilters.order_no.trim()) params.order_no = orderFilters.order_no.trim()
  if (orderFilters.status !== undefined) params.status = orderFilters.status
  if (orderFilters.payment_method) params.payment_method = orderFilters.payment_method
  if (orderFilters.amount_min != null) params.amount_min = orderFilters.amount_min
  if (orderFilters.amount_max != null) params.amount_max = orderFilters.amount_max
  if (orderTimeRange.value?.length === 2) {
    params.start_date = orderTimeRange.value[0]
    params.end_date = orderTimeRange.value[1]
  }
  return params
}

function handleOrderSearch() {
  ordersPagination.page = 1
  loadOrders(buildOrderParams())
}

function resetOrderFilters() {
  orderFilters.order_no = ''
  orderFilters.status = undefined
  orderFilters.payment_method = ''
  orderFilters.amount_min = undefined
  orderFilters.amount_max = undefined
  orderTimeRange.value = []
  handleOrderSearch()
}

async function fetchFinanceSummary() {
  try {
    const res = await getFinanceSummary()
    const d = (res as { data?: Partial<FinanceSummary> }).data
    Object.assign(finance, emptyFinance, d ?? {})
  } catch {
    Object.assign(finance, emptyFinance)
  }
}

function onTabChange(name: string | number) {
  if (name === 'withdrawals') {
    loadWithdrawals({})
  }
}

onMounted(() => {
  fetchFinanceSummary()
  loadOrders(buildOrderParams())
})
</script>

<style scoped>
.order-tabs :deep(.el-tabs__header) {
  margin-bottom: 16px;
}

.amount-range {
  display: flex;
  align-items: center;
  gap: 8px;
}

.amount-input {
  width: 120px;
}

.amount-sep {
  color: #999;
  font-size: 13px;
}
</style>
