package handler

import (
	"context"
	"encoding/json"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/aiagent"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/response"
	"github.com/vibebuild/server/internal/service"
	"go.uber.org/zap"
)

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
			"bid_type":      "personal",
			"team_name":     nil,
			"team_members":  []interface{}{},
			"skills":        []string{},
			"created_at":    b.CreatedAt,
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

// Recommendations GET /api/v1/projects/:id/recommendations — 转发 AI-Agent POST /api/v2/match/recommend
func (h *BidHandler) Recommendations(c *gin.Context) {
	if h.aiAgent == nil {
		response.ErrorBadRequest(c, errcode.ErrAIServiceUnavailable, "AI 匹配服务未配置（请设置 ai_agent.base_url 或环境变量 VB_AI_AGENT_BASE_URL）")
		return
	}
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
	if q.Page < 1 {
		q.Page = 1
	}
	if q.PageSize < 1 {
		q.PageSize = 10
	}
	if q.PageSize > 20 {
		q.PageSize = 20
	}

	filters := map[string]interface{}{}
	if skills := parseBidTechReqs(project.TechRequirements); len(skills) > 0 {
		filters["skills"] = skills
	}

	reqID := c.GetString("request_id")
	data, err := h.aiAgent.MatchRecommend(context.Background(), reqID, aiagent.MatchRecommendRequest{
		DemandID:  project.UUID,
		MatchType: "recommend_providers",
		UserID:    ownerUUID,
		Filters:   filters,
		Pagination: map[string]int{
			"page":       q.Page,
			"page_size":  q.PageSize,
		},
	})
	if err != nil {
		h.log.Warn("match_recommend_failed", zap.Error(err))
		response.ErrorBadRequest(c, errcode.ErrAIServiceUnavailable, "AI 推荐服务调用失败: "+err.Error())
		return
	}

	items := make([]gin.H, 0, len(data.Recommendations))
	for _, rec := range data.Recommendations {
		row := gin.H{
			"provider_id":              rec.ProviderID,
			"user_id":                  rec.ProviderID,
			"rank":                     rec.Rank,
			"match_score":              rec.MatchScore,
			"recommendation_reason":    rec.RecommendationReason,
			"highlight_skills":         rec.HighlightSkills,
			"similar_project_reference": rec.SimilarProjectReference,
			"dimension_scores":         rec.DimensionScores,
			"bid_type":                 "personal",
			"team_id":                  nil,
			"team_name":                nil,
		}
		if u, err := h.bidService.FindUserByUUID(rec.ProviderID); err == nil && u != nil {
			row["nickname"] = u.Nickname
			row["avatar_url"] = u.AvatarURL
			row["rating"] = u.AvgRating
			row["completion_rate"] = u.CompletionRate
			if ps := h.bidService.PrimarySkillName(u.ID); ps != "" {
				row["primary_skill"] = ps
				row["skill"] = ps
			}
		}
		items = append(items, row)
	}

	response.Success(c, gin.H{
		"demand_id":           data.DemandID,
		"match_type":          data.MatchType,
		"experts":             items,
		"recommendations":     items,
		"overall_suggestion":  data.OverallSuggestion,
		"no_match_reason":     data.NoMatchReason,
		"meta":                data.Meta,
	})
}

// QuickMatch POST /api/v1/projects/:id/quick-match — AI 推荐最优造物者并执行选标撮合流程
func (h *BidHandler) QuickMatch(c *gin.Context) {
	if h.aiAgent == nil {
		response.ErrorBadRequest(c, errcode.ErrAIServiceUnavailable, "AI 匹配服务未配置（请设置 ai_agent.base_url 或环境变量 VB_AI_AGENT_BASE_URL）")
		return
	}
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

	filters := map[string]interface{}{}
	if skills := parseBidTechReqs(project.TechRequirements); len(skills) > 0 {
		filters["skills"] = skills
	}
	reqID := c.GetString("request_id")
	data, err := h.aiAgent.MatchRecommend(context.Background(), reqID, aiagent.MatchRecommendRequest{
		DemandID:  project.UUID,
		MatchType: "recommend_providers",
		UserID:    ownerUUID,
		Filters:   filters,
		Pagination: map[string]int{
			"page":      1,
			"page_size": 10,
		},
	})
	if err != nil {
		h.log.Warn("quick_match_recommend_failed", zap.Error(err))
		response.ErrorBadRequest(c, errcode.ErrAIServiceUnavailable, "AI 推荐服务调用失败: "+err.Error())
		return
	}
	if len(data.Recommendations) == 0 {
		msg := "暂无可匹配专家"
		if data.NoMatchReason != nil && *data.NoMatchReason != "" {
			msg = *data.NoMatchReason
		}
		response.ErrorBadRequest(c, errcode.ErrQuickMatchNoCandidate, msg)
		return
	}

	var chosen *aiagent.RecommendationItem
	for i := range data.Recommendations {
		rec := &data.Recommendations[i]
		if rec.ProviderID == "" {
			continue
		}
		if _, err := h.bidService.FindUserByUUID(rec.ProviderID); err == nil {
			chosen = rec
			break
		}
	}
	if chosen == nil {
		response.ErrorBadRequest(c, errcode.ErrQuickMatchNoCandidate, "推荐结果中的用户在本平台不存在，请使用「智能推荐」列表手动联系或稍后再试")
		return
	}

	bid, err := h.bidService.QuickMatch(ownerUUID, projectUUID, chosen.ProviderID, chosen.MatchScore, chosen.RecommendationReason)
	if err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			return
		}
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, err.Error())
		return
	}

	response.SuccessMsg(c, "快速匹配完成，已选定服务方", gin.H{
		"status":                  "accepted",
		"bid_id":                  bid.UUID,
		"provider_id":             chosen.ProviderID,
		"match_score":             chosen.MatchScore,
		"recommendation_reason":   chosen.RecommendationReason,
		"highlight_skills":        chosen.HighlightSkills,
		"dimension_scores":        chosen.DimensionScores,
		"agreed_price":            bid.Price,
		"estimated_duration_days": bid.EstimatedDays,
	})
}

func parseBidTechReqs(raw model.JSON) []string {
	var result []string
	if len(raw) > 0 {
		json.Unmarshal([]byte(raw), &result)
	}
	if result == nil {
		return []string{}
	}
	return result
}
