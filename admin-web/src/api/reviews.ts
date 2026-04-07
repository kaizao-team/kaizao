import request from './request'

export function getAdminReviews(params: Record<string, any>) {
  return request.get('/admin/reviews', { params })
}

export function updateReviewStatus(uuid: string, data: { status: number }) {
  return request.put(`/admin/reviews/${uuid}/status`, data)
}
