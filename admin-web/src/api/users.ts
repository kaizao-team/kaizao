import request from './request'
import type { UpdateOnboardingParams } from '@/types/user'

export function getUsers(params: Record<string, any>) {
  return request.get('/admin/users', { params })
}

export function getUserDetail(uuid: string) {
  return request.get(`/admin/users/${uuid}`)
}

export function getUserSkills(uuid: string) {
  return request.get(`/admin/users/${uuid}/skills`)
}

export function getUserPortfolios(uuid: string) {
  return request.get(`/admin/users/${uuid}/portfolios`)
}

export function updateUserOnboarding(uuid: string, data: UpdateOnboardingParams) {
  return request.put(`/admin/users/${uuid}/onboarding`, data)
}

export function updateUserStatus(uuid: string, data: { status: number; reason?: string }) {
  return request.put(`/admin/users/${uuid}/status`, data)
}
