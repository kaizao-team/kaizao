package handler

import (
	"encoding/json"

	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/dto"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/response"
	"github.com/vibebuild/server/internal/service"
	"go.uber.org/zap"
)

// ProjectHandler 项目处理器
type ProjectHandler struct {
	projectService *service.ProjectService
	log            *zap.Logger
}

// NewProjectHandler 创建项目处理器
func NewProjectHandler(projectService *service.ProjectService, log *zap.Logger) *ProjectHandler {
	return &ProjectHandler{projectService: projectService, log: log}
}

// Create 创建项目/发布需求
func (h *ProjectHandler) Create(c *gin.Context) {
	var req dto.CreateProjectReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrProjectTitleEmpty, "参数校验失败: "+err.Error())
		return
	}

	userUUID := c.GetString("user_uuid")

	project, err := h.projectService.Create(
		userUUID, req.Title, req.Description, req.Category,
		req.BudgetMin, req.BudgetMax, req.MatchMode, req.IsDraft,
	)
	if err != nil {
		response.ErrorInternal(c, "创建项目失败")
		return
	}

	statusText := map[int16]string{1: "草稿", 2: "已发布"}

	resp := dto.ProjectResp{
		UUID:        project.UUID,
		Title:       project.Title,
		Description: project.Description,
		Category:    project.Category,
		BudgetMin:   project.BudgetMin,
		BudgetMax:   project.BudgetMax,
		Status:      project.Status,
		StatusText:  statusText[project.Status],
		MatchMode:   project.MatchMode,
		PublishedAt: project.PublishedAt,
		CreatedAt:   project.CreatedAt,
	}

	response.Success(c, resp)
}

// List 项目列表
func (h *ProjectHandler) List(c *gin.Context) {
	var query dto.ProjectListQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		query.Page = 1
		query.PageSize = 20
		query.SortBy = "published_at"
		query.SortOrder = "desc"
	}

	conditions := make(map[string]interface{})
	if query.Category != "" {
		conditions["category"] = query.Category
	}
	if query.Status > 0 {
		conditions["status"] = query.Status
	}
	if query.MatchMode > 0 {
		conditions["match_mode"] = query.MatchMode
	}

	projects, total, err := h.projectService.List(query.Page, query.PageSize, conditions, query.SortBy, query.SortOrder)
	if err != nil {
		response.ErrorInternal(c, "获取项目列表失败")
		return
	}

	var list []dto.ProjectResp
	for _, p := range projects {
		var techReqs []string
		if len(p.TechRequirements) > 0 {
			json.Unmarshal([]byte(p.TechRequirements), &techReqs)
		}

		item := dto.ProjectResp{
			UUID:             p.UUID,
			Title:            p.Title,
			Description:      p.Description,
			Category:         p.Category,
			Complexity:       p.Complexity,
			BudgetMin:        p.BudgetMin,
			BudgetMax:        p.BudgetMax,
			TechRequirements: techReqs,
			Status:           p.Status,
			MatchMode:        p.MatchMode,
			ViewCount:        p.ViewCount,
			BidCount:         p.BidCount,
			PublishedAt:      p.PublishedAt,
			CreatedAt:        p.CreatedAt,
		}
		if p.Owner != nil {
			item.Owner = &dto.UserBriefResp{
				UUID:      p.Owner.UUID,
				Nickname:  p.Owner.Nickname,
				AvatarURL: p.Owner.AvatarURL,
			}
		}
		list = append(list, item)
	}

	if list == nil {
		list = []dto.ProjectResp{}
	}

	response.SuccessWithMeta(c, dto.ListData{List: list}, response.BuildMeta(query.Page, query.PageSize, total))
}

// Get 项目详情
func (h *ProjectHandler) Get(c *gin.Context) {
	uuid := c.Param("uuid")

	project, err := h.projectService.GetByUUID(uuid)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrProjectNotFound, errcode.GetMessage(errcode.ErrProjectNotFound))
		return
	}

	resp := dto.ProjectResp{
		UUID:          project.UUID,
		Title:         project.Title,
		Description:   project.Description,
		Category:      project.Category,
		Complexity:    project.Complexity,
		BudgetMin:     project.BudgetMin,
		BudgetMax:     project.BudgetMax,
		AgreedPrice:   project.AgreedPrice,
		Deadline:      project.Deadline,
		Status:        project.Status,
		MatchMode:     project.MatchMode,
		Progress:      project.Progress,
		ViewCount:     project.ViewCount,
		BidCount:      project.BidCount,
		FavoriteCount: project.FavoriteCount,
		PublishedAt:   project.PublishedAt,
		CreatedAt:     project.CreatedAt,
	}
	if project.Owner != nil {
		resp.Owner = &dto.UserBriefResp{
			UUID:       project.Owner.UUID,
			Nickname:   project.Owner.Nickname,
			AvatarURL:  project.Owner.AvatarURL,
			IsVerified: project.Owner.IsVerified,
		}
	}

	response.Success(c, resp)
}

// Update 更新项目
func (h *ProjectHandler) Update(c *gin.Context) {
	uuid := c.Param("uuid")

	var req dto.UpdateProjectReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrProjectTitleEmpty, "参数校验失败")
		return
	}

	fields := make(map[string]interface{})
	if req.Title != nil {
		fields["title"] = *req.Title
	}
	if req.Description != nil {
		fields["description"] = *req.Description
	}
	if req.Category != nil {
		fields["category"] = *req.Category
	}
	if req.BudgetMin != nil {
		fields["budget_min"] = *req.BudgetMin
	}
	if req.BudgetMax != nil {
		fields["budget_max"] = *req.BudgetMax
	}

	project, err := h.projectService.Update(uuid, fields)
	if err != nil {
		response.ErrorInternal(c, "更新项目失败")
		return
	}

	response.Success(c, dto.ProjectResp{
		UUID:        project.UUID,
		Title:       project.Title,
		Description: project.Description,
		Category:    project.Category,
		Status:      project.Status,
		CreatedAt:   project.CreatedAt,
	})
}

// Close 关闭项目
func (h *ProjectHandler) Close(c *gin.Context) {
	uuid := c.Param("uuid")

	var req dto.CloseProjectReq
	c.ShouldBindJSON(&req)

	if err := h.projectService.Close(uuid, req.Reason); err != nil {
		response.ErrorInternal(c, "关闭项目失败")
		return
	}

	response.Success(c, nil)
}
