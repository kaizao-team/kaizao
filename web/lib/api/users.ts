import { serverFetch } from './client'
import { browserFetch } from './browser'
import type { User } from './types'

export interface UserPublic extends User {
  skills?: string[]
  portfolios?: Array<{ id: string; title: string; cover?: string }>
  reviews?: Array<{ id: string; score: number; content: string; created_at: string }>
}

export function getUserServer(id: string) {
  return serverFetch<UserPublic>(`/api/v1/users/${id}`)
}

export function getUserSkillsServer(id: string) {
  return serverFetch<string[]>(`/api/v1/users/${id}/skills`)
}

export function getUserPortfoliosServer(id: string) {
  return serverFetch<UserPublic['portfolios']>(`/api/v1/users/${id}/portfolios`)
}

export function getUserReviewsServer(id: string) {
  return serverFetch<UserPublic['reviews']>(`/api/v1/users/${id}/reviews`)
}

export function getMeBrowser() {
  return browserFetch<User>('/api/v1/users/me')
}

export function getMeServer() {
  return serverFetch<User>('/api/v1/users/me', { auth: true })
}
