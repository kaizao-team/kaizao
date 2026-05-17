import { serverFetch } from './client'
import { browserFetch } from './browser'
import type { PageResult, Project, Expert } from './types'

export interface MarketQuery {
  page?: number
  size?: number
  domain?: string
  budget_min?: number
  budget_max?: number
  status?: string
}

function buildQuery(q: MarketQuery): string {
  const params = new URLSearchParams()
  Object.entries(q).forEach(([k, v]) => {
    if (v !== undefined && v !== '') params.set(k, String(v))
  })
  const s = params.toString()
  return s ? `?${s}` : ''
}

export function listProjectsServer(q: MarketQuery = {}) {
  return serverFetch<PageResult<Project>>(`/api/v1/market/projects${buildQuery(q)}`)
}

export function listExpertsServer(q: MarketQuery = {}) {
  return serverFetch<PageResult<Expert>>(`/api/v1/market/experts${buildQuery(q)}`)
}

export function listProjectsBrowser(q: MarketQuery = {}) {
  return browserFetch<PageResult<Project>>(`/api/v1/market/projects${buildQuery(q)}`)
}

export function listExpertsBrowser(q: MarketQuery = {}) {
  return browserFetch<PageResult<Expert>>(`/api/v1/market/experts${buildQuery(q)}`)
}
