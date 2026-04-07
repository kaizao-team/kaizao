export interface Report {
  uuid: string
  reporter_id: string
  reporter_nickname: string
  target_type: string
  target_id: string
  reason_type: string
  reason_detail: string
  evidence: any
  status: number
  handler_id: string | null
  handle_result: string | null
  created_at: string
}
