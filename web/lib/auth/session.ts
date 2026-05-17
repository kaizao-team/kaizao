import 'server-only'
import { cookies } from 'next/headers'
import { ROLE_COOKIE, TOKEN_COOKIE } from './cookie'

export interface ServerSession {
  isLoggedIn: boolean
  role?: 1 | 2
}

export function getServerSession(): ServerSession {
  const store = cookies()
  const token = store.get(TOKEN_COOKIE)?.value
  const roleStr = store.get(ROLE_COOKIE)?.value
  if (!token) return { isLoggedIn: false }
  const parsed = roleStr ? Number(roleStr) : NaN
  const role = parsed === 1 || parsed === 2 ? (parsed as 1 | 2) : undefined
  return { isLoggedIn: true, role }
}
