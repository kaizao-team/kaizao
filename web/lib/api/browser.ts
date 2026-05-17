import { ApiError, type ApiEnvelope } from './types'

export async function browserFetch<T>(path: string, init: RequestInit = {}): Promise<T> {
  const res = await fetch(path, {
    ...init,
    headers: { 'Content-Type': 'application/json', ...(init.headers ?? {}) },
    credentials: 'include',
  })
  const json = (await res.json()) as ApiEnvelope<T>
  if (!res.ok || (json.code !== undefined && json.code !== 0)) {
    throw new ApiError(res.status, json.code ?? res.status, json.message ?? '请求失败')
  }
  return json.data
}
