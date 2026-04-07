export interface Order {
  order_no: string
  project_id: string
  project_title: string
  milestone_id: string | null
  payer_id: string
  payer_nickname: string
  payee_id: string | null
  payee_team_id: string | null
  amount: number
  platform_fee_rate: number
  platform_fee: number
  actual_amount: number
  payment_method: string
  status: number
  created_at: string
  paid_at: string | null
}

export interface FinanceSummary {
  total_gmv: number
  month_gmv: number
  total_platform_fee: number
  pending_escrow_amount: number
  pending_refund_count: number
}

export interface WithdrawalRecord {
  uuid: string
  user_id: string
  user_nickname: string
  amount: number
  withdraw_method: string
  withdraw_account: string
  status: number
  created_at: string
}
