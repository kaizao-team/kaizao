package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/response"
	"github.com/vibebuild/server/internal/service"
	"go.uber.org/zap"
)

type PRDHandler struct {
	projectService *service.ProjectService
	log            *zap.Logger
}

func NewPRDHandler(projectService *service.ProjectService, log *zap.Logger) *PRDHandler {
	return &PRDHandler{projectService: projectService, log: log}
}

func (h *PRDHandler) AIChat(c *gin.Context) {
	var req struct {
		Message  string `json:"message" binding:"required"`
		Category string `json:"category"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	response.Success(c, gin.H{
		"reply":            "好的，我已经了解了您的需求。请问还有什么具体的功能要求吗？比如用户量级、技术偏好等。",
		"can_generate_prd": false,
		"turn":             1,
	})
}

func (h *PRDHandler) GeneratePRD(c *gin.Context) {
	var req struct {
		Category    string        `json:"category" binding:"required"`
		ChatHistory []interface{} `json:"chat_history" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	prdID := model.GenerateUUID()
	response.Success(c, gin.H{
		"prd_id": prdID,
		"title":  "项目 PRD",
		"modules": []gin.H{
			{
				"id":   "mod_core",
				"name": "核心功能模块",
				"cards": []gin.H{
					{
						"id":          "card_001",
						"module_id":   "mod_core",
						"title":       "核心功能",
						"type":        "event",
						"priority":    "P0",
						"description": "基于对话内容生成的核心功能描述",
						"acceptance_criteria": []gin.H{
							{"id": "ac_001", "content": "功能正常运行", "checked": false},
						},
						"roles":        []string{"frontend", "backend"},
						"effort_hours": 16,
						"dependencies": []string{},
						"tech_tags":    []string{},
						"status":       "pending",
					},
				},
			},
		},
		"budget_suggestion": gin.H{
			"min":    5000,
			"max":    15000,
			"reason": "基于项目复杂度和市场行情估算",
		},
	})
}

func (h *PRDHandler) SaveDraft(c *gin.Context) {
	var req struct {
		Category  string   `json:"category"`
		BudgetMin *float64 `json:"budget_min"`
		BudgetMax *float64 `json:"budget_max"`
		MatchMode string   `json:"match_mode"`
		Step      int      `json:"step"`
	}
	c.ShouldBindJSON(&req)

	userUUID := c.GetString("user_uuid")
	title := "草稿-" + req.Category
	if req.Category == "" {
		title = "未命名草稿"
	}
	desc := "需求草稿，待完善"
	cat := req.Category
	if cat == "" {
		cat = "app"
	}
	project, err := h.projectService.Create(userUUID, title, desc, cat, req.BudgetMin, req.BudgetMax, nil, 0, true)
	if err != nil {
		response.ErrorInternal(c, "保存草稿失败")
		return
	}
	response.SuccessMsg(c, "草稿已保存", gin.H{
		"draft_id": project.UUID,
		"saved_at": project.CreatedAt,
	})
}

func (h *PRDHandler) GetPRD(c *gin.Context) {
	id := c.Param("id")
	project, err := h.projectService.GetByUUID(id)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrProjectNotFound, "项目不存在")
		return
	}
	response.Success(c, gin.H{
		"prd_id":     model.GenerateUUID(),
		"project_id": project.UUID,
		"title":      project.Title + " PRD",
		"version":    "1.0",
		"created_at": project.CreatedAt,
		"modules":    []interface{}{},
	})
}

func (h *PRDHandler) UpdateCard(c *gin.Context) {
	var req struct {
		CriteriaID string `json:"criteria_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	response.SuccessMsg(c, "更新成功", gin.H{
		"criteria_id": req.CriteriaID,
	})
}
