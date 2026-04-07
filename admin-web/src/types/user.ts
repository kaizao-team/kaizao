export interface User {
  uuid: string
  nickname: string
  avatar_url: string | null
  role: number
  phone: string
  onboarding_status: number
  credit_score: number
  level: number
  completed_orders: number
  status: number
  created_at: string
  last_login_at: string | null
  onboarding_submitted_at: string | null
  onboarding_reviewed_at: string | null
  onboarding_application_note: string | null
  resume_url: string | null
}

export interface UpdateOnboardingParams {
  status: 'approved' | 'rejected'
  reason?: string
}
