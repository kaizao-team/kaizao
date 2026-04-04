package dto

// SendSMSCodeReq 发送短信验证码请求
type SendSMSCodeReq struct {
	Phone   string `json:"phone" binding:"required,len=11"`
	Purpose int    `json:"purpose" binding:"required,oneof=1 2 3"`
}

// SendSMSCodeResp 发送短信验证码响应
type SendSMSCodeResp struct {
	ExpireSeconds     int `json:"expire_seconds"`
	RetryAfterSeconds int `json:"retry_after_seconds"`
}

// RegisterReq 注册请求
type RegisterReq struct {
	Phone      string `json:"phone" binding:"required,len=11"`
	SMSCode    string `json:"sms_code" binding:"required,len=6"`
	Nickname   string `json:"nickname" binding:"required,min=2,max=20"`
	Role       int    `json:"role" binding:"omitempty,oneof=0 1 2 3"`
	InviteCode string `json:"invite_code" binding:"omitempty"`
}

// LoginReq 登录请求（phone + code，不存在则自动注册）
type LoginReq struct {
	Phone      string `json:"phone" binding:"required,len=11"`
	Code       string `json:"code" binding:"required,len=6"`
	DeviceType string `json:"device_type" binding:"omitempty,oneof=android ios web"`
	DeviceID   string `json:"device_id" binding:"omitempty"`
}

// WechatLoginReq 微信登录请求
type WechatLoginReq struct {
	Code       string `json:"code" binding:"required"`
	DeviceType string `json:"device_type" binding:"omitempty,oneof=android ios web"`
}

// RefreshTokenReq 刷新 Token 请求
type RefreshTokenReq struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// AuthResp 认证响应（登录/注册通用）
type AuthResp struct {
	User         UserBriefResp `json:"user"`
	AccessToken  string        `json:"access_token"`
	RefreshToken string        `json:"refresh_token"`
	ExpiresIn    int           `json:"expires_in"`
}

// UserBriefResp 用户简要信息
type UserBriefResp struct {
	UUID        string  `json:"uuid"`
	Nickname    string  `json:"nickname"`
	AvatarURL   *string `json:"avatar_url"`
	Role        int16   `json:"role"`
	Level       int16   `json:"level"`
	CreditScore int     `json:"credit_score"`
	IsVerified  bool    `json:"is_verified"`
}

// TokenResp Token 响应
type TokenResp struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int    `json:"expires_in"`
}

// PasswordKeyResp GET /auth/password-key
type PasswordKeyResp struct {
	KeyID         string `json:"key_id"`
	Algorithm     string `json:"algorithm"`
	PublicKeyPEM  string `json:"public_key_pem"`
}

// CaptchaResp GET /auth/captcha
type CaptchaResp struct {
	CaptchaID   string `json:"captcha_id"`
	ImageBase64 string `json:"image_base64"`
	ExpiresIn   int    `json:"expires_in"`
}

// RegisterByPasswordReq POST /auth/register-password（禁止 JSON 根字段 password）
type RegisterByPasswordReq struct {
	Username       string  `json:"username" binding:"required,min=4,max=32"`
	PasswordCipher string  `json:"password_cipher" binding:"required"`
	Nickname       *string `json:"nickname" binding:"omitempty,min=2,max=20"`
	Role           int     `json:"role" binding:"oneof=0 1 2 3"`
	Phone          *string `json:"phone"`
	SMSCode        *string `json:"sms_code"`
	InviteCode     string  `json:"invite_code" binding:"omitempty"`
}

// LoginByPasswordReq POST /auth/login-password
type LoginByPasswordReq struct {
	LoginType      string `json:"login_type" binding:"required,oneof=username phone"`
	Identity       string `json:"identity" binding:"required,min=1,max=64"`
	PasswordCipher string `json:"password_cipher" binding:"required"`
	CaptchaID      string `json:"captcha_id" binding:"required"`
	CaptchaCode    string `json:"captcha_code" binding:"required"`
	DeviceType     string `json:"device_type" binding:"omitempty,oneof=android ios web"`
}
