import { browserFetch } from './browser'

export interface SmsCodeReq { mobile: string; scene?: string }
export interface LoginReq { mobile: string; sms_code: string }
export interface RegisterReq { mobile: string; sms_code: string; role: 1 | 2 }
export interface LoginPasswordReq { mobile: string; password: string }

export interface AuthResult { token: string; user: { id: string; role: 1 | 2; name?: string } }

export function sendSmsCode(req: SmsCodeReq) {
  return browserFetch<{ ok: boolean }>('/api/v1/auth/sms-code', {
    method: 'POST', body: JSON.stringify(req),
  })
}

export function login(req: LoginReq) {
  return browserFetch<AuthResult>('/api/auth/login', {
    method: 'POST', body: JSON.stringify(req),
  })
}

export function loginPassword(req: LoginPasswordReq) {
  return browserFetch<AuthResult>('/api/v1/auth/login-password', {
    method: 'POST', body: JSON.stringify(req),
  })
}

export function register(req: RegisterReq) {
  return browserFetch<AuthResult>('/api/auth/register', {
    method: 'POST', body: JSON.stringify(req),
  })
}

export function logout() {
  return browserFetch<{ ok: boolean }>('/api/auth/logout', { method: 'POST' })
}
