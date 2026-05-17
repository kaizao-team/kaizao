import { NextRequest, NextResponse } from 'next/server'
import { setRole, setToken } from '@/lib/auth/cookie'

const UPSTREAM = process.env.KAIZAO_SERVER_INTERNAL ?? 'http://localhost:39527'

export async function POST(req: NextRequest) {
  const body = await req.text()
  const upstream = await fetch(`${UPSTREAM}/api/v1/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body,
  })
  const json = await upstream.json()
  if (upstream.ok && json.code === 0 && json.data?.token) {
    setToken(json.data.token)
    if (json.data.user?.role) setRole(json.data.user.role)
  }
  return NextResponse.json(json, { status: upstream.status })
}
