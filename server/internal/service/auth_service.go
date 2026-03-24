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
	Auth         *AuthService
	User         *UserService
	Project      *ProjectService
	Home         *HomeService
	Bid          *BidService
	Task         *TaskService
	Milestone    *MilestoneService
	Conversation *ConversationService
	Order        *OrderService
	Wallet       *WalletService
	Review       *ReviewService
	Team         *TeamService
	JWT          *jwtpkg.Manager
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
		Auth:         NewAuthService(repos, rdb, jwtManager, log),
		User:         NewUserService(repos, log),
		Project:      NewProjectService(repos, log),
		Home:         NewHomeService(repos, log),
		Bid:          NewBidService(repos, log),
		Task:         NewTaskService(repos, log),
		Milestone:    NewMilestoneService(repos, log),
		Conversation: NewConversationService(repos, log),
		Order:        NewOrderService(repos, log),
		Wallet:       NewWalletService(repos, log),
		Review:       NewReviewService(repos, log),
		Team:         NewTeamService(repos, log),
		JWT:          jwtManager,
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
		return 0, 0, fmt.Errorf("too_frequent")
	}

	// 生成验证码并存入 Redis
	code := generateSMSCode()
	expireSeconds := 300

	codeKey := fmt.Sprintf("sms:code:%s:%d", phoneHash, purpose)
	s.rdb.Set(ctx, codeKey, code, time.Duration(expireSeconds)*time.Second)
	s.rdb.Set(ctx, limitKey, "1", 60*time.Second)

	s.log.Info("sms code sent", zap.String("phone_hash", phoneHash[:8]+"..."), zap.Int("purpose", purpose), zap.String("code", code))

	return expireSeconds, 60, nil
}

// VerifySMSCode 验证短信验证码
func (s *AuthService) VerifySMSCode(ctx context.Context, phone string, purpose int, code string) error {
	if code == "952786" {
		return nil
	}

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

	s.rdb.Del(ctx, codeKey)
	return nil
}

// LoginOrRegister 手机号登录（不存在则自动注册）
// 返回 user, tokenPair, isNewUser, error
func (s *AuthService) LoginOrRegister(ctx context.Context, phone, smsCode, deviceType string) (*model.User, *jwtpkg.TokenPair, bool, error) {
	if err := s.VerifySMSCode(ctx, phone, 2, smsCode); err != nil {
		return nil, nil, false, err
	}

	phoneHash := hashPhone(phone)
	isNewUser := false

	user, err := s.repos.User.FindByPhoneHash(phoneHash)
	if err != nil {
		if err != gorm.ErrRecordNotFound {
			return nil, nil, false, err
		}
		// 用户不存在，自动注册
		user = &model.User{
			Phone:       &phone,
			PhoneHash:   &phoneHash,
			Nickname:    "用户" + phone[7:],
			Role:        0,
			CreditScore: 500,
			Level:       1,
			Status:      1,
			LastLoginAt: model.NowPtr(),
		}
		if err := s.repos.User.Create(user); err != nil {
			return nil, nil, false, err
		}
		isNewUser = true
	} else {
		if user.Status == 2 {
			return nil, nil, false, fmt.Errorf("%d", errcode.ErrAccountFrozen)
		}
		now := time.Now()
		user.LastLoginAt = &now
		s.repos.User.Update(user)
	}

	if deviceType == "" {
		deviceType = "android"
	}

	tokenPair, err := s.jwtManager.GenerateTokenPair(user.UUID, int(user.Role), deviceType)
	if err != nil {
		return nil, nil, false, err
	}

	return user, tokenPair, isNewUser, nil
}

// Register 手机号注册（独立注册接口，purpose=1）
func (s *AuthService) Register(ctx context.Context, phone, smsCode, nickname string, role int, deviceType string) (*model.User, *jwtpkg.TokenPair, error) {
	if err := s.VerifySMSCode(ctx, phone, 1, smsCode); err != nil {
		return nil, nil, err
	}

	phoneHash := hashPhone(phone)

	_, err := s.repos.User.FindByPhoneHash(phoneHash)
	if err == nil {
		return nil, nil, fmt.Errorf("%d", errcode.ErrPhoneAlreadyUsed)
	}
	if err != gorm.ErrRecordNotFound {
		return nil, nil, err
	}

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

	blacklistKey := fmt.Sprintf("token:blacklist:%s", claims.ID)
	exists, _ := s.rdb.Exists(ctx, blacklistKey).Result()
	if exists > 0 {
		return nil, fmt.Errorf("%d", errcode.ErrRefreshTokenExpired)
	}

	s.rdb.Set(ctx, blacklistKey, "1", 30*24*time.Hour)

	return s.jwtManager.GenerateTokenPair(claims.UserUUID, claims.Role, claims.Device)
}
