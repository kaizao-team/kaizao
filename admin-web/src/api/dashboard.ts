import request from './request'
import type { ApiResponse } from '@/types/api'

export function getDashboard(): Promise<ApiResponse<unknown>> {
  return request.get('/admin/dashboard') as Promise<ApiResponse<unknown>>
}
