import request from './request'
import type { CreateInviteCodeParams } from '@/types/invite-code'
export { getTeamCurrentInviteCode } from './teams'

export function getInviteCodes(params: Record<string, any>) {
  return request.get('/admin/invite-codes', { params })
}

export function createInviteCode(data: CreateInviteCodeParams) {
  return request.post('/admin/invite-codes', data)
}
