import request from './request'

export interface LoginParams {
  phone: string
  password: string
  encrypted_password?: string
}

export interface LoginResponse {
  access_token: string
  refresh_token: string
  user: {
    uuid: string
    nickname: string
    avatar_url: string | null
    role: number
  }
}

export function loginByPassword(data: LoginParams) {
  return request.post('/auth/login-password', data)
}

export function getPasswordKey() {
  return request.get('/auth/password-key')
}
