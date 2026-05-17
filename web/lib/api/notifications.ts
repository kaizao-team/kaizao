import { serverFetch } from './client'
import type { PageResult } from './types'

export interface Notification {
  id: string
  type: string
  title: string
  body?: string
  read: boolean
  created_at: string
}

export function listNotifications(q: { page?: number; size?: number } = {}) {
  const params = new URLSearchParams()
  if (q.page) params.set('page', String(q.page))
  if (q.size) params.set('size', String(q.size))
  return serverFetch<PageResult<Notification>>(`/api/v1/notifications?${params.toString()}`, { auth: true })
}
