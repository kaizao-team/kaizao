package handler

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/config"
	"github.com/vibebuild/server/internal/dto"
	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/response"
	"github.com/vibebuild/server/internal/service"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

// AdminHandler 管理端（邀请码、入驻审核 + 全部 admin API）
type AdminHandler struct {
	authService    *service.AuthService
	userService    *service.UserService
	adminService   *service.AdminService
	aiAgentBaseURL string
	log            *zap.Logger
}

func NewAdminHandler(auth *service.AuthService, user *service.UserService, admin *service.AdminService, aiCfg config.AIAgentConfig, log *zap.Logger) *AdminHandler {
	return &AdminHandler{
		authService:    auth,
		userService:    user,
		adminService:   admin,
		aiAgentBaseURL: strings.TrimRight(strings.TrimSpace(aiCfg.BaseURL), "/"),
		log:            log,
	}
}

// ──────────── 邀请码 ────────────

type batchCreateInviteCodeReq struct {
	Count     int     `json:"count"`
	Note      string  `json:"note"`
	ExpiresAt *string `json:"expires_at"`
}

// CreateInviteCode POST /admin/invite-codes — 批量创建全局邀请码
func (h *AdminHandler) CreateInviteCode(c *gin.Context) {
	adminUUID := c.GetString("user_uuid")
	admin, err := h.userService.GetByUUID(adminUUID)
	if err != nil {
		response.ErrorInternal(c, "管理员信息异常")
		return
	}
	var req batchCreateInviteCodeReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	if req.Count <= 0 {
		req.Count = 10
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
	plains, err := h.authService.BatchCreateInviteCodes(req.Count, admin.ID, req.Note, exp)
	if err != nil {
		response.ErrorInternal(c, "创建邀请码失败")
		return
	}
	response.Success(c, gin.H{
		"codes": plains,
		"count": len(plains),
	})
}

func (h *AdminHandler) ListInviteCodes(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	list, total, err := h.authService.ListInviteCodes(page, pageSize, nil)
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

// ReviewTeamApproval PUT /admin/teams/:uuid/approval — 管理端审核团队
func (h *AdminHandler) ReviewTeamApproval(c *gin.Context) {
	teamUUID := c.Param("uuid")
	var req struct {
		Status string  `json:"status" binding:"required,oneof=approved rejected"`
		Reason *string `json:"reason"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	var st int16
	if req.Status == "approved" {
		st = model.TeamApprovalApproved
	} else {
		st = model.TeamApprovalRejected
	}
	if err := h.adminService.UpdateTeamApproval(teamUUID, st); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.ErrorNotFound(c, errcode.ErrTeamNotFound, errcode.GetMessage(errcode.ErrTeamNotFound))
			return
		}
		response.ErrorInternal(c, "审核操作失败")
		return
	}
	response.SuccessMsg(c, "已更新", nil)
}

type updateOnboardingReq struct {
	Status string  `json:"status" binding:"required,oneof=approved rejected"`
	Reason *string `json:"reason"`
}

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

// ──────────── 用户管理 ────────────

// ListUsers GET /admin/users
func (h *AdminHandler) ListUsers(c *gin.Context) {
	var q dto.AdminListUsersQuery
	if err := c.ShouldBindQuery(&q); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	if q.Page < 1 {
		q.Page = 1
	}
	if q.PageSize < 1 || q.PageSize > 100 {
		q.PageSize = 20
	}
	users, total, err := h.adminService.ListUsers(service.AdminUserListOpts{
		Keyword:          q.Keyword,
		Role:             q.Role,
		Status:           q.Status,
		OnboardingStatus: q.OnboardingStatus,
		StartDate:        q.StartDate,
		EndDate:          q.EndDate,
		Page:             q.Page,
		PageSize:         q.PageSize,
	})
	if err != nil {
		response.ErrorInternal(c, "查询失败")
		return
	}
	out := make([]gin.H, 0, len(users))
	for _, u := range users {
		phone := ""
		if u.Phone != nil {
			phone = maskPhone(*u.Phone)
		}
		out = append(out, gin.H{
			"uuid":                        u.UUID,
			"nickname":                    u.Nickname,
			"avatar_url":                  u.AvatarURL,
			"phone":                       phone,
			"role":                        u.Role,
			"status":                      service.DBStatusToFront(u.Status),
			"onboarding_status":           u.OnboardingStatus,
			"credit_score":                u.CreditScore,
			"level":                       u.Level,
			"completed_orders":            u.CompletedOrders,
			"created_at":                  u.CreatedAt,
			"last_login_at":               u.LastLoginAt,
			"onboarding_submitted_at":     u.OnboardingSubmittedAt,
			"onboarding_reviewed_at":      u.OnboardingReviewedAt,
			"onboarding_application_note": u.OnboardingApplicationNote,
			"resume_url":                  u.ResumeURL,
		})
	}
	response.SuccessWithMeta(c, out, response.BuildMeta(q.Page, q.PageSize, total))
}

// UpdateUserStatus PUT /admin/users/:uuid/status
func (h *AdminHandler) UpdateUserStatus(c *gin.Context) {
	uuid := c.Param("uuid")
	var req dto.AdminUpdateUserStatusReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	if err := h.adminService.UpdateUserStatus(uuid, req.Status, req.Reason); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.ErrorNotFound(c, errcode.ErrAdminTargetNotFound, "用户不存在")
			return
		}
		if err.Error() == "cannot_freeze_super_admin" {
			response.ErrorForbidden(c, errcode.ErrCannotFreezeSuperAdmin, errcode.GetMessage(errcode.ErrCannotFreezeSuperAdmin))
			return
		}
		response.ErrorInternal(c, "操作失败")
		return
	}
	response.SuccessMsg(c, "已更新", nil)
}

// GetUserDetail GET /admin/users/:uuid
func (h *AdminHandler) GetUserDetail(c *gin.Context) {
	uuid := c.Param("uuid")
	u, err := h.adminService.GetUserDetail(uuid)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.ErrorNotFound(c, errcode.ErrAdminTargetNotFound, "用户不存在")
			return
		}
		response.ErrorInternal(c, "查询失败")
		return
	}
	phone := ""
	if u.Phone != nil {
		phone = maskPhone(*u.Phone)
	}
	response.Success(c, gin.H{
		"uuid":                        u.UUID,
		"nickname":                    u.Nickname,
		"avatar_url":                  u.AvatarURL,
		"phone":                       phone,
		"role":                        u.Role,
		"gender":                      u.Gender,
		"bio":                         u.Bio,
		"city":                        u.City,
		"is_verified":                 u.IsVerified,
		"credit_score":                u.CreditScore,
		"level":                       u.Level,
		"status":                      service.DBStatusToFront(u.Status),
		"onboarding_status":           u.OnboardingStatus,
		"freeze_reason":               u.FreezeReason,
		"total_orders":                u.TotalOrders,
		"completed_orders":            u.CompletedOrders,
		"avg_rating":                  u.AvgRating,
		"total_earnings":              u.TotalEarnings,
		"last_login_at":               u.LastLoginAt,
		"created_at":                  u.CreatedAt,
		"onboarding_submitted_at":     u.OnboardingSubmittedAt,
		"onboarding_reviewed_at":      u.OnboardingReviewedAt,
		"onboarding_application_note": u.OnboardingApplicationNote,
		"resume_url":                  u.ResumeURL,
	})
}

// GetUserSkills GET /admin/users/:uuid/skills
func (h *AdminHandler) GetUserSkills(c *gin.Context) {
	uuid := c.Param("uuid")
	u, err := h.userService.GetByUUID(uuid)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrAdminTargetNotFound, "用户不存在")
		return
	}
	skills, err := h.userService.ListUserSkills(u.ID)
	if err != nil {
		response.ErrorInternal(c, "查询失败")
		return
	}
	out := make([]gin.H, 0, len(skills))
	for _, sk := range skills {
		out = append(out, gin.H{
			"skill_id":            sk.SkillID,
			"skill_name":          sk.Skill.Name,
			"category":            sk.Skill.Category,
			"proficiency":         sk.Proficiency,
			"years_of_experience": sk.YearsOfExperience,
			"is_primary":          sk.IsPrimary,
		})
	}
	response.Success(c, out)
}

// GetUserPortfolios GET /admin/users/:uuid/portfolios
func (h *AdminHandler) GetUserPortfolios(c *gin.Context) {
	uuid := c.Param("uuid")
	u, err := h.userService.GetByUUID(uuid)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrAdminTargetNotFound, "用户不存在")
		return
	}
	portfolios, err := h.userService.ListUserPortfolios(u.ID)
	if err != nil {
		response.ErrorInternal(c, "查询失败")
		return
	}
	response.Success(c, portfolios)
}

// ──────────── 项目管理 ────────────

// ListProjects GET /admin/projects
func (h *AdminHandler) ListProjects(c *gin.Context) {
	var q dto.AdminListProjectsQuery
	if err := c.ShouldBindQuery(&q); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	if q.Page < 1 {
		q.Page = 1
	}
	if q.PageSize < 1 || q.PageSize > 100 {
		q.PageSize = 20
	}
	projects, total, err := h.adminService.ListProjects(service.AdminProjectListOpts{
		Keyword:   q.Keyword,
		Status:    q.Status,
		Category:  q.Category,
		BudgetMin: q.BudgetMin,
		BudgetMax: q.BudgetMax,
		StartDate: q.StartDate,
		EndDate:   q.EndDate,
		Page:      q.Page,
		PageSize:  q.PageSize,
	})
	if err != nil {
		response.ErrorInternal(c, "查询失败")
		return
	}
	out := make([]gin.H, 0, len(projects))
	for _, p := range projects {
		item := gin.H{
			"uuid":         p.UUID,
			"title":        p.Title,
			"category":     p.Category,
			"status":       p.Status,
			"budget_min":   p.BudgetMin,
			"budget_max":   p.BudgetMax,
			"agreed_price": p.AgreedPrice,
			"bid_count":    p.BidCount,
			"view_count":   p.ViewCount,
			"provider_id":  p.ProviderID,
			"team_id":      p.TeamID,
			"published_at": p.PublishedAt,
			"created_at":   p.CreatedAt,
		}
		if p.Owner != nil {
			item["owner_id"] = p.Owner.UUID
			item["owner_nickname"] = p.Owner.Nickname
			item["owner_avatar"] = p.Owner.AvatarURL
		}
		out = append(out, item)
	}
	response.SuccessWithMeta(c, out, response.BuildMeta(q.Page, q.PageSize, total))
}

// ReviewProject PUT /admin/projects/:uuid/review
func (h *AdminHandler) ReviewProject(c *gin.Context) {
	uuid := c.Param("uuid")
	var req dto.AdminProjectReviewReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	if err := h.adminService.ReviewProject(uuid, req.Action, req.Reason); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.ErrorNotFound(c, errcode.ErrAdminProjectNotFound, errcode.GetMessage(errcode.ErrAdminProjectNotFound))
			return
		}
		if err.Error() == "invalid_action" {
			response.ErrorBadRequest(c, errcode.ErrAdminInvalidAction, errcode.GetMessage(errcode.ErrAdminInvalidAction))
			return
		}
		response.ErrorInternal(c, "操作失败")
		return
	}
	response.SuccessMsg(c, "已更新", nil)
}

// ──────────── Dashboard ────────────

// GetDashboard GET /admin/dashboard
func (h *AdminHandler) GetDashboard(c *gin.Context) {
	data, err := h.adminService.GetDashboard()
	if err != nil {
		response.ErrorInternal(c, "查询失败")
		return
	}
	userTrend := make([]dto.AdminTrendPoint, len(data.UserTrend))
	for i, p := range data.UserTrend {
		userTrend[i] = dto.AdminTrendPoint{Date: p.Date, Count: p.Count}
	}
	projectTrend := make([]dto.AdminTrendPoint, len(data.ProjectTrend))
	for i, p := range data.ProjectTrend {
		projectTrend[i] = dto.AdminTrendPoint{Date: p.Date, Count: p.Count}
	}
	orderTrend := make([]dto.AdminOrderTrendPoint, len(data.OrderTrend))
	for i, p := range data.OrderTrend {
		orderTrend[i] = dto.AdminOrderTrendPoint{Date: p.Date, Amount: p.Count}
	}
	response.Success(c, dto.AdminDashboardResp{
		UserCount:              data.UserCount,
		UserToday:              data.UserToday,
		ProjectCount:           data.ProjectCount,
		ProjectWeek:            data.ProjectWeek,
		ActiveTeamCount:        data.ActiveTeamCount,
		OrderTotalAmount:       data.OrderTotalAmount,
		OrderMonthAmount:       data.OrderMonthAmount,
		PendingOnboardingCount: data.PendingOnboardingCount,
		PendingReportCount:     data.PendingReportCount,
		UserTrend:              userTrend,
		ProjectTrend:           projectTrend,
		OrderTrend:             orderTrend,
	})
}

// ──────────── 举报 ────────────

// ListReports GET /admin/reports
func (h *AdminHandler) ListReports(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	var status *int
	if s := c.Query("status"); s != "" {
		v, _ := strconv.Atoi(s)
		status = &v
	}
	list, total, err := h.adminService.ListReports(page, pageSize, status)
	if err != nil {
		response.ErrorInternal(c, "查询失败")
		return
	}
	response.SuccessWithMeta(c, list, response.BuildMeta(page, pageSize, total))
}

// HandleReport PUT /admin/reports/:uuid
func (h *AdminHandler) HandleReport(c *gin.Context) {
	uuid := c.Param("uuid")
	var req dto.AdminHandleReportReq
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
	if err := h.adminService.HandleReport(uuid, req.HandleResult, req.Action, admin.ID); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.ErrorNotFound(c, errcode.ErrAdminReportNotFound, errcode.GetMessage(errcode.ErrAdminReportNotFound))
			return
		}
		response.ErrorInternal(c, "操作失败")
		return
	}
	response.SuccessMsg(c, "已处理", nil)
}

// ──────────── 仲裁 ────────────

// ListArbitrations GET /admin/arbitrations
func (h *AdminHandler) ListArbitrations(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	var status *int
	if s := c.Query("status"); s != "" {
		v, _ := strconv.Atoi(s)
		status = &v
	}
	list, total, err := h.adminService.ListArbitrations(page, pageSize, status)
	if err != nil {
		response.ErrorInternal(c, "查询失败")
		return
	}
	response.SuccessWithMeta(c, list, response.BuildMeta(page, pageSize, total))
}

// HandleArbitration PUT /admin/arbitrations/:uuid
func (h *AdminHandler) HandleArbitration(c *gin.Context) {
	uuid := c.Param("uuid")
	var req dto.AdminHandleArbitrationReq
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
	if err := h.adminService.HandleArbitration(uuid, req.Verdict, req.VerdictType, req.RefundAmount, admin.ID); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.ErrorNotFound(c, errcode.ErrAdminArbitrationNotFound, errcode.GetMessage(errcode.ErrAdminArbitrationNotFound))
			return
		}
		response.ErrorInternal(c, "操作失败")
		return
	}
	response.SuccessMsg(c, "已处理", nil)
}

// ──────────── 订单/财务 ────────────

// ListOrders GET /admin/orders
func (h *AdminHandler) ListOrders(c *gin.Context) {
	var q dto.AdminListOrdersQuery
	if err := c.ShouldBindQuery(&q); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	if q.Page < 1 {
		q.Page = 1
	}
	if q.PageSize < 1 || q.PageSize > 100 {
		q.PageSize = 20
	}
	list, total, err := h.adminService.ListOrders(service.AdminOrderListOpts{
		OrderNo:       q.OrderNo,
		Status:        q.Status,
		PaymentMethod: q.PaymentMethod,
		AmountMin:     q.AmountMin,
		AmountMax:     q.AmountMax,
		StartDate:     q.StartDate,
		EndDate:       q.EndDate,
		Page:          q.Page,
		PageSize:      q.PageSize,
	})
	if err != nil {
		response.ErrorInternal(c, "查询失败")
		return
	}
	response.SuccessWithMeta(c, list, response.BuildMeta(q.Page, q.PageSize, total))
}

// GetOrderDetail GET /admin/orders/:id
func (h *AdminHandler) GetOrderDetail(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "无效的订单 ID")
		return
	}
	order, err := h.adminService.GetOrderDetail(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.ErrorNotFound(c, errcode.ErrAdminOrderNotFound, errcode.GetMessage(errcode.ErrAdminOrderNotFound))
			return
		}
		response.ErrorInternal(c, "查询失败")
		return
	}
	response.Success(c, order)
}

// GetFinanceSummary GET /admin/finance/summary
func (h *AdminHandler) GetFinanceSummary(c *gin.Context) {
	fs, err := h.adminService.GetFinanceSummary()
	if err != nil {
		response.ErrorInternal(c, "查询失败")
		return
	}
	response.Success(c, dto.AdminFinanceSummaryResp{
		TotalGMV:            fs.TotalGMV,
		MonthGMV:            fs.MonthGMV,
		TotalPlatformFee:    fs.TotalPlatformFee,
		PendingEscrowAmount: fs.PendingEscrowAmount,
		PendingRefundCount:  fs.PendingRefundCount,
	})
}

// ListWithdrawals GET /admin/withdrawals
func (h *AdminHandler) ListWithdrawals(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	var status *int
	if s := c.Query("status"); s != "" {
		v, _ := strconv.Atoi(s)
		status = &v
	}
	list, total, err := h.adminService.ListWithdrawals(page, pageSize, status)
	if err != nil {
		response.ErrorInternal(c, "查询失败")
		return
	}
	response.SuccessWithMeta(c, list, response.BuildMeta(page, pageSize, total))
}

// ──────────── 评价管理 ────────────

// ListReviews GET /admin/reviews
func (h *AdminHandler) ListReviews(c *gin.Context) {
	var q dto.AdminListReviewsQuery
	if err := c.ShouldBindQuery(&q); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	if q.Page < 1 {
		q.Page = 1
	}
	if q.PageSize < 1 || q.PageSize > 100 {
		q.PageSize = 20
	}
	list, total, err := h.adminService.ListReviews(service.AdminReviewListOpts{
		Status:      q.Status,
		RatingMin:   q.RatingMin,
		RatingMax:   q.RatingMax,
		IsAnonymous: q.IsAnonymous,
		StartDate:   q.StartDate,
		EndDate:     q.EndDate,
		Page:        q.Page,
		PageSize:    q.PageSize,
	})
	if err != nil {
		response.ErrorInternal(c, "查询失败")
		return
	}
	// 构造前端期望的响应格式
	out := make([]gin.H, 0, len(list))
	for _, r := range list {
		item := gin.H{
			"uuid":           r.UUID,
			"project_id":     r.ProjectID,
			"overall_rating": r.OverallRating,
			"content":        r.Content,
			"tags":           r.Tags,
			"member_ratings": r.MemberRatings,
			"is_anonymous":   r.IsAnonymous,
			"status":         r.Status,
			"reply_content":  r.ReplyContent,
			"created_at":     r.CreatedAt,
			"reviewer_role":  r.ReviewerRole,
			"dimension_ratings": gin.H{
				"quality":         r.QualityRating,
				"communication":   r.CommunicationRating,
				"timeliness":      r.TimelinessRating,
				"professionalism": r.ProfessionalismRating,
			},
		}
		if r.Reviewer != nil {
			item["reviewer_id"] = r.Reviewer.UUID
			item["reviewer_nickname"] = r.Reviewer.Nickname
		}
		if r.Reviewee != nil {
			item["reviewee_id"] = r.Reviewee.UUID
			item["reviewee_nickname"] = r.Reviewee.Nickname
		}
		out = append(out, item)
	}
	response.SuccessWithMeta(c, out, response.BuildMeta(q.Page, q.PageSize, total))
}

// UpdateReviewStatus PUT /admin/reviews/:uuid/status
func (h *AdminHandler) UpdateReviewStatus(c *gin.Context) {
	uuid := c.Param("uuid")
	var req dto.AdminUpdateReviewStatusReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	if err := h.adminService.UpdateReviewStatus(uuid, req.Status); err != nil {
		response.ErrorInternal(c, "操作失败")
		return
	}
	response.SuccessMsg(c, "已更新", nil)
}

// ──────────── AI 模型配置（代理转发到 ai-agent） ────────────

// GetAIModelConfig GET /admin/ai-models → ai-agent GET /api/v2/models/config
func (h *AdminHandler) GetAIModelConfig(c *gin.Context) {
	h.proxyAIAgent(c, http.MethodGet, "/api/v2/models/config", nil)
}

// UpdateAIModelConfig PUT /admin/ai-models → ai-agent PUT /api/v2/models/config
func (h *AdminHandler) UpdateAIModelConfig(c *gin.Context) {
	body, err := io.ReadAll(c.Request.Body)
	if err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "读取请求体失败")
		return
	}
	h.proxyAIAgent(c, http.MethodPut, "/api/v2/models/config", body)
}

// ──────────── AI 文档下载（代理转发到 ai-agent） ────────────

// ListAIDocuments GET /admin/projects/:uuid/ai-documents
func (h *AdminHandler) ListAIDocuments(c *gin.Context) {
	uuid := c.Param("uuid")
	h.proxyAIAgent(c, http.MethodGet, "/api/v2/documents/"+uuid, nil)
}

// DownloadAIDocument GET /admin/projects/:uuid/ai-documents/:docId/download
func (h *AdminHandler) DownloadAIDocument(c *gin.Context) {
	uuid := c.Param("uuid")
	docID := c.Param("docId")
	h.proxyAIAgent(c, http.MethodGet, "/api/v2/documents/"+uuid+"/download/"+docID, nil)
}

// ReanalyzePRD POST /admin/projects/:uuid/prd/reanalyze
func (h *AdminHandler) ReanalyzePRD(c *gin.Context) {
	uuid := c.Param("uuid")
	h.proxyAIAgent(c, http.MethodPost, "/api/v2/documents/"+uuid+"/reanalyze", nil)
}

// UploadProjectPRDDocument PUT /admin/projects/:uuid/prd/document
func (h *AdminHandler) UploadProjectPRDDocument(c *gin.Context) {
	uuid := c.Param("uuid")
	h.proxyAIAgentMultipart(c, http.MethodPut, "/api/v2/documents/"+uuid+"/prd/document")
}

func (h *AdminHandler) proxyAIAgent(c *gin.Context, method, path string, body []byte) {
	if h.aiAgentBaseURL == "" {
		response.ErrorInternal(c, "ai-agent 未配置")
		return
	}
	url := h.aiAgentBaseURL + path
	var reqBody io.Reader
	if body != nil {
		reqBody = strings.NewReader(string(body))
	}
	req, err := http.NewRequestWithContext(c.Request.Context(), method, url, reqBody)
	if err != nil {
		response.ErrorInternal(c, fmt.Sprintf("构建请求失败: %v", err))
		return
	}
	req.Header.Set("Content-Type", "application/json")
	if rid := c.GetString("request_id"); rid != "" {
		req.Header.Set("X-Request-ID", rid)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		h.log.Warn("proxy_ai_agent_error", zap.Error(err))
		response.ErrorInternal(c, "ai-agent 服务不可用")
		return
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)

	// 透传 ai-agent 的 JSON 响应
	c.Data(resp.StatusCode, "application/json; charset=utf-8", raw)
}

// ──────────── helpers ────────────

func (h *AdminHandler) proxyAIAgentMultipart(c *gin.Context, method, path string) {
	if h.aiAgentBaseURL == "" {
		response.ErrorInternal(c, "ai-agent not configured")
		return
	}
	url := h.aiAgentBaseURL + path
	req, err := http.NewRequestWithContext(c.Request.Context(), method, url, c.Request.Body)
	if err != nil {
		response.ErrorInternal(c, fmt.Sprintf("build request failed: %v", err))
		return
	}
	if ct := strings.TrimSpace(c.GetHeader("Content-Type")); ct != "" {
		req.Header.Set("Content-Type", ct)
	}
	if rid := c.GetString("request_id"); rid != "" {
		req.Header.Set("X-Request-ID", rid)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		h.log.Warn("proxy_ai_agent_multipart_error", zap.Error(err))
		response.ErrorInternal(c, "ai-agent service unavailable")
		return
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)
	contentType := strings.TrimSpace(resp.Header.Get("Content-Type"))
	if contentType == "" {
		contentType = "application/json; charset=utf-8"
	}
	c.Data(resp.StatusCode, contentType, raw)
}

func maskPhone(phone string) string {
	if len(phone) < 7 {
		return phone
	}
	return phone[:3] + strings.Repeat("*", len(phone)-7) + phone[len(phone)-4:]
}
