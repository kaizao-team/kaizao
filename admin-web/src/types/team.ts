export interface Team {
  id: string
  team_name: string
  project_name: string
  description: string | null
  avatar_url: string | null
  vibe_level: string
  vibe_power: number
  avg_rating: number
  member_count: number
  total_projects: number
  status: string
  leader_uuid: string
  nickname: string
  leader_avatar_url: string | null
  completed_projects: number
  tagline: string | null
  skills: string[]
  created_at: string
  hourly_rate: number | null
  budget_min: number | null
  budget_max: number | null
  available_status: number
  experience_years: number
  resume_summary: string | null
  members: TeamMember[]
}

export interface TeamMember {
  id: number
  user_id: string
  nickname: string
  avatar_url: string | null
  role: string
  ratio: number
  is_leader: boolean
  status: string
}
