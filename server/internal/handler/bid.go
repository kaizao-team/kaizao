package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/aiagent"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/response"
	"github.com/vibebuild/server/internal/service"
	"go.uber.org/zap"
)

const listBidTeamMembersMax = 8

func bidTeamMembersToSlice(members []model.TeamMember) []interface{} {
	if len(members) == 0 {
		return []interface{}{}
	}
	n := len(members)
	if n > listBidTeamMembersMax {
		n = listBidTeamMembersMax
	}
	out := make([]interface{}, 0, n)
	for i := 0; i < n; i++ {
		m := members[i]
		row := gin.H{"role_in_team": m.RoleInTeam}
		if m.User != nil {
			row["user_id"] = m.User.UUID
			row["nickname"] = m.User.Nickname
			if m.User.AvatarURL != nil {
				row["avatar_url"] = *m.User.AvatarURL
			}
		}
		out = append(out, row)
	}
	return out
}

func teamMemberMapsToSlice(members []map[string]interface{}) []interface{} {
	out := make([]interface{}, len(members))
	for i, m := range members {
		out[i] = m
	}
	return out
}

type BidHandler struct {
	bidService     *service.BidService
	projectService *service.ProjectService
	aiAgent        *aiagent.Client
	log            *zap.Logger
}

func NewBidHandler(bidService *service.BidService, projectService *service.ProjectService, aiAgent *aiagent.Client, log *zap.Logger) *BidHandler {
	return &BidHandler{
		bidService:     bidService,
		projectService: projectService,
		aiAgent:        aiAgent,
		log:            log,
	}
}

func (h *BidHandler) ListBids(c *gin.Context) {
	projectID := c.Param("id")
	bids, err := h.bidService.ListByProject(projectID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrProjectNotFound, "项目不存在")
		return
	}
	list := make([]gin.H, 0, len(bids))
	for _, b := range bids {
		item := gin.H{
			"id":            b.UUID,
			"bid_amount":    b.Price,
			"duration_days": b.EstimatedDays,
			"proposal":      b.Proposal,
			"skills":        []string{},
			"created_at":    b.CreatedAt,
		}
		if b.TeamID != nil && b.Team != nil {
			item["bid_type"] = "team"
			item["team_id"] = b.Team.UUID
			item["team_name"] = b.Team.Name
			if b.Team.AvatarURL != nil {
				item["team_avatar_url"] = *b.Team.AvatarURL
			}
			item["team_members"] = bidTeamMembersToSlice(b.Team.Members)
		} else {
			item["bid_type"] = "personal"
			item["team_id"] = nil
			item["team_name"] = nil
			item["team_members"] = []interface{}{}
		}
		if b.Bidder != nil {
			item["user_id"] = b.Bidder.UUID
			item["user_name"] = b.Bidder.Nickname
			item["avatar"] = b.Bidder.AvatarURL
			item["rating"] = b.Bidder.AvgRating
			item["completion_rate"] = b.Bidder.CompletionRate
		}
		list = append(list, item)
	}
	response.Success(c, list)
}

func (h *BidHandler) CreateBid(c *gin.Context) {
	projectID := c.Param("id")
	var req struct {
		Amount       float64 `json:"amount" binding:"required,min=1"`
		DurationDays int     `json:"duration_days" binding:"required,min=1"`
		Proposal     string  `json:"proposal"`
		BidType      string  `json:"bid_type"`
		TeamID       *string `json:"team_id"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	userUUID := c.GetString("user_uuid")
	bid, err := h.bidService.Create(userUUID, projectID, req.Amount, req.DurationDays, req.Proposal, req.BidType, req.TeamID)
	if err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			return
		}
		response.ErrorBadRequest(c, errcode.ErrBidOwnProject, err.Error())
		return
	}
	response.SuccessMsg(c, "投标成功", gin.H{
		"bid_id": bid.UUID,
		"status": "submitted",
	})
}

func (h *BidHandler) AcceptBid(c *gin.Context) {
	bidID := c.Param("bidId")
	userUUID := c.GetString("user_uuid")
	bid, err := h.bidService.Accept(bidID, userUUID)
	if err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			return
		}
		response.ErrorBadRequest(c, errcode.ErrBidNotFound, err.Error())
		return
	}
	_ = bid
	response.SuccessMsg(c, "已选定供给方", gin.H{
		"status": "accepted",
	})
}

func (h *BidHandler) WithdrawBid(c *gin.Context) {
	bidID := c.Param("bidId")
	userUUID := c.GetString("user_uuid")
	if err := h.bidService.Withdraw(bidID, userUUID); err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			return
		}
		response.ErrorBadRequest(c, errcode.ErrBidNotFound, err.Error())
		return
	}
	response.SuccessMsg(c, "投标已撤回", gin.H{"status": "withdrawn"})
}

func (h *BidHandler) AISuggestion(c *gin.Context) {
	projectID := c.Param("id")
	_ = projectID
	response.Success(c, gin.H{
		"suggested_price_min":     4000,
		"suggested_price_max":     8000,
		"suggested_duration_days": 14,
		"skill_match_score":       85,
		"reason":                  "基于项目复杂度和市场行情，建议报价区间为4000-8000元，工期约14天",
	})
}

// Recommendations GET /api/v1/projects/:id/recommendations — 简化匹配：按预算+团队级别降序
func (h *BidHandler) Recommendations(c *gin.Context) {
	projectUUID := c.Param("id")
	ownerUUID := c.GetString("user_uuid")
	project, err := h.projectService.GetPeekIfOwner(projectUUID, ownerUUID)
	if err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code == errcode.ErrProjectOwnerOnly {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			return
		}
		response.ErrorNotFound(c, errcode.ErrProjectNotFound, errcode.GetMessage(errcode.ErrProjectNotFound))
		return
	}

	var q struct {
		Page     int `form:"page"`
		PageSize int `form:"page_size"`
	}
	_ = c.ShouldBindQuery(&q)
	if q.PageSize < 1 {
		q.PageSize = 10
	}
	if q.PageSize > 20 {
		q.PageSize = 20
	}

	budgetMax := 0.0
	if project.BudgetMax != nil {
		budgetMax = *project.BudgetMax
	}
	if budgetMax <= 0 {
		budgetMax = 1e8 // 无上限时不过滤
	}

	results, err := h.bidService.SimpleMatchProviders(budgetMax, q.PageSize)
	if err != nil {
		h.log.Warn("simple_match_failed", zap.Error(err))
		response.ErrorBadRequest(c, errcode.ErrAIServiceUnavailable, "匹配服务调用失败: "+err.Error())
		return
	}

	items := make([]gin.H, 0, len(results))
	for i, r := range results {
		row := gin.H{
			"provider_id":           r.User.UUID,
			"user_id":               r.User.UUID,
			"rank":                  i + 1,
			"match_score":           r.MatchScore,
			"recommendation_reason": r.Reason,
			"highlight_skills":      []string{},
			"bid_type":              "team",
			"team_id":               r.Team.UUID,
			"team_name":             r.Team.Name,
			"team_members":          teamMemberMapsToSlice(r.Members),
		}
		if r.Team.AvatarURL != nil {
			row["team_avatar_url"] = *r.Team.AvatarURL
		}
		row["nickname"] = r.User.Nickname
		row["avatar_url"] = r.User.AvatarURL
		row["rating"] = r.User.AvgRating
		row["completion_rate"] = r.User.CompletionRate
		if ps := h.bidService.PrimarySkillName(r.User.ID); ps != "" {
			row["primary_skill"] = ps
			row["skill"] = ps
		}
		items = append(items, row)
	}

	response.Success(c, gin.H{
		"demand_id":       project.UUID,
		"match_type":      "simple_match",
		"experts":         items,
		"recommendations": items,
	})
}

// QuickMatch POST /api/v1/projects/:id/quick-match — 简化匹配：取最高级别团队方并执行选标撮合
func (h *BidHandler) QuickMatch(c *gin.Context) {
	projectUUID := c.Param("id")
	ownerUUID := c.GetString("user_uuid")
	project, err := h.projectService.GetPeekIfOwner(projectUUID, ownerUUID)
	if err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code == errcode.ErrProjectOwnerOnly {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			return
		}
		response.ErrorNotFound(c, errcode.ErrProjectNotFound, errcode.GetMessage(errcode.ErrProjectNotFound))
		return
	}

	budgetMax := 0.0
	if project.BudgetMax != nil {
		budgetMax = *project.BudgetMax
	}
	if budgetMax <= 0 {
		budgetMax = 1e8
	}

	results, err := h.bidService.SimpleMatchProviders(budgetMax, 10)
	if err != nil {
		h.log.Warn("quick_match_simple_failed", zap.Error(err))
		response.ErrorBadRequest(c, errcode.ErrAIServiceUnavailable, "匹配服务调用失败: "+err.Error())
		return
	}
	if len(results) == 0 {
		response.ErrorBadRequest(c, errcode.ErrQuickMatchNoCandidate, "暂无可匹配团队")
		return
	}

	chosen := results[0]
	bid, err := h.bidService.QuickMatch(ownerUUID, projectUUID, chosen.User.UUID, chosen.Team.ID, chosen.MatchScore, chosen.Reason)
	if err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			return
		}
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, err.Error())
		return
	}

	resp := gin.H{
		"status":                  "accepted",
		"bid_id":                  bid.UUID,
		"provider_id":             chosen.User.UUID,
		"team_id":                 chosen.Team.UUID,
		"team_name":               chosen.Team.Name,
		"match_score":             chosen.MatchScore,
		"recommendation_reason":   chosen.Reason,
		"highlight_skills":        []string{},
		"agreed_price":            bid.Price,
		"estimated_duration_days": bid.EstimatedDays,
	}
	response.SuccessMsg(c, "快速匹配完成，已选定团队", resp)
}

