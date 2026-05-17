import { NextRequest, NextResponse } from 'next/server'
import { getToken } from '@/lib/auth/cookie'

const UPSTREAM = process.env.KAIZAO_SERVER_INTERNAL ?? 'http://localhost:39527'

async function proxy(req: NextRequest, { params }: { params: { path: string[] } }) {
  const path = params.path.join('/')
  const search = req.nextUrl.search
  const url = `${UPSTREAM}/api/${path}${search}`

  const headers = new Headers()
  const token = getToken()
  if (token) headers.set('Authorization', `Bearer ${token}`)
  const ct = req.headers.get('content-type')
  if (ct) headers.set('Content-Type', ct)
  const ua = req.headers.get('user-agent')
  if (ua) headers.set('User-Agent', ua)

  const init: RequestInit = {
    method: req.method,
    headers,
    redirect: 'manual',
  }
  if (!['GET', 'HEAD'].includes(req.method)) {
    init.body = await req.text()
  }

  const upstream = await fetch(url, init)
  const body = await upstream.text()
  const out = new NextResponse(body, { status: upstream.status })
  upstream.headers.forEach((v, k) => {
    if (!['content-encoding', 'transfer-encoding', 'connection'].includes(k.toLowerCase())) {
      out.headers.set(k, v)
    }
  })
  return out
}

export { proxy as GET, proxy as POST, proxy as PUT, proxy as PATCH, proxy as DELETE }
