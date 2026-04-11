import request from './request'

export function getTeams(params: Record<string, any>) {
  return request.get('/teams', { params })
}

export function getTeamDetail(uuid: string) {
  return request.get(`/teams/${uuid}`)
}

export function getTeamStaticAssets(uuid: string, params?: Record<string, any>) {
  return request.get(`/teams/${uuid}/static-assets`, { params })
}

export function getTeamCurrentInviteCode(uuid: string) {
  return request.get(`/admin/teams/${uuid}/current-invite-code`)
}

export function updateTeam(uuid: string, data: Record<string, any>) {
  return request.put(`/admin/teams/${uuid}`, data)
}

export function createInviteCodeForTeam(teamUuid: string, note?: string, expiresAt?: string) {
  return request.post('/admin/invite-codes', {
    team_uuid: teamUuid,
    note,
    expires_at: expiresAt,
  })
}
