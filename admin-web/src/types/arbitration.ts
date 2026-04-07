export interface Arbitration {
  uuid: string
  project_id: string
  project_title: string
  order_id: string
  applicant_id: string
  applicant_nickname: string
  respondent_id: string
  respondent_nickname: string
  reason: string
  evidence: any
  status: number
  arbiter_id: string | null
  verdict: string | null
  verdict_type: string | null
  refund_amount: number | null
  arbitrated_at: string | null
  created_at: string
}
