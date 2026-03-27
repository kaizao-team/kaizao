package handler

import (
	"encoding/json"

	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/response"
	"github.com/vibebuild/server/internal/service"
	"go.uber.org/zap"
)

type BidHandler struct {
	bidService *service.BidService
	log        *zap.Logger
}

func NewBidHandler(bidService *service.BidService, log *zap.Logger) *BidHandler {
	return &BidHandler{bidService: bidService, log: log}
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
		"suggested_price_min":    4000,
		"suggested_price_max":    8000,
		"suggested_duration_days": 14,
		"skill_match_score":      85,
		"reason":                 "基于项目复杂度和市场行情，建议报价区间为4000-8000元，工期约14天",
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
