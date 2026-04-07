import request from './request'

export function getAdminOrders(params: Record<string, any>) {
  return request.get('/admin/orders', { params })
}

export function getOrderDetail(id: string) {
  return request.get(`/admin/orders/${id}`)
}

export function getFinanceSummary() {
  return request.get('/admin/finance/summary')
}

export function getWithdrawals(params: Record<string, any>) {
  return request.get('/admin/withdrawals', { params })
}
