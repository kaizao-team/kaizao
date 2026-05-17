import { serverFetch } from './client'
import type { Project, PageResult } from './types'

export interface ProjectDetail extends Project {
  prd_cards?: Array<{ id: string; title: string; content: string }>
  overview?: { budget_cents?: number; deadline?: string; tech_stack?: string[]; phases?: string[] }
}

export function getProjectServer(id: string) {
  return serverFetch<ProjectDetail>(`/api/v1/projects/${id}`)
}

export function getProjectPrdServer(id: string) {
  return serverFetch<Array<{ id: string; title: string; content: string }>>(`/api/v1/projects/${id}/prd`)
}

export function getProjectOverviewServer(id: string) {
  return serverFetch<ProjectDetail['overview']>(`/api/v1/projects/${id}/overview`)
}

export function listMyProjects(q: { page?: number; size?: number } = {}) {
  const params = new URLSearchParams()
  if (q.page) params.set('page', String(q.page))
  if (q.size) params.set('size', String(q.size))
  params.set('owner', 'me')
  return serverFetch<PageResult<Project>>(`/api/v1/projects?${params.toString()}`, { auth: true })
}
