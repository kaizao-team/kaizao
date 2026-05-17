import { serverFetch } from './client'

export interface DemanderHome {
  user: { id: string; name: string; avatar?: string }
  ongoing_projects?: Array<{ id: string; title: string; status: string }>
  drafts?: Array<{ id: string; title: string }>
}

export interface ExpertHome {
  user: { id: string; name: string; avatar?: string }
  rate_level?: string
  ongoing_bids?: Array<{ project_id: string; project_title: string; status: string }>
  available_projects?: Array<{ id: string; title: string }>
}

export function getDemanderHome() {
  return serverFetch<DemanderHome>('/api/v1/home/demander', { auth: true })
}
export function getExpertHome() {
  return serverFetch<ExpertHome>('/api/v1/home/expert', { auth: true })
}
