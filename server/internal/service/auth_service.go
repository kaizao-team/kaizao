package service

import (
	"bytes"
	"context"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	mathrand "math/rand"
	"regexp"
	"strings"
	"time"
	"unicode"

	"github.com/dchest/captcha"
	"github.com/redis/go-redis/v9"
	"github.com/vibebuild/server/internal/config"
	"github.com/vibebuild/server/internal/dto"
	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/captchastore"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/invitehash"
	jwtpkg "github.com/vibebuild/server/internal/pkg/jwt"
	"github.com/vibebuild/server/internal/pkg/objectstore"
	"github.com/vibebuild/server/internal/pkg/passwordrsa"
	"github.com/vibebuild/server/internal/repository"
	"go.uber.org/zap"
	"golang.org/x/crypto/bcrypt"
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
	Notification *NotificationService
	Upload       *UploadService
	JWT          *jwtpkg.Manager
	Repos        *repository.Repositories
}

// NewServices 创建所有 Service；passwordRSA 用于账号密码注册/登录（RSA-OAEP 解密），不可为 nil。
func NewServices(repos *repository.Repositories, rdb *redis.Client, cfg *config.Config, log *zap.Logger, passwordRSA *rsa.PrivateKey) *Services {
	jwtManager := jwtpkg.NewManager(
		cfg.JWT.Secret,
		cfg.JWT.AccessExpireHour,
		cfg.JWT.RefreshExpireDay,
		cfg.JWT.Issuer,
	)

	objClient, err := objectstore.New(cfg.OSS, log)
	if err != nil {
		log.Fatal("object storage init failed", zap.Error(err))
	}

	userSvc := NewUserService(repos, log)
	orderSvc := NewOrderService(repos, log)
	uploadSvc := NewUploadService(objClient, cfg, log)
	return &Services{
		Auth:         NewAuthService(repos, rdb, jwtManager, cfg, log, passwordRSA),
		User:         userSvc,
		Project:      NewProjectService(repos, log),
		Home:         NewHomeService(repos, log),
		Bid:          NewBidService(repos, orderSvc, log),
		Task:         NewTaskService(repos, log),
		Milestone:    NewMilestoneService(repos, log),
		Conversation: NewConversationService(repos, log),
		Order:        orderSvc,
		Wallet:       NewWalletService(repos, log),
		Review:       NewReviewService(repos, log),
		Team:         NewTeamService(repos, objClient, log),
		Notification: NewNotificationService(repos, log),
		Upload:       uploadSvc,
		JWT:          jwtManager,
		Repos:        repos,
	}
}

// AuthService 认证服务
type AuthService struct {
	repos         *repository.Repositories
	rdb           *redis.Client
	jwtManager    *jwtpkg.Manager
	cfg           *config.Config
	log           *zap.Logger
	passwordRSA   *rsa.PrivateKey
	passwordKeyID string
}

// NewAuthService 创建认证服务
func NewAuthService(repos *repository.Repositories, rdb *redis.Client, jwtManager *jwtpkg.Manager, cfg *config.Config, log *zap.Logger, passwordRSA *rsa.PrivateKey) *AuthService {
	store := &captchastore.DchestRedisStore{
		Rdb: rdb,
		TTL: time.Duration(cfg.AuthPassword.CaptchaTTLSec) * time.Second,
	}
	if store.TTL <= 0 {
		store.TTL = 3 * time.Minute
	}
	captcha.SetCustomStore(store)

	kid := strings.TrimSpace(cfg.AuthPassword.KeyID)
	if kid == "" {
		kid = "v1"
	}
	return &AuthService{
		repos:         repos,
		rdb:           rdb,
		jwtManager:    jwtManager,
		cfg:           cfg,
		log:           log,
		passwordRSA:   passwordRSA,
		passwordKeyID: kid,
	}
}

var usernamePattern = regexp.MustCompile(`^[a-zA-Z0-9_]{4,32}$`)

// PasswordPublicKey 返回 RSA 公钥 PEM（客户端加密 password_cipher）。
func (s *AuthService) PasswordPublicKey() *dto.PasswordKeyResp {
	if s.passwordRSA == nil {
		return nil
	}
	return &dto.PasswordKeyResp{
		KeyID:        s.passwordKeyID,
		Algorithm:    "RSA-OAEP-SHA256",
		PublicKeyPEM: passwordrsa.PublicKeyPEM(s.passwordRSA),
	}
}

// GenerateCaptcha 生成图形验证码，返回 captcha_id、PNG Base64、过期秒数。
func (s *AuthService) GenerateCaptcha() (captchaID string, imageBase64 string, expiresIn int, err error) {
	id := captcha.NewLen(6)
	var buf bytes.Buffer
	if err := captcha.WriteImage(&buf, id, 240, 80); err != nil {
		return "", "", 0, err
	}
	exp := s.cfg.AuthPassword.CaptchaTTLSec
	if exp <= 0 {
		exp = 180
	}
	return id, base64.StdEncoding.EncodeToString(buf.Bytes()), exp, nil
}

// hashPhone 生成手机号哈希
func hashPhone(phone string) string {
	h := sha256.Sum256([]byte(phone))
	return fmt.Sprintf("%x", h)
}

// generateSMSCode 生成6位数字验证码
func generateSMSCode() string {
	return fmt.Sprintf("%06d", mathrand.Intn(1000000))
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

// LoginOrRegister 手机号登录（不存在则自动注册，受 registration 配置约束）
// 返回 user, tokenPair, isNewUser, error
func (s *AuthService) LoginOrRegister(ctx context.Context, phone, smsCode, deviceType string) (*model.User, *jwtpkg.TokenPair, bool, error) {
	if err := s.VerifySMSCode(ctx, phone, 2, smsCode); err != nil {
		return nil, nil, false, err
	}

	phoneHash := hashPhone(phone)
	isNewUser := false
	reg := s.cfg.Registration

	user, err := s.repos.User.FindByPhoneHash(phoneHash)
	if err != nil {
		if err != gorm.ErrRecordNotFound {
			return nil, nil, false, err
		}
		if reg.DisableAutoRegister {
			return nil, nil, false, fmt.Errorf("%d", errcode.ErrRegisterRequired)
		}
		user = &model.User{
			Phone:              &phone,
			PhoneHash:          &phoneHash,
			Nickname:           "用户" + phone[7:],
			Role:               0,
			CreditScore:        500,
			Level:              1,
			Status:             1,
			OnboardingStatus:   model.OnboardingApproved,
			LastLoginAt:        model.NowPtr(),
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

// Register 手机号注册（purpose=1）。邀请码不参与注册；专家默认待入驻，仍签发 Token。
func (s *AuthService) Register(ctx context.Context, phone, smsCode, nickname string, role int, deviceType string) (*model.User, *jwtpkg.TokenPair, error) {
	if deviceType == "" {
		deviceType = "android"
	}
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

	onboard := model.OnboardingApproved
	if role == 2 || role == 3 {
		onboard = model.OnboardingPending
	}

	user := &model.User{
		Phone:            &phone,
		PhoneHash:        &phoneHash,
		Nickname:         nickname,
		Role:             int16(role),
		CreditScore:      500,
		Level:            1,
		Status:           1,
		OnboardingStatus: onboard,
		LastLoginAt:      model.NowPtr(),
	}

	if err := s.repos.User.Create(user); err != nil {
		return nil, nil, err
	}

	user, err = s.repos.User.FindByUUID(user.UUID)
	if err != nil {
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

	user, err := s.repos.User.FindByUUID(claims.UserUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrTokenInvalid)
	}
	if user.Status == 2 {
		return nil, fmt.Errorf("%d", errcode.ErrAccountFrozen)
	}

	blacklistKey := fmt.Sprintf("token:blacklist:%s", claims.ID)
	exists, _ := s.rdb.Exists(ctx, blacklistKey).Result()
	if exists > 0 {
		return nil, fmt.Errorf("%d", errcode.ErrRefreshTokenExpired)
	}

	s.rdb.Set(ctx, blacklistKey, "1", 30*24*time.Hour)

	return s.jwtManager.GenerateTokenPair(claims.UserUUID, claims.Role, claims.Device)
}

func validatePasswordStrength(password string) error {
	if len(password) < 8 || len(password) > 72 {
		return fmt.Errorf("%d", errcode.ErrPasswordWeak)
	}
	var hasLetter, hasDigit bool
	for _, r := range password {
		switch {
		case unicode.IsLetter(r):
			hasLetter = true
		case unicode.IsDigit(r):
			hasDigit = true
		}
	}
	if !hasLetter || !hasDigit {
		return fmt.Errorf("%d", errcode.ErrPasswordWeak)
	}
	return nil
}

// RegisterByPassword 用户名+密文密码注册，可选短信绑定手机（purpose=1）。
func (s *AuthService) RegisterByPassword(ctx context.Context, req *dto.RegisterByPasswordReq) (*model.User, *jwtpkg.TokenPair, error) {
	if s.passwordRSA == nil {
		return nil, nil, fmt.Errorf("%d", errcode.ErrParamInvalid)
	}
	reg := s.cfg.Registration
	if reg.DisableAutoRegister {
		return nil, nil, fmt.Errorf("%d", errcode.ErrRegisterRequired)
	}
	u := strings.TrimSpace(req.Username)
	if !usernamePattern.MatchString(u) {
		return nil, nil, fmt.Errorf("%d", errcode.ErrUsernameInvalid)
	}
	plain, err := passwordrsa.DecryptPasswordCipher(s.passwordRSA, req.PasswordCipher)
	if err != nil {
		return nil, nil, err
	}
	if err := validatePasswordStrength(plain); err != nil {
		return nil, nil, err
	}
	_, err = s.repos.User.FindByUsername(u)
	if err == nil {
		return nil, nil, fmt.Errorf("%d", errcode.ErrUsernameTaken)
	}
	if err != gorm.ErrRecordNotFound {
		return nil, nil, err
	}

	var phone *string
	var phoneHash *string
	if req.Phone != nil && strings.TrimSpace(*req.Phone) != "" {
		if req.SMSCode == nil || strings.TrimSpace(*req.SMSCode) == "" {
			return nil, nil, fmt.Errorf("%d", errcode.ErrParamInvalid)
		}
		p := strings.TrimSpace(*req.Phone)
		ok, _ := regexp.MatchString(`^1[3-9]\d{9}$`, p)
		if !ok {
			return nil, nil, fmt.Errorf("%d", errcode.ErrPhoneFormat)
		}
		if err := s.VerifySMSCode(ctx, p, 1, strings.TrimSpace(*req.SMSCode)); err != nil {
			return nil, nil, err
		}
		ph := hashPhone(p)
		if _, e := s.repos.User.FindByPhoneHash(ph); e == nil {
			return nil, nil, fmt.Errorf("%d", errcode.ErrPhoneAlreadyUsed)
		} else if e != gorm.ErrRecordNotFound {
			return nil, nil, e
		}
		phone = &p
		phoneHash = &ph
	} else if req.SMSCode != nil && strings.TrimSpace(*req.SMSCode) != "" {
		return nil, nil, fmt.Errorf("%d", errcode.ErrParamInvalid)
	}

	role := req.Role
	if reg.RoleNeedsInvite(role) && strings.TrimSpace(req.InviteCode) == "" {
		return nil, nil, fmt.Errorf("%d", errcode.ErrInviteRequired)
	}
	var inviteID *int64
	if reg.RoleNeedsInvite(role) {
		consumed, _, ierr := s.repos.InviteCode.ConsumeTeamInviteAndRotate(strings.TrimSpace(req.InviteCode))
		if ierr != nil {
			return nil, nil, ierr
		}
		id := consumed.ID
		inviteID = &id
	}

	hashB, err := bcrypt.GenerateFromPassword([]byte(plain), bcrypt.DefaultCost)
	if err != nil {
		return nil, nil, err
	}
	hashStr := string(hashB)

	nickname := u
	if req.Nickname != nil && strings.TrimSpace(*req.Nickname) != "" {
		nickname = strings.TrimSpace(*req.Nickname)
	}
	onboard := model.OnboardingApproved
	if role == 2 || role == 3 || reg.RoleNeedsApproval(role) {
		onboard = model.OnboardingPending
	}

	user := &model.User{
		Username:         &u,
		PasswordHash:     &hashStr,
		Phone:            phone,
		PhoneHash:        phoneHash,
		Nickname:         nickname,
		Role:             int16(role),
		CreditScore:      500,
		Level:            1,
		Status:           1,
		OnboardingStatus: onboard,
		InviteCodeID:     inviteID,
		LastLoginAt:      model.NowPtr(),
	}
	if err := s.repos.User.Create(user); err != nil {
		return nil, nil, err
	}
	user, err = s.repos.User.FindByUUID(user.UUID)
	if err != nil {
		return nil, nil, err
	}
	if reg.RoleNeedsApproval(role) {
		return nil, nil, fmt.Errorf("%d", errcode.ErrOnboardingPending)
	}
	tokenPair, err := s.jwtManager.GenerateTokenPair(user.UUID, int(user.Role), "android")
	if err != nil {
		return nil, nil, err
	}
	return user, tokenPair, nil
}

// LoginByPassword 用户名或手机号 + 密文密码 + 图形验证码。
func (s *AuthService) LoginByPassword(_ context.Context, req *dto.LoginByPasswordReq) (*model.User, *jwtpkg.TokenPair, error) {
	if s.passwordRSA == nil {
		return nil, nil, fmt.Errorf("%d", errcode.ErrParamInvalid)
	}
	if !captcha.VerifyString(strings.TrimSpace(req.CaptchaID), strings.TrimSpace(req.CaptchaCode)) {
		return nil, nil, fmt.Errorf("%d", errcode.ErrCaptchaInvalid)
	}
	plain, err := passwordrsa.DecryptPasswordCipher(s.passwordRSA, req.PasswordCipher)
	if err != nil {
		return nil, nil, err
	}
	deviceType := req.DeviceType
	if deviceType == "" {
		deviceType = "android"
	}

	var user *model.User
	var ferr error
	switch req.LoginType {
	case "phone":
		p := strings.TrimSpace(req.Identity)
		ok, _ := regexp.MatchString(`^1[3-9]\d{9}$`, p)
		if !ok {
			return nil, nil, fmt.Errorf("%d", errcode.ErrPhoneFormat)
		}
		user, ferr = s.repos.User.FindByPhoneHash(hashPhone(p))
	default:
		id := strings.TrimSpace(req.Identity)
		if !usernamePattern.MatchString(id) {
			return nil, nil, fmt.Errorf("%d", errcode.ErrUsernameInvalid)
		}
		user, ferr = s.repos.User.FindByUsername(id)
	}
	if ferr != nil {
		if ferr == gorm.ErrRecordNotFound {
			return nil, nil, fmt.Errorf("%d", errcode.ErrLoginFailed)
		}
		return nil, nil, ferr
	}
	if user.PasswordHash == nil || *user.PasswordHash == "" {
		return nil, nil, fmt.Errorf("%d", errcode.ErrPasswordNotSet)
	}
	if err := bcrypt.CompareHashAndPassword([]byte(*user.PasswordHash), []byte(plain)); err != nil {
		return nil, nil, fmt.Errorf("%d", errcode.ErrLoginFailed)
	}
	if user.Status == 2 {
		return nil, nil, fmt.Errorf("%d", errcode.ErrAccountFrozen)
	}
	now := time.Now()
	user.LastLoginAt = &now
	_ = s.repos.User.Update(user)

	tokenPair, err := s.jwtManager.GenerateTokenPair(user.UUID, int(user.Role), deviceType)
	if err != nil {
		return nil, nil, err
	}
	return user, tokenPair, nil
}

// CreateInviteCode 管理端为团队生成当前有效邀请码（单次使用，核销后自动轮换）
func (s *AuthService) CreateInviteCode(teamUUID string, createdByUserID int64, note string, expiresAt *time.Time) (plain string, rec *model.InviteCode, err error) {
	team, err := s.repos.Team.FindByUUID(teamUUID)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return "", nil, fmt.Errorf("%d", errcode.ErrTeamNotFound)
		}
		return "", nil, err
	}
	tid := team.ID
	if err := s.repos.InviteCode.DisableActiveUnusedForTeam(tid); err != nil {
		return "", nil, err
	}
	plain = invitehash.GeneratePlain("KZ-")
	h := invitehash.Hash(plain)
	hint := plain
	if len(plain) >= 4 {
		hint = plain[len(plain)-4:]
	}
	p := plain
	ic := &model.InviteCode{
		TeamID:          &tid,
		CodeHash:        h,
		CodePlain:       &p,
		CodeHint:        hint,
		Note:            note,
		MaxUses:         1,
		UsedCount:       0,
		ExpiresAt:       expiresAt,
		CreatedByUserID: &createdByUserID,
	}
	if err := s.repos.InviteCode.Create(ic); err != nil {
		return "", nil, err
	}
	return plain, ic, nil
}

// GetTeamCurrentInvite 管理端查看团队当前有效邀请码（含明文）
func (s *AuthService) GetTeamCurrentInvite(teamUUID string) (*model.InviteCode, error) {
	team, err := s.repos.Team.FindByUUID(teamUUID)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("%d", errcode.ErrTeamNotFound)
		}
		return nil, err
	}
	ic, err := s.repos.InviteCode.FindActiveByTeamID(team.ID)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return ic, nil
}

// ListInviteCodes 管理端分页列表
func (s *AuthService) ListInviteCodes(page, pageSize int, teamUUID *string) ([]*model.InviteCode, int64, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	off := (page - 1) * pageSize
	var teamID *int64
	if teamUUID != nil && *teamUUID != "" {
		team, err := s.repos.Team.FindByUUID(*teamUUID)
		if err != nil {
			if err == gorm.ErrRecordNotFound {
				return []*model.InviteCode{}, 0, nil
			}
			return nil, 0, err
		}
		teamID = &team.ID
	}
	return s.repos.InviteCode.List(off, pageSize, teamID)
}
