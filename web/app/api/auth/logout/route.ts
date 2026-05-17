import { NextResponse } from 'next/server'
import { clearToken, getToken } from '@/lib/auth/cookie'

const UPSTREAM = process.env.KAIZAO_SERVER_INTERNAL ?? 'http://localhost:39527'

export async function POST() {
  const token = getToken()
  if (token) {
    await fetch(`${UPSTREAM}/api/v1/auth/logout`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
    }).catch(() => {})
  }
  clearToken()
  return NextResponse.json({ code: 0, data: { ok: true } })
}
