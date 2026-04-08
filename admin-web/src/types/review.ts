export interface Review {
  uuid: string
  project_id: string | number
  project_title?: string
  reviewer_id?: string
  reviewer_nickname?: string
  reviewer_role?: number
  reviewee_id?: string
  reviewee_nickname?: string
  overall_rating: number
  content?: string
  tags?: string[]
  is_anonymous: boolean
  status: number
  created_at: string
  dimension_ratings?: Record<string, number>
  member_ratings?: any[]
  reply_content?: string
}
