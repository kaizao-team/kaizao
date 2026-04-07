import request from './request'

export function getReports(params: Record<string, any>) {
  return request.get('/admin/reports', { params })
}

export function handleReport(uuid: string, data: { handle_result: string; action?: string }) {
  return request.put(`/admin/reports/${uuid}`, data)
}
