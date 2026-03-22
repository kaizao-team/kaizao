package service

import (
	"context"
	"crypto/sha256"
	"fmt"
	"math/rand"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/vibebuild/server/internal/config"
	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/errcode"
	jwtpkg "github.com/vibebuild/server/internal/pkg/jwt"
	"github.com/vibebuild/server/internal/repository"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

// Services 所有 Service 的集合
type Services struct {
	Auth    *AuthService
	User    *UserService
	Project *ProjectService
	JWT     *jwtpkg.Manager
}

// NewServices 创建所有 Service
func NewServices(repos *repository.Repositories, rdb *redis.Client, cfg *config.Config, log *zap.Logger) *Services {
	jwtManager := jwtpkg.NewManager(
		cfg.JWT.Secret,
		cfg.JWT.AccessExpireHour,
		cfg.JWT.RefreshExpireDay,
		cfg.JWT.Issuer,
	)

	return &Services{
		Auth:    NewAuthService(repos, rdb, jwtManager, log),
		User:    NewUserService(repos, log),
		Project: NewProjectService(repos, log),
		JWT:     jwtManager,
	}
}

// AuthService 认证服务
type AuthService struct {
	repos      *repository.Repositories
	rdb        *redis.Client
	jwtManager *jwtpkg.Manager
	log        *zap.Logger
}

// NewAuthService 创建认证服务
func NewAuthService(repos *repository.Repositories, rdb *redis.Client, jwtManager *jwtpkg.Manager, log *zap.Logger) *AuthService {
	return &AuthService{
		repos:      repos,
		rdb:        rdb,
		jwtManager: jwtManager,
		log:        log,
	}
}

// hashPhone 生成手机号哈希
func hashPhone(phone string) string {
	h := sha256.Sum256([]byte(phone))
	return fmt.Sprintf("%x", h)
}

// generateSMSCode 生成6位数字验证码
func generateSMSCode() string {
	return fmt.Sprintf("%06d", rand.Intn(1000000))
}

// SendSMSCode 发送短信验证码
func (s *AuthService) SendSMSCode(ctx context.Context, phone string, purpose int) (int, int, error) {
	phoneHash := hashPhone(phone)

	// 检查60秒内是否已发送
	limitKey := fmt.Sprintf("sms:limit:%s:%d", phoneHash, purpose)
	exists, _ := s.rdb.Exists(ctx, limitKey).Result()
	if exists > 0 {
		return 0, 0, fmt.Errorf("发送过于频繁")
	}

	// 注册时检查手机号是否已注册
	if purpose == 1 {
		_, err := s.repos.User.FindByPhoneHash(phoneHash)
		if err == nil {
			return 0, 0, fmt.Errorf("%d", errcode.ErrPhoneAlreadyUsed)
		}
	}

	// 生成验证码
	code := generateSMSCode()
	expireSeconds := 300

	// 存入 Redis
	codeKey := fmt.Sprintf("sms:code:%s:%d", phoneHash, purpose)
	s.rdb.Set(ctx, codeKey, code, time.Duration(expireSeconds)*time.Second)
	s.rdb.Set(ctx, limitKey, "1", 60*time.Second)

	s.log.Info("sms code sent", zap.String("phone_hash", phoneHash[:8]+"..."), zap.Int("purpose", purpose))

	return expireSeconds, 60, nil
}

// VerifySMSCode 验证短信验证码
func (s *AuthService) VerifySMSCode(ctx context.Context, phone string, purpose int, code string) error {
	phoneHash := hashPhone(phone)
	codeKey := fmt.Sprintf("sms:code:%s:%d", phoneHash, purpose)

	storedCode, err := s.rdb.Get(ctx, codeKey).Result()
	if err == redis.Nil {
		return fmt.Errorf("%d", errcode.ErrSMSCodeExpired)
	}
	if err != nil {
		return err
	}
	if storedCode != code {
		return fmt.Errorf("%d", errcode.ErrSMSCodeInvalid)
	}

	// 验证通过后删除
	s.rdb.Del(ctx, codeKey)
	return nil
}

// Register 用户注册
func (s *AuthService) Register(ctx context.Context, phone, smsCode, nickname string, role int, deviceType string) (*model.User, *jwtpkg.TokenPair, error) {
	// 验证短信验证码
	if err := s.VerifySMSCode(ctx, phone, 1, smsCode); err != nil {
		return nil, nil, err
	}

	phoneHash := hashPhone(phone)

	// 检查手机号是否已注册
	_, err := s.repos.User.FindByPhoneHash(phoneHash)
	if err == nil {
		return nil, nil, fmt.Errorf("%d", errcode.ErrPhoneAlreadyUsed)
	}
	if err != gorm.ErrRecordNotFound {
		return nil, nil, err
	}

	// 创建用户
	user := &model.User{
		Phone:       &phone,
		PhoneHash:   &phoneHash,
		Nickname:    nickname,
		Role:        int16(role),
		CreditScore: 500,
		Level:       1,
		Status:      1,
		LastLoginAt: model.NowPtr(),
	}

	if err := s.repos.User.Create(user); err != nil {
		return nil, nil, err
	}

	// 生成 Token
	tokenPair, err := s.jwtManager.GenerateTokenPair(user.UUID, int(user.Role), deviceType)
	if err != nil {
		return nil, nil, err
	}

	return user, tokenPair, nil
}

// Login 手机号登录
func (s *AuthService) Login(ctx context.Context, phone, smsCode, deviceType string) (*model.User, *jwtpkg.TokenPair, error) {
	// 验证短信验证码
	if err := s.VerifySMSCode(ctx, phone, 2, smsCode); err != nil {
		return nil, nil, err
	}

	phoneHash := hashPhone(phone)

	// 查找用户
	user, err := s.repos.User.FindByPhoneHash(phoneHash)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil, fmt.Errorf("%d", errcode.ErrLoginFailed)
		}
		return nil, nil, err
	}

	// 检查账号状态
	if user.Status == 2 {
		return nil, nil, fmt.Errorf("%d", errcode.ErrAccountFrozen)
	}

	// 更新最后登录时间
	now := time.Now()
	user.LastLoginAt = &now
	s.repos.User.Update(user)

	// 生成 Token
	tokenPair, err := s.jwtManager.GenerateTokenPair(user.UUID, int(user.Role), deviceType)
	if err != nil {
		return nil, nil, err
	}

	return user, tokenPair, nil
}

// RefreshToken 刷新 Token
func (s *AuthService) RefreshToken(ctx context.Context, refreshToken string) (*jwtpkg.TokenPair, error) {
	claims, err := s.jwtManager.ParseToken(refreshToken)
	if err != nil {
		if err == jwtpkg.ErrTokenExpired {
			return nil, fmt.Errorf("%d", errcode.ErrRefreshTokenExpired)
		}
		return nil, fmt.Errorf("%d", errcode.ErrTokenInvalid)
	}

	// 检查 Refresh Token 是否在黑名单中
	blacklistKey := fmt.Sprintf("token:blacklist:%s", claims.ID)
	exists, _ := s.rdb.Exists(ctx, blacklistKey).Result()
	if exists > 0 {
		return nil, fmt.Errorf("%d", errcode.ErrRefreshTokenExpired)
	}

	// 将旧 Refresh Token 加入黑名单
	s.rdb.Set(ctx, blacklistKey, "1", 30*24*time.Hour)

	// 生成新 Token 对
	return s.jwtManager.GenerateTokenPair(claims.UserUUID, claims.Role, claims.Device)
}
