package handler

import (
	"encoding/json"
	"errors"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/response"
	"github.com/vibebuild/server/internal/service"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

// AdminHandler 管理端（邀请码、入驻审核）
type AdminHandler struct {
	authService *service.AuthService
	userService *service.UserService
	log         *zap.Logger
}

func NewAdminHandler(auth *service.AuthService, user *service.UserService, log *zap.Logger) *AdminHandler {
	return &AdminHandler{authService: auth, userService: user, log: log}
}

type createInviteCodeReq struct {
	TeamUUID  string  `json:"team_uuid" binding:"required"`
	Note      string  `json:"note"`
	ExpiresAt *string `json:"expires_at"`
}

// CreateInviteCode POST /api/v1/admin/invite-codes（绑定团队；若已有未用码会先作废再发新码）
func (h *AdminHandler) CreateInviteCode(c *gin.Context) {
	adminUUID := c.GetString("user_uuid")
	admin, err := h.userService.GetByUUID(adminUUID)
	if err != nil {
		response.ErrorInternal(c, "管理员信息异常")
		return
	}
	var req createInviteCodeReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	var exp *time.Time
	if req.ExpiresAt != nil && *req.ExpiresAt != "" {
		t, e := time.Parse(time.RFC3339, *req.ExpiresAt)
		if e != nil {
			response.ErrorBadRequest(c, errcode.ErrParamInvalid, "expires_at 格式须为 RFC3339")
			return
		}
		exp = &t
	}
	plain, rec, err := h.authService.CreateInviteCode(req.TeamUUID, admin.ID, req.Note, exp)
	if err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code == errcode.ErrTeamNotFound {
			response.ErrorNotFound(c, errcode.ErrTeamNotFound, errcode.GetMessage(errcode.ErrTeamNotFound))
			return
		}
		response.ErrorInternal(c, "创建邀请码失败")
		return
	}
	response.Success(c, gin.H{
		"code_plain": plain,
		"uuid":       rec.UUID,
		"team_id":    rec.TeamID,
		"max_uses":   rec.MaxUses,
		"expires_at": rec.ExpiresAt,
		"note":       rec.Note,
	})
}

// ListInviteCodes GET /api/v1/admin/invite-codes?team_uuid=
func (h *AdminHandler) ListInviteCodes(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	var teamUUID *string
	if q := c.Query("team_uuid"); q != "" {
		teamUUID = &q
	}
	list, total, err := h.authService.ListInviteCodes(page, pageSize, teamUUID)
	if err != nil {
		response.ErrorInternal(c, "查询失败")
		return
	}
	out := make([]gin.H, 0, len(list))
	for _, ic := range list {
		var allowed []int
		if len(ic.AllowedRoles) > 0 {
			_ = json.Unmarshal(ic.AllowedRoles, &allowed)
		}
		row := gin.H{
			"uuid":          ic.UUID,
			"team_id":       ic.TeamID,
			"code_hint":     ic.CodeHint,
			"code_plain":    ic.CodePlain,
			"note":          ic.Note,
			"max_uses":      ic.MaxUses,
			"used_count":    ic.UsedCount,
			"expires_at":    ic.ExpiresAt,
			"allowed_roles": allowed,
			"disabled_at":   ic.DisabledAt,
			"created_at":    ic.CreatedAt,
		}
		out = append(out, row)
	}
	response.SuccessWithMeta(c, out, response.BuildMeta(page, pageSize, total))
}

// GetTeamCurrentInviteCode GET /api/v1/admin/teams/:uuid/current-invite-code
func (h *AdminHandler) GetTeamCurrentInviteCode(c *gin.Context) {
	teamUUID := c.Param("uuid")
	ic, err := h.authService.GetTeamCurrentInvite(teamUUID)
	if err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code == errcode.ErrTeamNotFound {
			response.ErrorNotFound(c, errcode.ErrTeamNotFound, errcode.GetMessage(errcode.ErrTeamNotFound))
			return
		}
		response.ErrorInternal(c, "查询失败")
		return
	}
	if ic == nil {
		response.Success(c, gin.H{"has_active": false})
		return
	}
	response.Success(c, gin.H{
		"has_active": true,
		"uuid":       ic.UUID,
		"team_id":    ic.TeamID,
		"code_plain": ic.CodePlain,
		"code_hint":  ic.CodeHint,
		"expires_at": ic.ExpiresAt,
		"note":       ic.Note,
	})
}

type updateOnboardingReq struct {
	Status string  `json:"status" binding:"required,oneof=approved rejected"`
	Reason *string `json:"reason"`
}

// UpdateUserOnboarding PUT /api/v1/admin/users/:uuid/onboarding
func (h *AdminHandler) UpdateUserOnboarding(c *gin.Context) {
	targetUUID := c.Param("uuid")
	var req updateOnboardingReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	adminUUID := c.GetString("user_uuid")
	admin, err := h.userService.GetByUUID(adminUUID)
	if err != nil {
		response.ErrorInternal(c, "管理员信息异常")
		return
	}
	var st int16
	if req.Status == "approved" {
		st = model.OnboardingApproved
	} else {
		st = model.OnboardingRejected
	}
	if err := h.userService.SetOnboarding(targetUUID, st, req.Reason, admin.ID); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.ErrorNotFound(c, errcode.ErrAdminTargetNotFound, "用户不存在")
			return
		}
		response.ErrorInternal(c, "更新失败")
		return
	}
	response.SuccessMsg(c, "已更新", nil)
}
