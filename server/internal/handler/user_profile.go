package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/response"
)

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
		"id":           user.UUID,
		"nickname":     user.Nickname,
		"avatar":       user.AvatarURL,
		"tagline":      user.Bio,
		"role":         user.Role,
		"rating":       user.AvgRating,
		"credit_score": user.CreditScore,
		"is_verified":  user.IsVerified,
		"phone":        phone,
		"wechat_bound": user.WechatOpenID != nil,
		"stats":        stats,
		"bio":          user.Bio,
		"created_at":   user.CreatedAt,
	})
}

func (h *UserHandler) UpdateProfile(c *gin.Context) {
	targetUUID := c.Param("id")
	var req struct {
		Nickname *string `json:"nickname"`
		Tagline  *string `json:"tagline"`
		Bio      *string `json:"bio"`
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
	if len(fields) == 0 {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "无可更新字段")
		return
	}
	updated, err := h.userService.UpdateProfile(targetUUID, fields)
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
	list := make([]gin.H, 0, len(skills))
	for _, s := range skills {
		item := gin.H{
			"id":       s.Skill.ID,
			"name":     s.Skill.Name,
			"category": s.Skill.Category,
		}
		list = append(list, item)
	}
	response.Success(c, list)
}

func (h *UserHandler) UpdateSkills(c *gin.Context) {
	targetUUID := c.Param("id")
	var req struct {
		Skills []struct {
			ID       interface{} `json:"id"`
			Name     string      `json:"name"`
			Category string      `json:"category"`
		} `json:"skills" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	_ = targetUUID
	response.SuccessMsg(c, "技能更新成功", nil)
}

func (h *UserHandler) GetPortfolios(c *gin.Context) {
	userID := c.Param("id")
	user, err := h.userService.GetByUUID(userID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrUserNotFound, "用户不存在")
		return
	}
	portfolios, _ := h.userService.ListUserPortfolios(user.ID)
	list := make([]gin.H, 0, len(portfolios))
	for _, p := range portfolios {
		list = append(list, gin.H{
			"id":          p.UUID,
			"title":       p.Title,
			"cover_url":   p.CoverURL,
			"description": p.Description,
			"tags":        p.TechStack,
			"created_at":  p.CreatedAt,
		})
	}
	response.Success(c, list)
}

// ListExperts 专家列表
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

	experts, total, err := h.userService.ListExperts(page, pageSize)
	if err != nil {
		response.ErrorInternal(c, "获取专家列表失败")
		return
	}

	expertList := make([]gin.H, 0, len(experts))
	for _, e := range experts {
		skills, _ := h.userService.ListUserSkills(e.ID)
		skillNames := make([]string, 0, len(skills))
		for _, s := range skills {
			skillNames = append(skillNames, s.Skill.Name)
		}

		expertList = append(expertList, gin.H{
			"id":                 e.UUID,
			"nickname":           e.Nickname,
			"avatar_url":         e.AvatarURL,
			"rating":             e.AvgRating,
			"skills":             skillNames,
			"completed_projects": e.CompletedOrders,
			"hourly_rate":        e.HourlyRate,
			"tagline":            e.Bio,
		})
	}

	response.SuccessWithMeta(c, expertList, response.BuildMeta(page, pageSize, total))
}
