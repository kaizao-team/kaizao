import 'server-only'
import { getToken } from '@/lib/auth/cookie'
import { ApiError, type ApiEnvelope } from './types'

const BASE = process.env.KAIZAO_SERVER_INTERNAL ?? 'http://localhost:39527'

export async function serverFetch<T>(
  path: string,
  init: RequestInit & { auth?: boolean } = {}
): Promise<T> {
  const { auth = false, headers, ...rest } = init
  const h = new Headers(headers)
  if (auth) {
    const token = getToken()
    if (token) h.set('Authorization', `Bearer ${token}`)
  }
  h.set('Content-Type', 'application/json')

  const res = await fetch(`${BASE}${path}`, {
    ...rest,
    headers: h,
    cache: 'no-store',
  })
  const json = (await res.json()) as ApiEnvelope<T>
  if (!res.ok || (json.code !== undefined && json.code !== 0)) {
    throw new ApiError(res.status, json.code ?? res.status, json.message ?? 'request failed')
  }
  return json.data
}
