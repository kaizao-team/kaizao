export interface ApiResponse<T = any> {
  code: number
  message: string
  data: T
  request_id?: string
}

export interface PaginatedMeta {
  page: number
  page_size: number
  total: number
  total_pages: number
}

export interface PaginatedResponse<T> {
  code: number
  message: string
  data: T[]
  meta: PaginatedMeta
  request_id?: string
}

export interface PaginationParams {
  page?: number
  page_size?: number
}
