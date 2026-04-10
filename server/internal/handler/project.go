package handler

import (
	"encoding/json"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/dto"
	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/response"
	"github.com/vibebuild/server/internal/repository"
	"github.com/vibebuild/server/internal/service"
	"go.uber.org/zap"
)

// ProjectHandler 项目处理器
type ProjectHandler struct {
	projectService     *service.ProjectService
	projectFileService *service.ProjectFileService
	milestoneService   *service.MilestoneService
	log                *zap.Logger
}

// NewProjectHandler 创建项目处理器
func NewProjectHandler(projectService *service.ProjectService, projectFileService *service.ProjectFileService, milestoneService *service.MilestoneService, log *zap.Logger) *ProjectHandler {
	return &ProjectHandler{projectService: projectService, projectFileService: projectFileService, milestoneService: milestoneService, log: log}
}

// Create 创建项目/发布需求
// POST /api/v1/projects
func (h *ProjectHandler) Create(c *gin.Context) {
	var req dto.CreateProjectReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrProjectTitleEmpty, "参数校验失败: "+err.Error())
		return
	}

	userUUID := c.GetString("user_uuid")

	project, err := h.projectService.Create(
		userUUID, req.Title, req.Description, req.Category,
		req.BudgetMin, req.BudgetMax, req.TechRequirements, req.MatchMode, req.IsDraft,
	)
	if err != nil {
		response.ErrorInternal(c, "创建项目失败")
		return
	}

	response.SuccessMsg(c, "项目发布成功", gin.H{
		"id":     project.UUID,
		"uuid":   project.UUID,
		"status": project.Status,
	})
}

// List 项目列表
// GET /api/v1/projects
// 须登录。未传 role：当前用户作为 owner 或 provider 的项目并集，可叠加 category/status/match_mode。
// 支持 role: 1=仅需求方(owner)，2=仅服务方(provider)；0 或非法值返回空列表。
func (h *ProjectHandler) List(c *gin.Context) {
	var query dto.ProjectListQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		query.Page = 1
		query.PageSize = 20
		query.SortBy = "published_at"
		query.SortOrder = "desc"
	}
	if query.Page == 0 {
		query.Page = 1
	}
	if query.PageSize == 0 {
		query.PageSize = 20
	}

	userUUID := c.GetString("user_uuid")
	if userUUID == "" {
		response.ErrorUnauthorized(c, errcode.ErrTokenInvalid, "缺少认证信息")
		return
	}

	_, rolePresent := c.GetQuery("role")
	role, _ := strconv.Atoi(c.Query("role"))

	if rolePresent {
		if role == 1 || role == 2 {
			projects, total, err := h.projectService.ListByRole(userUUID, role, query.Page, query.PageSize)
			if err != nil {
				response.ErrorInternal(c, "获取项目列表失败")
				return
			}
			list := toProjectRespList(projects)
			response.SuccessWithMeta(c, list, response.BuildMeta(query.Page, query.PageSize, total))
			return
		}
		response.SuccessWithMeta(c, toProjectRespList(nil), response.BuildMeta(query.Page, query.PageSize, 0))
		return
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

	projects, total, err := h.projectService.ListMine(userUUID, query.Page, query.PageSize, conditions, query.SortBy, query.SortOrder)
	if err != nil {
		response.ErrorInternal(c, "获取项目列表失败")
		return
	}

	list := toProjectRespList(projects)
	response.SuccessWithMeta(c, list, response.BuildMeta(query.Page, query.PageSize, total))
}

// Get 项目详情
// GET /api/v1/projects/:id
func (h *ProjectHandler) Get(c *gin.Context) {
	idStr := c.Param("id")
	userUUID := c.GetString("user_uuid")

	var p *model.Project
	if numID, err := strconv.ParseInt(idStr, 10, 64); err == nil {
		p, err = h.projectService.GetByID(numID)
		if err != nil {
			response.ErrorNotFound(c, errcode.ErrProjectNotFound, errcode.GetMessage(errcode.ErrProjectNotFound))
			return
		}
	} else {
		var err2 error
		p, err2 = h.projectService.GetByUUID(idStr)
		if err2 != nil {
			response.ErrorNotFound(c, errcode.ErrProjectNotFound, errcode.GetMessage(errcode.ErrProjectNotFound))
			return
		}
	}

	isParticipant := h.projectService.IsParticipant(p.UUID, userUUID)
	response.Success(c, h.buildProjectDetail(p, userUUID, isParticipant))
}

// Update 更新项目
// PUT /api/v1/projects/:id
func (h *ProjectHandler) Update(c *gin.Context) {
	uuid := c.Param("id")

	var req dto.UpdateProjectReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrProjectTitleEmpty, "参数校验失败: "+err.Error())
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
	if req.MatchMode != nil {
		fields["match_mode"] = int16(*req.MatchMode)
	}

	project, err := h.projectService.Update(uuid, fields)
	if err != nil {
		response.ErrorInternal(c, "更新项目失败")
		return
	}

	response.SuccessMsg(c, "更新成功", gin.H{
		"uuid":     project.UUID,
		"title":    project.Title,
		"category": project.Category,
		"status":   project.Status,
	})
}

// Publish 发布草稿项目（草稿 status=1 → 已发布 status=2）
// POST /api/v1/projects/:id/publish
func (h *ProjectHandler) Publish(c *gin.Context) {
	uuid := c.Param("id")
	userUUID := c.GetString("user_uuid")

	project, err := h.projectService.PublishDraft(uuid, userUUID)
	if err != nil {
		code, parseErr := strconv.Atoi(err.Error())
		if parseErr == nil && code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			return
		}
		response.ErrorInternal(c, "发布项目失败")
		return
	}

	response.SuccessMsg(c, "项目已发布", gin.H{
		"id":           project.UUID,
		"uuid":         project.UUID,
		"status":       project.Status,
		"published_at": project.PublishedAt,
	})
}

// ConfirmAlignment 确认需求对齐 (status 3→4)
// POST /api/v1/projects/:id/confirm-alignment
func (h *ProjectHandler) ConfirmAlignment(c *gin.Context) {
	uuid := c.Param("id")
	userUUID := c.GetString("user_uuid")
	if err := h.projectService.ConfirmAlignment(uuid, userUUID); err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			return
		}
		response.ErrorInternal(c, "确认需求对齐失败")
		return
	}
	response.SuccessMsg(c, "需求已对齐", gin.H{"status": 4})
}

// Start 启动项目 (status 4→5)
// POST /api/v1/projects/:id/start
func (h *ProjectHandler) Start(c *gin.Context) {
	uuid := c.Param("id")
	userUUID := c.GetString("user_uuid")
	if err := h.projectService.StartProject(uuid, userUUID); err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			return
		}
		response.ErrorInternal(c, "启动项目失败")
		return
	}
	response.SuccessMsg(c, "项目已启动", gin.H{"status": 5})
}

// Close 关闭项目
func (h *ProjectHandler) Close(c *gin.Context) {
	uuid := c.Param("id")

	var req dto.CloseProjectReq
	c.ShouldBindJSON(&req)

	if err := h.projectService.Close(uuid, req.Reason); err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			return
		}
		response.ErrorInternal(c, "关闭项目失败")
		return
	}

	response.Success(c, nil)
}

// ListMarket 需求广场列表
// GET /api/v1/market/projects
func (h *ProjectHandler) ListMarket(c *gin.Context) {
	var query dto.MarketProjectQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		query.Page = 1
		query.PageSize = 10
	}
	if query.Page == 0 {
		query.Page = 1
	}
	if query.PageSize == 0 {
		query.PageSize = 10
	}

	filter := repository.ProjectFilter{
		Category:  query.Category,
		BudgetMin: query.BudgetMin,
		BudgetMax: query.BudgetMax,
		Sort:      query.Sort,
	}

	projects, total, err := h.projectService.ListMarket(query.Page, query.PageSize, filter)
	if err != nil {
		response.ErrorInternal(c, "获取需求广场失败")
		return
	}

	list := toMarketProjectList(projects)
	response.SuccessWithMeta(c, list, response.BuildMeta(query.Page, query.PageSize, total))
}

// ---- 辅助函数 ----

func toProjectRespList(projects []*model.Project) []service.ProjectListItem {
	list := make([]service.ProjectListItem, 0, len(projects))
	for _, p := range projects {
		list = append(list, service.NewProjectListItem(p))
	}
	return list
}

func toMarketProjectList(projects []*model.Project) []service.ProjectListItem {
	return toProjectRespList(projects)
}

type projectDetail struct {
	service.ProjectListItem
	PrdSummary  string      `json:"prd_summary"`
	Milestones  interface{} `json:"milestones"`
	MyBidStatus *string     `json:"my_bid_status,omitempty"`
	BidID       *string     `json:"bid_id,omitempty"`
}

func (h *ProjectHandler) buildProjectDetail(p *model.Project, userUUID string, isParticipant bool) projectDetail {
	prdSummary := ""
	var milestoneList []interface{}

	if isParticipant {
		prdSummary = extractPRDSummary(p)

		statusMap := map[int16]string{
			1: "pending",
			2: "in_progress",
			3: "completed",
			4: "revision_requested",
			5: "delivered",
		}
		if ms, err := h.milestoneService.ListByProject(p.UUID); err == nil && len(ms) > 0 {
			milestoneList = make([]interface{}, 0, len(ms))
			for _, m := range ms {
				st := statusMap[m.Status]
				if st == "" {
					st = "pending"
				}
				progress := 0
				switch m.Status {
				case 3:
					progress = 100
				case 5:
					progress = 90
				case 2:
					progress = 50
				}
				entry := map[string]interface{}{
					"id":               m.UUID,
					"title":            m.Title,
					"description":      m.Description,
					"status":           st,
					"progress":         progress,
					"due_date":         m.DueDate,
					"amount":           m.PaymentAmount,
					"payment_ratio":    m.PaymentRatio,
					"estimated_days":   m.EstimatedDays,
					"feature_item_ids": m.FeatureItemIDs,
					"phases":           m.Phases,
				}
				milestoneList = append(milestoneList, entry)
			}
		}
	}
	if milestoneList == nil {
		milestoneList = []interface{}{}
	}

	detail := projectDetail{
		ProjectListItem: service.NewProjectListItem(p),
		PrdSummary:      prdSummary,
		Milestones:      milestoneList,
	}

	if bs := h.projectService.UserBidStatus(p.ID, userUUID); bs != "" {
		detail.MyBidStatus = &bs
	}

	// 填充 bid_id（项目已关联的 bid UUID）
	if p.BidID != nil {
		if bid, err := h.projectService.FindBidByID(*p.BidID); err == nil {
			bidUUID := bid.UUID
			detail.BidID = &bidUUID
		}
	}

	return detail
}

func extractPRDSummary(p *model.Project) string {
	tryExtract := func(raw model.JSONMap) string {
		if len(raw) == 0 {
			return ""
		}
		var m map[string]interface{}
		if err := json.Unmarshal([]byte(raw), &m); err != nil {
			return ""
		}
		if s, ok := m["summary"]; ok {
			if str, ok := s.(string); ok && str != "" {
				return str
			}
		}
		return ""
	}
	if s := tryExtract(p.ConfirmedPRD); s != "" {
		return s
	}
	return tryExtract(p.AiPRD)
}

func respondProjectFileError(c *gin.Context, err error) {
	code, convErr := strconv.Atoi(err.Error())
	if convErr != nil || code <= 0 {
		response.ErrorInternal(c, "操作失败")
		return
	}
	msg := errcode.GetMessage(code)
	switch code {
	case errcode.ErrUserNotFound, errcode.ErrProjectNotFound, errcode.ErrProjectFileNotFound, errcode.ErrMilestoneNotFound:
		response.ErrorNotFound(c, code, msg)
	case errcode.ErrProjectParticipantOnly:
		response.ErrorForbidden(c, code, msg)
	case errcode.ErrObjectStorageDisabled, errcode.ErrUploadFileTooLarge, errcode.ErrUploadEmptyFile,
		errcode.ErrObjectUploadFailed, errcode.ErrProjectFileKindInvalid, errcode.ErrParamInvalid:
		response.ErrorBadRequest(c, code, msg)
	default:
		response.ErrorBadRequest(c, code, msg)
	}
}

// ListProjectFiles GET /api/v1/projects/:id/files
func (h *ProjectHandler) ListProjectFiles(c *gin.Context) {
	projectID := c.Param("id")
	userUUID := c.GetString("user_uuid")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	withURL := true
	if v := strings.TrimSpace(c.Query("with_url")); v == "0" || v == "false" {
		withURL = false
	}
	q := service.ProjectFileListQuery{
		FileKind:          c.Query("file_kind"),
		MilestoneUUID:     c.Query("milestone_id"),
		Page:              page,
		PageSize:          pageSize,
		IncludePresignURL: withURL,
	}
	list, total, err := h.projectFileService.List(c.Request.Context(), projectID, userUUID, q)
	if err != nil {
		respondProjectFileError(c, err)
		return
	}
	response.SuccessWithMeta(c, list, response.BuildMeta(q.Page, q.PageSize, total))
}

// UploadProjectFile POST /api/v1/projects/:id/files
func (h *ProjectHandler) UploadProjectFile(c *gin.Context) {
	projectID := c.Param("id")
	userUUID := c.GetString("user_uuid")
	fh, err := c.FormFile("file")
	if err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "请上传 file 字段")
		return
	}
	fileKind := c.PostForm("file_kind")
	var milestoneUUID *string
	if ms := strings.TrimSpace(c.PostForm("milestone_id")); ms != "" {
		milestoneUUID = &ms
	}
	src, err := fh.Open()
	if err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "无法读取上传文件")
		return
	}
	defer src.Close()

	rec, err := h.projectFileService.Upload(
		c.Request.Context(),
		projectID,
		userUUID,
		fileKind,
		milestoneUUID,
		fh.Filename,
		fh.Size,
		fh.Header.Get("Content-Type"),
		src,
	)
	if err != nil {
		respondProjectFileError(c, err)
		return
	}
	item, err := h.projectFileService.Get(c.Request.Context(), projectID, userUUID, rec.UUID)
	if err != nil {
		respondProjectFileError(c, err)
		return
	}
	response.SuccessMsg(c, "上传成功", item)
}

// GetProjectFile GET /api/v1/projects/:id/files/:fileUuid
func (h *ProjectHandler) GetProjectFile(c *gin.Context) {
	projectID := c.Param("id")
	fileUUID := c.Param("fileUuid")
	userUUID := c.GetString("user_uuid")
	item, err := h.projectFileService.Get(c.Request.Context(), projectID, userUUID, fileUUID)
	if err != nil {
		respondProjectFileError(c, err)
		return
	}
	response.Success(c, item)
}
