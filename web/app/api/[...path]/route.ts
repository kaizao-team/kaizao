import { NextRequest, NextResponse } from 'next/server'
import { getToken } from '@/lib/auth/cookie'

const UPSTREAM = process.env.KAIZAO_SERVER_INTERNAL ?? 'http://localhost:39527'

const HOP_BY_HOP = new Set([
  'content-encoding',
  'transfer-encoding',
  'connection',
  'keep-alive',
  'te',
  'trailer',
  'upgrade',
  'proxy-authenticate',
  'proxy-authorization',
])

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
  const accept = req.headers.get('accept')
  if (accept) headers.set('Accept', accept)
  const acceptLang = req.headers.get('accept-language')
  if (acceptLang) headers.set('Accept-Language', acceptLang)

  const init: RequestInit = {
    method: req.method,
    headers,
    redirect: 'manual',
  }
  if (!['GET', 'HEAD'].includes(req.method)) {
    init.body = await req.text()
  }

  let upstream: Response
  try {
    upstream = await fetch(url, init)
  } catch (err) {
    return NextResponse.json(
      { code: 503, message: '上游服务暂不可用' },
      { status: 503 },
    )
  }

  const body = await upstream.text()
  const out = new NextResponse(body, { status: upstream.status })
  upstream.headers.forEach((v, k) => {
    if (!HOP_BY_HOP.has(k.toLowerCase())) {
      out.headers.set(k, v)
    }
  })
  return out
}

export { proxy as GET, proxy as POST, proxy as PUT, proxy as PATCH, proxy as DELETE }
