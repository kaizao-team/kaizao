package handler

import (
	"encoding/json"
	"errors"
	"regexp"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/dto"
	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/response"
	"github.com/vibebuild/server/internal/service"
	"gorm.io/gorm"
)

var cnMobilePattern = regexp.MustCompile(`^1[3-9]\d{9}$`)

// isPortfolioCategoryEnum 作品 category 合法枚举值（更新时若传 category 字段则不可为空串，且须命中其一）
func isPortfolioCategoryEnum(cat string) bool {
	switch cat {
	case "app", "web", "miniprogram", "design", "data", "other":
		return true
	default:
		return false
	}
}

// maskContactPhonePublic 公开资料中的联系电话脱敏（与登录手机号展示规则一致；非 11 位做保守遮挡）
func maskContactPhonePublic(p *string) string {
	if p == nil {
		return ""
	}
	s := strings.TrimSpace(*p)
	if s == "" {
		return ""
	}
	if len(s) >= 11 {
		return s[:3] + "****" + s[7:]
	}
	if len(s) >= 7 {
		return s[:2] + "****" + s[len(s)-2:]
	}
	return "****"
}

// userSkillsToResponse 用户技能列表（GET /users/me 与 GET /users/:id/skills 共用）
func userSkillsToResponse(skills []*model.UserSkill) []gin.H {
	list := make([]gin.H, 0, len(skills))
	for _, s := range skills {
		list = append(list, gin.H{
			"id":                  s.Skill.ID,
			"skill_id":            s.SkillID,
			"name":                s.Skill.Name,
			"category":            s.Skill.Category,
			"proficiency":         s.Proficiency,
			"years_of_experience": s.YearsOfExperience,
			"is_primary":          s.IsPrimary,
		})
	}
	return list
}

func (h *UserHandler) GetProfile(c *gin.Context) {
	userID := c.Param("id")
	user, err := h.userService.GetByUUID(userID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrUserNotFound, "用户不存在")
		return
	}
	phone := ""
	if user.Phone != nil {
		p := *user.Phone
		if len(p) >= 11 {
			phone = p[:3] + "****" + p[7:]
		}
	}
	stats := h.userService.GetUserStats(user)
	response.Success(c, gin.H{
		"id":             user.UUID,
		"nickname":       user.Nickname,
		"avatar":         user.AvatarURL,
		"tagline":        user.Bio,
		"role":           user.Role,
		"rating":         user.AvgRating,
		"credit_score":   user.CreditScore,
		"is_verified":    user.IsVerified,
		"phone":          phone,
		"contact_phone":  maskContactPhonePublic(user.ContactPhone),
		"wechat_bound":   user.WechatOpenID != nil,
		"stats":        stats,
		"bio":          user.Bio,
		"created_at":   user.CreatedAt,
	})
}

func (h *UserHandler) UpdateProfile(c *gin.Context) {
	targetUUID := c.Param("id")
	var req struct {
		Nickname     *string `json:"nickname"`
		Tagline      *string `json:"tagline"`
		Bio          *string `json:"bio"`
		ContactPhone *string `json:"contact_phone"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	fields := make(map[string]interface{})
	if req.Nickname != nil {
		fields["nickname"] = *req.Nickname
	}
	if req.Tagline != nil {
		fields["bio"] = *req.Tagline
	}
	if req.Bio != nil {
		fields["bio"] = *req.Bio
	}
	if req.ContactPhone != nil {
		cp := strings.TrimSpace(*req.ContactPhone)
		if cp == "" {
			fields["contact_phone"] = nil
		} else {
			if len(cp) > 20 {
				response.ErrorBadRequest(c, errcode.ErrParamInvalid, "联系电话过长")
				return
			}
			if !cnMobilePattern.MatchString(cp) {
				response.ErrorBadRequest(c, errcode.ErrPhoneFormat, errcode.GetMessage(errcode.ErrPhoneFormat))
				return
			}
			fields["contact_phone"] = cp
		}
	}
	if len(fields) == 0 {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "无可更新字段")
		return
	}
	updated, err := h.userService.UpdateProfile(targetUUID, fields, nil)
	if err != nil {
		response.ErrorInternal(c, "更新失败")
		return
	}
	response.SuccessMsg(c, "资料更新成功", gin.H{
		"id":       updated.UUID,
		"nickname": updated.Nickname,
		"bio":      updated.Bio,
	})
}

func (h *UserHandler) GetSkills(c *gin.Context) {
	userID := c.Param("id")
	user, err := h.userService.GetByUUID(userID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrUserNotFound, "用户不存在")
		return
	}
	skills, _ := h.userService.ListUserSkills(user.ID)
	response.Success(c, userSkillsToResponse(skills))
}

func (h *UserHandler) UpdateSkills(c *gin.Context) {
	// 静态路由 PUT /users/me/skills 优先于 /users/:id/skills，此时 c.Param("id") 为空；
	// 若 id 为 me 或为空，均视为当前登录用户。
	targetUUID := c.Param("id")
	if targetUUID == "" || targetUUID == "me" {
		targetUUID = c.GetString("user_uuid")
	}
	var req struct {
		Skills []struct {
			SkillID           *int64      `json:"skill_id"`
			ID                interface{} `json:"id"`
			Name              string      `json:"name"`
			Category          string      `json:"category"`
			Proficiency       *int        `json:"proficiency"`
			YearsOfExperience *int        `json:"years_of_experience"`
			IsPrimary         bool        `json:"is_primary"`
		} `json:"skills" binding:"required,max=20"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	items := make([]service.ReplaceUserSkillsItem, 0, len(req.Skills))
	for _, s := range req.Skills {
		it := service.ReplaceUserSkillsItem{
			SkillID:   s.SkillID,
			ID:        s.ID,
			Name:      s.Name,
			Category:  s.Category,
			IsPrimary: s.IsPrimary,
		}
		if s.Proficiency != nil {
			it.Proficiency = int16(*s.Proficiency)
		}
		if s.YearsOfExperience != nil {
			it.YearsOfExperience = int16(*s.YearsOfExperience)
		}
		items = append(items, it)
	}
	if err := h.userService.ReplaceUserSkills(targetUUID, items); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.ErrorNotFound(c, errcode.ErrUserNotFound, "用户不存在")
			return
		}
		if strings.Contains(err.Error(), "no valid skills") {
			response.ErrorBadRequest(c, errcode.ErrParamInvalid, "没有有效的技能项")
			return
		}
		response.ErrorInternal(c, "技能更新失败")
		return
	}
	response.SuccessMsg(c, "技能更新成功", nil)
}

func portfolioTechToSlice(raw model.JSON) []string {
	if len(raw) == 0 {
		return []string{}
	}
	var out []string
	if err := json.Unmarshal(raw, &out); err != nil {
		return []string{}
	}
	return out
}

func portfolioImagesForResponse(raw model.JSON) []dto.ImageItem {
	if len(raw) == 0 {
		return []dto.ImageItem{}
	}
	var out []dto.ImageItem
	if err := json.Unmarshal(raw, &out); err != nil {
		return []dto.ImageItem{}
	}
	return out
}

func (h *UserHandler) portfolioListItem(p *model.Portfolio) gin.H {
	tech := portfolioTechToSlice(p.TechStack)
	return gin.H{
		"id":             p.UUID,
		"title":          p.Title,
		"cover_url":      p.CoverURL,
		"description":    p.Description,
		"category":       p.Category,
		"tags":           tech,
		"tech_stack":     tech,
		"preview_url":    p.PreviewURL,
		"demo_video_url": p.DemoVideoURL,
		"images":         portfolioImagesForResponse(p.Images),
		"created_at":     p.CreatedAt,
	}
}

// GetMyPortfolios GET /api/v1/users/me/portfolios（须登录）
func (h *UserHandler) GetMyPortfolios(c *gin.Context) {
	userUUID := c.GetString("user_uuid")
	if userUUID == "" {
		response.ErrorUnauthorized(c, errcode.ErrTokenInvalid, "缺少认证信息")
		return
	}
	h.respondPortfoliosForUser(c, userUUID)
}

func (h *UserHandler) respondPortfoliosForUser(c *gin.Context, userUUID string) {
	user, err := h.userService.GetByUUID(userUUID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrUserNotFound, "用户不存在")
		return
	}
	portfolios, _ := h.userService.ListUserPortfolios(user.ID)
	list := make([]gin.H, 0, len(portfolios))
	for _, p := range portfolios {
		list = append(list, h.portfolioListItem(p))
	}
	response.Success(c, list)
}

// GetPortfolios GET /api/v1/users/:id/portfolios；:id 为 me 时需携带 Token
func (h *UserHandler) GetPortfolios(c *gin.Context) {
	userID := strings.TrimSpace(c.Param("id"))
	if userID == "me" {
		userID = c.GetString("user_uuid")
		if userID == "" {
			response.ErrorUnauthorized(c, errcode.ErrTokenInvalid, "查看自己的作品集需要登录")
			return
		}
	}
	h.respondPortfoliosForUser(c, userID)
}

// CreatePortfolio POST /api/v1/users/me/portfolios
func (h *UserHandler) CreatePortfolio(c *gin.Context) {
	userUUID := c.GetString("user_uuid")
	user, err := h.userService.GetByUUID(userUUID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrUserNotFound, "用户不存在")
		return
	}
	var req dto.CreatePortfolioReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	title := strings.TrimSpace(req.Title)
	if title == "" {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "标题不能为空")
		return
	}
	category := strings.TrimSpace(req.Category)
	if category == "" {
		category = "other"
	}
	var descPtr *string
	if t := strings.TrimSpace(req.Description); t != "" {
		descPtr = &t
	}
	var coverPtr *string
	if t := strings.TrimSpace(req.CoverURL); t != "" {
		coverPtr = &t
	}
	var previewPtr *string
	if t := strings.TrimSpace(req.PreviewURL); t != "" {
		previewPtr = &t
	}
	var demoPtr *string
	if t := strings.TrimSpace(req.DemoVideoURL); t != "" {
		demoPtr = &t
	}
	var techStackJSON model.JSON
	if len(req.TechStack) > 0 {
		b, err := json.Marshal(req.TechStack)
		if err != nil {
			response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
			return
		}
		techStackJSON = model.JSON(b)
	}
	var imagesJSON model.JSON
	if len(req.Images) > 0 {
		b, err := json.Marshal(req.Images)
		if err != nil {
			response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
			return
		}
		imagesJSON = model.JSON(b)
	}
	p := &model.Portfolio{
		UserID:       user.ID,
		Title:        title,
		Description:  descPtr,
		Category:     category,
		CoverURL:     coverPtr,
		PreviewURL:   previewPtr,
		TechStack:    techStackJSON,
		Images:       imagesJSON,
		DemoVideoURL: demoPtr,
		Status:       1,
	}
	if err := h.userService.CreatePortfolio(p); err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code == errcode.ErrPortfolioExceedLimit {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			return
		}
		response.ErrorInternal(c, "创建作品失败")
		return
	}
	response.SuccessMsg(c, "作品创建成功", gin.H{
		"id":    p.UUID,
		"title": p.Title,
	})
}

// UpdatePortfolio PUT /api/v1/users/me/portfolios/:uuid
func (h *UserHandler) UpdatePortfolio(c *gin.Context) {
	userUUID := c.GetString("user_uuid")
	portfolioUUID := c.Param("uuid")
	user, err := h.userService.GetByUUID(userUUID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrUserNotFound, "用户不存在")
		return
	}
	portfolio, err := h.userService.FindPortfolioByUUID(portfolioUUID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrParamInvalid, "作品不存在")
		return
	}
	if portfolio.UserID != user.ID {
		response.ErrorForbidden(c, errcode.ErrParamInvalid, "无权操作他人作品")
		return
	}
	var req dto.UpdatePortfolioReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	fields := make(map[string]interface{})
	if req.Title != nil {
		t := strings.TrimSpace(*req.Title)
		if t == "" {
			response.ErrorBadRequest(c, errcode.ErrParamInvalid, "标题不能为空")
			return
		}
		fields["title"] = t
	}
	if req.Description != nil {
		fields["description"] = *req.Description
	}
	if req.Category != nil {
		cat := strings.TrimSpace(*req.Category)
		if cat == "" {
			response.ErrorBadRequest(c, errcode.ErrParamInvalid, "category 不能为空")
			return
		}
		if !isPortfolioCategoryEnum(cat) {
			response.ErrorBadRequest(c, errcode.ErrParamInvalid, "category 无效")
			return
		}
		fields["category"] = cat
	}
	if req.CoverURL != nil {
		if strings.TrimSpace(*req.CoverURL) == "" {
			fields["cover_url"] = nil
		} else {
			fields["cover_url"] = strings.TrimSpace(*req.CoverURL)
		}
	}
	if req.PreviewURL != nil {
		if strings.TrimSpace(*req.PreviewURL) == "" {
			fields["preview_url"] = nil
		} else {
			fields["preview_url"] = strings.TrimSpace(*req.PreviewURL)
		}
	}
	if req.DemoVideoURL != nil {
		if strings.TrimSpace(*req.DemoVideoURL) == "" {
			fields["demo_video_url"] = nil
		} else {
			fields["demo_video_url"] = strings.TrimSpace(*req.DemoVideoURL)
		}
	}
	if req.TechStack != nil {
		b, err := json.Marshal(*req.TechStack)
		if err != nil {
			response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
			return
		}
		fields["tech_stack"] = model.JSON(b)
	}
	if req.Images != nil {
		b, err := json.Marshal(*req.Images)
		if err != nil {
			response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
			return
		}
		fields["images"] = model.JSON(b)
	}
	if len(fields) == 0 {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "无可更新字段")
		return
	}
	if err := h.userService.UpdatePortfolioFields(portfolio.ID, fields); err != nil {
		response.ErrorInternal(c, "更新失败")
		return
	}
	response.SuccessMsg(c, "作品更新成功", gin.H{"id": portfolio.UUID})
}

// DeletePortfolio DELETE /api/v1/users/me/portfolios/:uuid
func (h *UserHandler) DeletePortfolio(c *gin.Context) {
	userUUID := c.GetString("user_uuid")
	portfolioUUID := c.Param("uuid")
	user, err := h.userService.GetByUUID(userUUID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrUserNotFound, "用户不存在")
		return
	}
	portfolio, err := h.userService.FindPortfolioByUUID(portfolioUUID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrParamInvalid, "作品不存在")
		return
	}
	if portfolio.UserID != user.ID {
		response.ErrorForbidden(c, errcode.ErrParamInvalid, "无权操作他人作品")
		return
	}
	if err := h.userService.UpdatePortfolioFields(portfolio.ID, map[string]interface{}{"status": 0}); err != nil {
		response.ErrorInternal(c, "删除失败")
		return
	}
	response.SuccessMsg(c, "作品已删除", nil)
}

// SubmitOnboardingApplication POST /api/v1/users/me/onboarding/application
func (h *UserHandler) SubmitOnboardingApplication(c *gin.Context) {
	userUUID := c.GetString("user_uuid")
	var req struct {
		ResumeURL       string   `json:"resume_url"`
		Note            string   `json:"note"`
		PortfolioUUIDs  []string `json:"portfolio_uuids"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	var resumePtr *string
	if t := strings.TrimSpace(req.ResumeURL); t != "" {
		resumePtr = &t
	}
	var notePtr *string
	if t := strings.TrimSpace(req.Note); t != "" {
		notePtr = &t
	}
	if err := h.userService.SubmitOnboardingApplication(userUUID, resumePtr, notePtr, req.PortfolioUUIDs); err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			return
		}
		response.ErrorInternal(c, "提交失败")
		return
	}
	response.SuccessMsg(c, "已提交审核", nil)
}

// RedeemOnboardingInvite POST /api/v1/users/me/onboarding/redeem-invite
func (h *UserHandler) RedeemOnboardingInvite(c *gin.Context) {
	userUUID := c.GetString("user_uuid")
	var req struct {
		InviteCode string `json:"invite_code" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	if err := h.userService.RedeemTeamInviteForOnboarding(userUUID, req.InviteCode); err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			return
		}
		response.ErrorInternal(c, "兑换失败")
		return
	}
	response.SuccessMsg(c, "已通过团队邀请完成入驻", nil)
}

// ListExperts 专家列表（以团队为主实体）
// GET /api/v1/market/experts
func (h *UserHandler) ListExperts(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 50 {
		pageSize = 20
	}

	teams, total, err := h.userService.ListExpertTeams(page, pageSize)
	if err != nil {
		response.ErrorInternal(c, "获取专家列表失败")
		return
	}

	leaderIDs := make([]int64, 0, len(teams))
	for _, t := range teams {
		leaderIDs = append(leaderIDs, t.LeaderID)
	}
	allSkills, _ := h.repos.User.ListUserSkillsForUsers(leaderIDs)
	skillsByUser := groupSkillsByUser(allSkills)

	expertList := make([]gin.H, 0, len(teams))
	for _, t := range teams {
		leader := t.Leader
		item := gin.H{
			"id":           t.UUID,
			"team_name":    t.Name,
			"vibe_level":   t.VibeLevel,
			"vibe_power":   t.VibePower,
			"member_count": t.MemberCount,
			"rating":       t.AvgRating,
			"hourly_rate":  t.HourlyRate,
			"budget_min":   t.BudgetMin,
			"budget_max":   t.BudgetMax,
		}
		if leader != nil {
			item["leader_uuid"] = leader.UUID
			item["nickname"] = leader.Nickname
			item["avatar_url"] = leader.AvatarURL
			item["completed_projects"] = leader.CompletedOrders
			item["tagline"] = leader.Bio

			skills := skillsByUser[leader.ID]
			skillNames := make([]string, 0, len(skills))
			for _, s := range skills {
				if s.Skill.Name != "" {
					skillNames = append(skillNames, s.Skill.Name)
				}
			}
			item["skills"] = skillNames
		}
		expertList = append(expertList, item)
	}

	response.SuccessWithMeta(c, expertList, response.BuildMeta(page, pageSize, total))
}

func groupSkillsByUser(skills []*model.UserSkill) map[int64][]*model.UserSkill {
	m := make(map[int64][]*model.UserSkill)
	for _, s := range skills {
		m[s.UserID] = append(m[s.UserID], s)
	}
	return m
}

// AddFavorite POST /api/v1/favorites
func (h *UserHandler) AddFavorite(c *gin.Context) {
	userUUID := c.GetString("user_uuid")
	user, err := h.userService.GetByUUID(userUUID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrUserNotFound, "用户不存在")
		return
	}
	var req struct {
		TargetType string `json:"target_type" binding:"required"`
		TargetID   string `json:"target_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	if req.TargetType != "project" && req.TargetType != "expert" {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "target_type 仅支持 project / expert")
		return
	}

	outcome, err := h.favoriteService.AddFavorite(user.ID, req.TargetType, req.TargetID)
	if err != nil {
		if code, convErr := strconv.Atoi(err.Error()); convErr == nil && code > 0 {
			switch code {
			case errcode.ErrProjectNotFound:
				response.ErrorNotFound(c, code, errcode.GetMessage(code))
			case errcode.ErrUserNotFound:
				response.ErrorNotFound(c, code, errcode.GetMessage(code))
			case errcode.ErrFavoriteExpertInvalid:
				response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			case errcode.ErrParamInvalid:
				response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			default:
				response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			}
			return
		}
		response.ErrorInternal(c, "收藏失败")
		return
	}
	if outcome.AlreadyFavorited {
		response.SuccessMsg(c, "已收藏", gin.H{"id": outcome.UUID})
		return
	}
	response.SuccessMsg(c, "收藏成功", gin.H{"id": outcome.UUID})
}

// RemoveFavorite DELETE /api/v1/favorites
func (h *UserHandler) RemoveFavorite(c *gin.Context) {
	userUUID := c.GetString("user_uuid")
	user, err := h.userService.GetByUUID(userUUID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrUserNotFound, "用户不存在")
		return
	}
	var req struct {
		TargetType string `json:"target_type" binding:"required"`
		TargetID   string `json:"target_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}

	err = h.favoriteService.RemoveFavorite(user.ID, req.TargetType, req.TargetID)
	if err != nil {
		if code, convErr := strconv.Atoi(err.Error()); convErr == nil && code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			return
		}
		response.ErrorInternal(c, "取消收藏失败")
		return
	}
	response.SuccessMsg(c, "已取消收藏", nil)
}

// ListMyFavorites GET /api/v1/users/me/favorites
func (h *UserHandler) ListMyFavorites(c *gin.Context) {
	userUUID := c.GetString("user_uuid")
	user, err := h.userService.GetByUUID(userUUID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrUserNotFound, "用户不存在")
		return
	}
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 50 {
		pageSize = 20
	}
	targetType := c.Query("target_type")

	favs, total, err := h.repos.Favorite.ListByUserID(user.ID, targetType, (page-1)*pageSize, pageSize)
	if err != nil {
		response.ErrorInternal(c, "获取收藏列表失败")
		return
	}

	list := make([]gin.H, 0, len(favs))
	for _, f := range favs {
		item := gin.H{
			"id":          f.UUID,
			"target_type": f.TargetType,
			"target_id":   f.TargetID,
			"created_at":  f.CreatedAt,
		}
		if f.TargetType == "project" {
			if p, err := h.repos.Project.FindByUUID(f.TargetID); err == nil {
				item["title"] = p.Title
				item["status"] = p.Status
				item["category"] = p.Category
				item["budget_min"] = p.BudgetMin
				item["budget_max"] = p.BudgetMax
			}
		} else if f.TargetType == "expert" {
			if t, err := h.repos.Team.FindByUUID(f.TargetID); err == nil {
				item["team_name"] = t.Name
				if t.Leader != nil {
					item["nickname"] = t.Leader.Nickname
					item["avatar_url"] = t.Leader.AvatarURL
					item["rating"] = t.Leader.AvgRating
				}
			}
		}
		list = append(list, item)
	}

	response.SuccessWithMeta(c, list, response.BuildMeta(page, pageSize, total))
}
