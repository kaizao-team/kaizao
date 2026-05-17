export interface ApiEnvelope<T> {
  code: number
  message?: string
  data: T
}

export interface PageResult<T> {
  list: T[]
  total: number
  page: number
  size: number
}

export interface User {
  id: string
  name: string
  avatar?: string
  role: 1 | 2
  credit_score?: number
}

export interface Project {
  id: string
  title: string
  description: string
  budget_cents?: number
  deadline?: string
  domain?: string
  tags?: string[]
  status: string
  created_at: string
  owner: Pick<User, 'id' | 'name' | 'avatar'>
}

export interface Expert extends User {
  skills?: string[]
  rate_level?: string
  bid_count?: number
}

export class ApiError extends Error {
  constructor(public status: number, public code: number, message: string) {
    super(message)
  }
}
