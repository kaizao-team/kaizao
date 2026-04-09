package handler

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"regexp"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/config"
	"github.com/vibebuild/server/internal/dto"
	"github.com/vibebuild/server/internal/pkg/aiagent"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/response"
	"github.com/vibebuild/server/internal/repository"
	"github.com/vibebuild/server/internal/service"
	"go.uber.org/zap"
)

// Handlers 所有 Handler 的集合
type Handlers struct {
	Auth         *AuthHandler
	User         *UserHandler
	Project      *ProjectHandler
	Home         *HomeHandler
	PRD          *PRDHandler
	Bid          *BidHandler
	Task         *TaskHandler
	Conversation *ConversationHandler
	Order        *OrderHandler
	Wallet       *WalletHandler
	Review       *ReviewHandler
	Team         *TeamHandler
	Notification *NotificationHandler
	Upload       *UploadHandler
	Admin        *AdminHandler
}

// NewHandlers 创建所有 Handler
func NewHandlers(services *service.Services, cfg *config.Config, log *zap.Logger) *Handlers {
	publicBase := ""
	if cfg != nil {
		publicBase = strings.TrimSpace(cfg.Server.PublicBaseURL)
	}
	var aiClient *aiagent.Client
	if cfg != nil {
		aiClient = aiagent.NewClient(cfg.AIAgent, log)
	}
	return &Handlers{
		Auth:         NewAuthHandler(services.Auth, log),
		Admin:        NewAdminHandler(services.Auth, services.User, services.Admin, cfg.AIAgent, log),
		User:         NewUserHandler(services.User, services.Favorite, services.Repos, log),
		Project:      NewProjectHandler(services.Project, services.ProjectFile, services.Milestone, log),
		Home:         NewHomeHandler(services.Home, log),
		PRD:          NewPRDHandler(services.Project, cfg.AIAgent, log),
		Bid:          NewBidHandler(services.Bid, services.Project, aiClient, log),
		Task:         NewTaskHandler(services.Task, services.Milestone, log),
		Conversation: NewConversationHandler(services.Conversation, log),
		Order:        NewOrderHandler(services.Order, services.Wallet, log),
		Wallet:       NewWalletHandler(services.Wallet, log),
		Review:       NewReviewHandler(services.Review, log),
		Team:         NewTeamHandler(services.Team, aiClient, log),
		Notification: NewNotificationHandler(services.Notification, log),
		Upload:       NewUploadHandler(services.Upload, publicBase, log),
	}
}

// AuthHandler 认证处理器
type AuthHandler struct {
	authService *service.AuthService
	log         *zap.Logger
}

// NewAuthHandler 创建认证处理器
func NewAuthHandler(authService *service.AuthService, log *zap.Logger) *AuthHandler {
	return &AuthHandler{authService: authService, log: log}
}

// SendSMSCode 发送短信验证码
// POST /api/v1/auth/sms-code
func (h *AuthHandler) SendSMSCode(c *gin.Context) {
	var req dto.SendSMSCodeReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrPhoneFormat, "参数校验失败")
		return
	}

	matched, _ := regexp.MatchString(`^1[3-9]\d{9}$`, req.Phone)
	if !matched {
		response.ErrorBadRequest(c, errcode.ErrPhoneFormat, errcode.GetMessage(errcode.ErrPhoneFormat))
		return
	}

	_, retryAfter, err := h.authService.SendSMSCode(c.Request.Context(), req.Phone, req.Purpose)
	if err != nil {
		if err.Error() == "too_frequent" {
			response.ErrorTooManyRequests(c, retryAfter)
		} else {
			code, _ := strconv.Atoi(err.Error())
			if code > 0 {
				response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			} else {
				response.ErrorTooManyRequests(c, 60)
			}
		}
		return
	}

	response.SuccessMsg(c, "验证码已发送", nil)
}

// Login 手机号登录（不存在自动注册）
// POST /api/v1/auth/login  Body: { "phone": "...", "code": "..." }
func (h *AuthHandler) Login(c *gin.Context) {
	var req dto.LoginReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrPhoneFormat, "参数校验失败")
		return
	}

	deviceType := req.DeviceType
	if deviceType == "" {
		deviceType = "android"
	}

	user, tokenPair, isNewUser, err := h.authService.LoginOrRegister(c.Request.Context(), req.Phone, req.Code, deviceType)
	if err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
		} else {
			response.ErrorInternal(c, "登录失败")
		}
		return
	}

	response.SuccessMsg(c, "登录成功", gin.H{
		"access_token":  tokenPair.AccessToken,
		"refresh_token": tokenPair.RefreshToken,
		"user_id":       user.UUID,
		"role":          user.Role,
		"is_new_user":   isNewUser,
	})
}

// Register 手机号注册（独立注册接口）
// POST /api/v1/auth/register
func (h *AuthHandler) Register(c *gin.Context) {
	var req dto.RegisterReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrPhoneFormat, "参数校验失败")
		return
	}

	matched, _ := regexp.MatchString(`^1[3-9]\d{9}$`, req.Phone)
	if !matched {
		response.ErrorBadRequest(c, errcode.ErrPhoneFormat, errcode.GetMessage(errcode.ErrPhoneFormat))
		return
	}

	user, tokenPair, err := h.authService.Register(c.Request.Context(), req.Phone, req.SMSCode, req.Nickname, req.Role, "android")
	if err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
		} else {
			response.ErrorInternal(c, "注册失败")
		}
		return
	}

	userBrief := dto.UserBriefResp{
		UUID:        user.UUID,
		Nickname:    user.Nickname,
		AvatarURL:   user.AvatarURL,
		Role:        user.Role,
		Level:       user.Level,
		CreditScore: user.CreditScore,
		IsVerified:  user.IsVerified,
	}
	response.Success(c, dto.AuthResp{
		User:         userBrief,
		AccessToken:  tokenPair.AccessToken,
		RefreshToken: tokenPair.RefreshToken,
		ExpiresIn:    tokenPair.ExpiresIn,
	})
}

// PasswordKey GET /api/v1/auth/password-key
func (h *AuthHandler) PasswordKey(c *gin.Context) {
	r := h.authService.PasswordPublicKey()
	if r == nil {
		response.ErrorInternal(c, "密码加密未配置")
		return
	}
	response.Success(c, r)
}

// Captcha GET /api/v1/auth/captcha
func (h *AuthHandler) Captcha(c *gin.Context) {
	id, img, exp, err := h.authService.GenerateCaptcha()
	if err != nil {
		response.ErrorInternal(c, "验证码生成失败")
		return
	}
	response.Success(c, dto.CaptchaResp{
		CaptchaID:   id,
		ImageBase64: img,
		ExpiresIn:   exp,
	})
}

var errPlaintextPasswordField = errors.New("plaintext password field")

func authJSONForbidPlaintextPassword(body []byte) error {
	var raw map[string]interface{}
	if err := json.Unmarshal(body, &raw); err != nil {
		return err
	}
	if _, ok := raw["password"]; ok {
		return errPlaintextPasswordField
	}
	return nil
}

// RegisterByPassword POST /api/v1/auth/register-password
func (h *AuthHandler) RegisterByPassword(c *gin.Context) {
	body, err := io.ReadAll(c.Request.Body)
	if err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "读取请求体失败")
		return
	}
	if err := authJSONForbidPlaintextPassword(body); err != nil {
		if errors.Is(err, errPlaintextPasswordField) {
			response.ErrorBadRequest(c, errcode.ErrPasswordPlaintextForbidden, errcode.GetMessage(errcode.ErrPasswordPlaintextForbidden))
			return
		}
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数格式错误")
		return
	}
	c.Request.Body = io.NopCloser(bytes.NewReader(body))
	var req dto.RegisterByPasswordReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}

	user, tokenPair, err := h.authService.RegisterByPassword(c.Request.Context(), &req)
	if err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
		} else {
			response.ErrorInternal(c, "注册失败")
		}
		return
	}
	userBrief := dto.UserBriefResp{
		UUID:        user.UUID,
		Nickname:    user.Nickname,
		AvatarURL:   user.AvatarURL,
		Role:        user.Role,
		Level:       user.Level,
		CreditScore: user.CreditScore,
		IsVerified:  user.IsVerified,
	}
	response.Success(c, dto.AuthResp{
		User:         userBrief,
		AccessToken:  tokenPair.AccessToken,
		RefreshToken: tokenPair.RefreshToken,
		ExpiresIn:    tokenPair.ExpiresIn,
	})
}

// LoginByPassword POST /api/v1/auth/login-password
func (h *AuthHandler) LoginByPassword(c *gin.Context) {
	body, err := io.ReadAll(c.Request.Body)
	if err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "读取请求体失败")
		return
	}
	if err := authJSONForbidPlaintextPassword(body); err != nil {
		if errors.Is(err, errPlaintextPasswordField) {
			response.ErrorBadRequest(c, errcode.ErrPasswordPlaintextForbidden, errcode.GetMessage(errcode.ErrPasswordPlaintextForbidden))
			return
		}
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数格式错误")
		return
	}
	c.Request.Body = io.NopCloser(bytes.NewReader(body))
	var req dto.LoginByPasswordReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}

	user, tokenPair, err := h.authService.LoginByPassword(c.Request.Context(), &req)
	if err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
		} else {
			response.ErrorInternal(c, "登录失败")
		}
		return
	}
	response.SuccessMsg(c, "登录成功", gin.H{
		"access_token":  tokenPair.AccessToken,
		"refresh_token": tokenPair.RefreshToken,
		"user_id":       user.UUID,
		"role":          user.Role,
		"is_new_user":   false,
	})
}

// WechatLogin 微信 OAuth 登录
func (h *AuthHandler) WechatLogin(c *gin.Context) {
	var req dto.WechatLoginReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrWechatAuthFailed, "参数校验失败")
		return
	}
	response.Success(c, map[string]interface{}{
		"message": "wechat login endpoint ready",
	})
}

// RefreshToken 刷新 Token
// POST /api/v1/auth/refresh
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req dto.RefreshTokenReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrTokenInvalid, "参数校验失败")
		return
	}

	tokenPair, err := h.authService.RefreshToken(c.Request.Context(), req.RefreshToken)
	if err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code > 0 {
			response.ErrorUnauthorized(c, code, errcode.GetMessage(code))
		} else {
			response.ErrorUnauthorized(c, errcode.ErrTokenInvalid, "Token无效")
		}
		return
	}

	response.Success(c, dto.TokenResp{
		AccessToken:  tokenPair.AccessToken,
		RefreshToken: tokenPair.RefreshToken,
		ExpiresIn:    tokenPair.ExpiresIn,
	})
}

// Logout 退出登录
// POST /api/v1/auth/logout
func (h *AuthHandler) Logout(c *gin.Context) {
	response.Success(c, nil)
}

// UserHandler 用户处理器
type UserHandler struct {
	userService     *service.UserService
	favoriteService *service.FavoriteService
	repos           *repository.Repositories
	log             *zap.Logger
}

// NewUserHandler 创建用户处理器
func NewUserHandler(userService *service.UserService, favoriteService *service.FavoriteService, repos *repository.Repositories, log *zap.Logger) *UserHandler {
	return &UserHandler{userService: userService, favoriteService: favoriteService, repos: repos, log: log}
}

// GetMe 获取当前用户信息
// GET /api/v1/users/me
func (h *UserHandler) GetMe(c *gin.Context) {
	userUUID := c.GetString("user_uuid")
	user, err := h.userService.GetByUUID(userUUID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrUserNotFound, "用户不存在")
		return
	}

	stats := h.userService.GetUserStats(user)
	skills, _ := h.userService.ListUserSkills(user.ID)

	hourlyRate := user.HourlyRate
	availableStatus := user.AvailableStatus
	var budgetMin, budgetMax *float64
	var teamInfo interface{}
	if user.Role == 2 || user.Role == 3 {
		if team, err := h.repos.Team.FindPrimaryTeamForUser(user.ID); err == nil && team != nil {
			hourlyRate = team.HourlyRate
			availableStatus = team.AvailableStatus
			budgetMin = team.BudgetMin
			budgetMax = team.BudgetMax
			teamInfo = gin.H{
				"uuid":             team.UUID,
				"name":             team.Name,
				"avatar_url":       team.AvatarURL,
				"description":      team.Description,
				"vibe_level":       team.VibeLevel,
				"vibe_power":       team.VibePower,
				"avg_rating":       team.AvgRating,
				"member_count":     team.MemberCount,
				"total_projects":   team.TotalProjects,
				"hourly_rate":      team.HourlyRate,
				"available_status": team.AvailableStatus,
				"budget_min":       team.BudgetMin,
				"budget_max":       team.BudgetMax,
			}
		}
	}

	response.Success(c, gin.H{
		"id":               user.UUID,
		"uuid":             user.UUID,
		"nickname":         user.Nickname,
		"avatar_url":       user.AvatarURL,
		"contact_phone":    user.ContactPhone,
		"role":             user.Role,
		"onboarding_status":        user.OnboardingStatus,
		"onboarding_submitted_at":  user.OnboardingSubmittedAt,
		"resume_url":               user.ResumeURL,
		"onboarding_application_note": user.OnboardingApplicationNote,
		"bio":              user.Bio,
		"city":             user.City,
		"is_verified":      user.IsVerified,
		"credit_score":     user.CreditScore,
		"level":            user.Level,
		"total_orders":     user.TotalOrders,
		"completed_orders": user.CompletedOrders,
		"completion_rate":  user.CompletionRate,
		"avg_rating":       user.AvgRating,
		"hourly_rate":      hourlyRate,
		"available_status": availableStatus,
		"budget_min":       budgetMin,
		"budget_max":       budgetMax,
		"skills":           userSkillsToResponse(skills),
		"role_tags":        []interface{}{},
		"stats":            stats,
		"team":             teamInfo,
	})
}

// UpdateMe 更新当前用户信息
// PUT /api/v1/users/me
func (h *UserHandler) UpdateMe(c *gin.Context) {
	userUUID := c.GetString("user_uuid")

	var req dto.UpdateUserReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}

	fields := make(map[string]interface{})
	if req.Nickname != nil {
		fields["nickname"] = *req.Nickname
	}
	if req.AvatarURL != nil {
		avatar := strings.TrimSpace(*req.AvatarURL)
		if avatar == "" {
			fields["avatar_url"] = nil
		} else {
			fields["avatar_url"] = avatar
		}
	}
	if req.Gender != nil {
		fields["gender"] = *req.Gender
	}
	if req.Bio != nil {
		fields["bio"] = *req.Bio
	}
	if req.City != nil {
		fields["city"] = *req.City
	}
	if req.ContactPhone != nil {
		cp := strings.TrimSpace(*req.ContactPhone)
		if cp == "" {
			fields["contact_phone"] = nil
		} else {
			fields["contact_phone"] = cp
		}
	}
	if req.Role != nil {
		fields["role"] = *req.Role
	}
	if req.HourlyRate != nil {
		fields["hourly_rate"] = *req.HourlyRate
	}
	if req.AvailableStatus != nil {
		fields["available_status"] = *req.AvailableStatus
	}

	if len(fields) == 0 {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "无可更新字段")
		return
	}

	if _, err := h.userService.UpdateProfile(userUUID, fields); err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
		} else {
			response.ErrorInternal(c, "更新失败")
		}
		return
	}

	response.SuccessMsg(c, "更新成功", nil)
}

// placeholder 为尚未实现完整逻辑的端点提供统一占位响应
func placeholder(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":       0,
		"message":    "success",
		"data":       gin.H{"status": "endpoint ready"},
		"request_id": c.GetString("request_id"),
	})
}
