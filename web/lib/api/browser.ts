import { ApiError, type ApiEnvelope } from './types'

export async function browserFetch<T>(path: string, init: RequestInit = {}): Promise<T> {
  const res = await fetch(path, {
    ...init,
    headers: { 'Content-Type': 'application/json', ...(init.headers ?? {}) },
    credentials: 'include',
  })
  let json: ApiEnvelope<T>
  try {
    json = (await res.json()) as ApiEnvelope<T>
  } catch {
    throw new ApiError(res.status, -1, '响应格式异常')
  }
  if (!res.ok || (json.code !== undefined && json.code !== 0)) {
    throw new ApiError(res.status, json.code ?? res.status, json.message ?? '请求失败')
  }
  return json.data
}
