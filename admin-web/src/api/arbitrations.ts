import request from './request'

export function getArbitrations(params: Record<string, any>) {
  return request.get('/admin/arbitrations', { params })
}

export function handleArbitration(
  uuid: string,
  data: {
    verdict: string
    verdict_type: string
    refund_amount?: number
  },
) {
  return request.put(`/admin/arbitrations/${uuid}`, data)
}
