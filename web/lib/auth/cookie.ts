import { cookies } from 'next/headers'

export const TOKEN_COOKIE = 'kz_token'
export const ROLE_COOKIE = 'kz_role'

export function getToken(): string | undefined {
  return cookies().get(TOKEN_COOKIE)?.value
}

export function setToken(token: string, maxAgeSec = 60 * 60 * 24 * 7) {
  cookies().set(TOKEN_COOKIE, token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: maxAgeSec,
    path: '/',
  })
}

export function clearToken() {
  cookies().delete(TOKEN_COOKIE)
  cookies().delete(ROLE_COOKIE)
}

export function setRole(role: number) {
  cookies().set(ROLE_COOKIE, String(role), {
    httpOnly: false,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 60 * 60 * 24 * 7,
    path: '/',
  })
}
