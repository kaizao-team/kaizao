package jwt

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

var (
	ErrTokenExpired = errors.New("token has expired")
	ErrTokenInvalid = errors.New("token is invalid")
)

// Claims JWT Claims 结构
type Claims struct {
	UserUUID string `json:"sub"`
	Role     int    `json:"role"`
	Device   string `json:"device"`
	jwt.RegisteredClaims
}

// TokenPair Access + Refresh Token 对
type TokenPair struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int    `json:"expires_in"`
}

// Manager JWT 管理器
type Manager struct {
	secret           []byte
	accessExpireHour int
	refreshExpireDay int
	issuer           string
}

// NewManager 创建 JWT Manager
func NewManager(secret string, accessExpireHour, refreshExpireDay int, issuer string) *Manager {
	return &Manager{
		secret:           []byte(secret),
		accessExpireHour: accessExpireHour,
		refreshExpireDay: refreshExpireDay,
		issuer:           issuer,
	}
}

// GenerateTokenPair 生成 Access + Refresh Token
func (m *Manager) GenerateTokenPair(userUUID string, role int, device string) (*TokenPair, error) {
	now := time.Now()

	// Access Token
	accessClaims := Claims{
		UserUUID: userUUID,
		Role:     role,
		Device:   device,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(now.Add(time.Duration(m.accessExpireHour) * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(now),
			Issuer:    m.issuer,
			ID:        "tk_" + uuid.New().String()[:8],
		},
	}
	accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims)
	accessTokenStr, err := accessToken.SignedString(m.secret)
	if err != nil {
		return nil, err
	}

	// Refresh Token
	refreshClaims := Claims{
		UserUUID: userUUID,
		Role:     role,
		Device:   device,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(now.Add(time.Duration(m.refreshExpireDay) * 24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(now),
			Issuer:    m.issuer,
			ID:        "rt_" + uuid.New().String()[:8],
		},
	}
	refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims)
	refreshTokenStr, err := refreshToken.SignedString(m.secret)
	if err != nil {
		return nil, err
	}

	return &TokenPair{
		AccessToken:  accessTokenStr,
		RefreshToken: refreshTokenStr,
		ExpiresIn:    m.accessExpireHour * 3600,
	}, nil
}

// ParseToken 解析并验证 Token
func (m *Manager) ParseToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		return m.secret, nil
	})
	if err != nil {
		if errors.Is(err, jwt.ErrTokenExpired) {
			return nil, ErrTokenExpired
		}
		return nil, ErrTokenInvalid
	}
	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}
	return nil, ErrTokenInvalid
}
