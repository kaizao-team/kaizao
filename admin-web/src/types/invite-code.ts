export interface InviteCode {
  uuid: string
  team_id: number
  code_hint: string
  code_plain: string
  note: string
  max_uses: number
  used_count: number
  expires_at: string | null
  allowed_roles: number[]
  disabled_at: string | null
  created_at: string
}

export interface CreateInviteCodeParams {
  count: number
  note?: string
  expires_at?: string
}
