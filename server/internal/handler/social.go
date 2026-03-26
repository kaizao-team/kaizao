package handler

import (
	"encoding/json"

	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/response"
	"github.com/vibebuild/server/internal/service"
	"go.uber.org/zap"
)

type ReviewHandler struct {
	reviewService *service.ReviewService
	log           *zap.Logger
}

func NewReviewHandler(reviewService *service.ReviewService, log *zap.Logger) *ReviewHandler {
	return &ReviewHandler{reviewService: reviewService, log: log}
}

func (h *ReviewHandler) Create(c *gin.Context) {
	var req struct {
		ProjectID     string                   `json:"project_id" binding:"required"`
		RevieweeID    string                   `json:"reviewee_id" binding:"required"`
		OverallRating float64                  `json:"overall_rating" binding:"required,min=1,max=5"`
		Dimensions    []map[string]interface{} `json:"dimensions"`
		Comment       string                   `json:"comment"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	userUUID := c.GetString("user_uuid")
	review, err := h.reviewService.Create(service.CreateReviewReq{
		ProjectUUID:   req.ProjectID,
		ReviewerUUID:  userUUID,
		RevieweeUUID:  req.RevieweeID,
		OverallRating: req.OverallRating,
		Dimensions:    req.Dimensions,
		Comment:       req.Comment,
	})
	if err != nil {
		response.ErrorBadRequest(c, errcode.ErrReviewDuplicate, err.Error())
		return
	}
	response.SuccessMsg(c, "评价提交成功", gin.H{
		"review_id": review.UUID,
	})
}

func (h *ReviewHandler) ListByProject(c *gin.Context) {
	projectID := c.Param("id")
	reviews, err := h.reviewService.ListByProject(projectID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrProjectNotFound, "项目不存在")
		return
	}
	list := make([]gin.H, 0, len(reviews))
	for _, r := range reviews {
		reviewer := gin.H{"id": "", "nickname": "", "role": ""}
		reviewee := gin.H{"id": "", "nickname": "", "role": ""}
		if r.Reviewer != nil {
			role := "demander"
			if r.Reviewer.Role == 2 {
				role = "expert"
			}
			reviewer = gin.H{"id": r.Reviewer.UUID, "nickname": r.Reviewer.Nickname, "role": role}
		}
		if r.Reviewee != nil {
			role := "demander"
			if r.Reviewee.Role == 2 {
				role = "expert"
			}
			reviewee = gin.H{"id": r.Reviewee.UUID, "nickname": r.Reviewee.Nickname, "role": role}
		}
		dims := []gin.H{}
		if r.QualityRating != nil {
			dims = append(dims, gin.H{"name": "代码质量", "rating": *r.QualityRating})
		}
		if r.CommunicationRating != nil {
			dims = append(dims, gin.H{"name": "沟通效率", "rating": *r.CommunicationRating})
		}
		if r.TimelinessRating != nil {
			dims = append(dims, gin.H{"name": "交付时效", "rating": *r.TimelinessRating})
		}
		list = append(list, gin.H{
			"id":             r.UUID,
			"reviewer":       reviewer,
			"reviewee":       reviewee,
			"overall_rating": r.OverallRating,
			"dimensions":     dims,
			"comment":        r.Content,
			"created_at":     r.CreatedAt,
		})
	}
	response.Success(c, list)
}

type TeamHandler struct {
	teamService *service.TeamService
	log         *zap.Logger
}

func NewTeamHandler(teamService *service.TeamService, log *zap.Logger) *TeamHandler {
	return &TeamHandler{teamService: teamService, log: log}
}

func (h *TeamHandler) ListTeams(c *gin.Context) {
	role := c.Query("role")
	data, err := h.teamService.ListTeamPosts(role)
	if err != nil {
		response.ErrorInternal(c, "获取组队列表失败")
		return
	}
	response.Success(c, data)
}

func (h *TeamHandler) CreatePost(c *gin.Context) {
	var req struct {
		ProjectName string                   `json:"project_name" binding:"required"`
		Description string                   `json:"description" binding:"required"`
		NeededRoles []map[string]interface{} `json:"needed_roles"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	userUUID := c.GetString("user_uuid")
	post, err := h.teamService.CreatePost(userUUID, req.ProjectName, req.Description, req.NeededRoles)
	if err != nil {
		response.ErrorInternal(c, "发布失败")
		return
	}
	response.SuccessMsg(c, "寻人帖发布成功", gin.H{
		"id":     post.UUID,
		"status": "recruiting",
	})
}

func (h *TeamHandler) GetDetail(c *gin.Context) {
	teamUUID := c.Param("uuid")
	team, err := h.teamService.GetDetail(teamUUID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrParamInvalid, "组队不存在")
		return
	}
	members := make([]gin.H, 0)
	for _, m := range team.Members {
		nickname := ""
		if m.User != nil {
			nickname = m.User.Nickname
		}
		members = append(members, gin.H{
			"id":        m.UserID,
			"nickname":  nickname,
			"role":      m.RoleInTeam,
			"ratio":     m.SplitRatio,
			"is_leader": m.UserID == team.LeaderID,
			"status":    "accepted",
		})
	}
	statusMap := map[int16]string{1: "recruiting", 2: "confirming", 3: "active"}
	status := statusMap[team.Status]
	if status == "" {
		status = "recruiting"
	}
	response.Success(c, gin.H{
		"id":           team.UUID,
		"project_name": team.Name,
		"project_id":   team.ProjectID,
		"status":       status,
		"members":      members,
	})
}

func (h *TeamHandler) UpdateSplitRatio(c *gin.Context) {
	teamUUID := c.Param("uuid")
	var req struct {
		Ratios []map[string]interface{} `json:"ratios" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	if err := h.teamService.UpdateSplitRatio(teamUUID, req.Ratios); err != nil {
		response.ErrorInternal(c, "更新失败")
		return
	}
	response.SuccessMsg(c, "分成比例已更新", nil)
}

func (h *TeamHandler) Invite(c *gin.Context) {
	teamUUID := c.Param("uuid")
	userUUID := c.GetString("user_uuid")
	if err := h.teamService.Invite(teamUUID, userUUID); err != nil {
		response.ErrorInternal(c, "操作失败")
		return
	}
	response.SuccessMsg(c, "组队确认成功，已通知所有成员", nil)
}

func (h *TeamHandler) RespondInvite(c *gin.Context) {
	inviteUUID := c.Param("id")
	var req struct {
		Accept bool `json:"accept"`
	}
	c.ShouldBindJSON(&req)
	if err := h.teamService.RespondInvite(inviteUUID, req.Accept); err != nil {
		response.ErrorInternal(c, "操作失败")
		return
	}
	msg := "已拒绝邀请"
	if req.Accept {
		msg = "已接受邀请"
	}
	response.SuccessMsg(c, msg, nil)
}

// suppress unused import warning
var _ = json.Marshal
