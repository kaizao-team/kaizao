export interface Project {
  uuid: string
  title: string
  owner_id: string
  owner_nickname: string
  owner_avatar: string | null
  provider_id: string | null
  team_id: string | null
  category: string
  budget_min: number | null
  budget_max: number | null
  agreed_price: number | null
  status: number
  bid_count: number
  view_count: number
  published_at: string | null
  created_at: string
}

export interface ProjectFile {
  uuid: string
  file_name: string
  file_size: number
  file_type: string
  uploaded_by: string
  created_at: string
  download_url: string
}
