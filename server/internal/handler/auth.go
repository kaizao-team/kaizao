package handler

import (
	"net/http"
	"regexp"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/dto"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/response"
	"github.com/vibebuild/server/internal/service"
	"go.uber.org/zap"
)

// Handlers 所有 Handler 的集合
type Handlers struct {
	Auth    *AuthHandler
	User    *UserHandler
	Project *ProjectHandler
}

// NewHandlers 创建所有 Handler
func NewHandlers(services *service.Services, log *zap.Logger) *Handlers {
	return &Handlers{
		Auth:    NewAuthHandler(services.Auth, log),
		User:    NewUserHandler(services.User, log),
		Project: NewProjectHandler(services.Project, log),
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
func (h *AuthHandler) SendSMSCode(c *gin.Context) {
	var req dto.SendSMSCodeReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrPhoneFormat, "参数校验失败")
		return
	}

	// 手机号格式校验
	matched, _ := regexp.MatchString(`^1[3-9]\d{9}$`, req.Phone)
	if !matched {
		response.ErrorBadRequest(c, errcode.ErrPhoneFormat, errcode.GetMessage(errcode.ErrPhoneFormat))
		return
	}

	expireSeconds, retryAfter, err := h.authService.SendSMSCode(c.Request.Context(), req.Phone, req.Purpose)
	if err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
		} else {
			response.ErrorTooManyRequests(c, 60)
		}
		return
	}

	response.Success(c, dto.SendSMSCodeResp{
		ExpireSeconds:     expireSeconds,
		RetryAfterSeconds: retryAfter,
	})
}

// Register 手机号注册
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

	response.Success(c, dto.AuthResp{
		User: dto.UserBriefResp{
			UUID:        user.UUID,
			Nickname:    user.Nickname,
			AvatarURL:   user.AvatarURL,
			Role:        user.Role,
			Level:       user.Level,
			CreditScore: user.CreditScore,
			IsVerified:  user.IsVerified,
		},
		AccessToken:  tokenPair.AccessToken,
		RefreshToken: tokenPair.RefreshToken,
		ExpiresIn:    tokenPair.ExpiresIn,
	})
}

// Login 手机号登录
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

	user, tokenPair, err := h.authService.Login(c.Request.Context(), req.Phone, req.SMSCode, deviceType)
	if err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
		} else {
			response.ErrorInternal(c, "登录失败")
		}
		return
	}

	response.Success(c, dto.AuthResp{
		User: dto.UserBriefResp{
			UUID:        user.UUID,
			Nickname:    user.Nickname,
			AvatarURL:   user.AvatarURL,
			Role:        user.Role,
			Level:       user.Level,
			CreditScore: user.CreditScore,
			IsVerified:  user.IsVerified,
		},
		AccessToken:  tokenPair.AccessToken,
		RefreshToken: tokenPair.RefreshToken,
		ExpiresIn:    tokenPair.ExpiresIn,
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
func (h *AuthHandler) Logout(c *gin.Context) {
	response.Success(c, nil)
}

// UserHandler 用户处理器
type UserHandler struct {
	userService *service.UserService
	log         *zap.Logger
}

// NewUserHandler 创建用户处理器
func NewUserHandler(userService *service.UserService, log *zap.Logger) *UserHandler {
	return &UserHandler{userService: userService, log: log}
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
