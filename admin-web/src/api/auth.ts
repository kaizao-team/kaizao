import request from './request'

export interface PasswordKeyResponse {
  key_id: string
  algorithm: string
  public_key_pem: string
  public_key_spki_pem?: string
}

export interface CaptchaResponse {
  captcha_id: string
  image_base64: string
  expires_in: number
}

export interface LoginByPasswordParams {
  login_type: 'phone' | 'username'
  identity: string
  password_cipher: string
  captcha_id: string
  captcha_code: string
  device_type?: string
}

export interface LoginResponse {
  access_token: string
  refresh_token: string
  user_id: string
  role: number
  is_new_user: boolean
}

export function loginByPassword(data: LoginByPasswordParams) {
  return request.post('/auth/login-password', data)
}

export function getPasswordKey() {
  return request.get<PasswordKeyResponse>('/auth/password-key')
}

export function getCaptcha() {
  return request.get<CaptchaResponse>('/auth/captcha')
}
