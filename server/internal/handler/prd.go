package handler

import (
	"encoding/json"
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
)

// normalizeDraftCategory 将前端/历史分类值归一为 data|dev|visual|solution
func normalizeDraftCategory(cat string) (string, bool) {
	c := strings.ToLower(strings.TrimSpace(cat))
	switch c {
	case "":
		return "dev", true
	case "data", "dev", "visual", "solution":
		return c, true
	case "design":
		return "visual", true
	case "app", "web", "miniprogram", "backend":
		return "dev", true
	default:
		return "", false
	}
}

type PRDHandler struct {
	projectService *service.ProjectService
	aiAgentBaseURL string
	aiAgentHTTP    *http.Client
	log            *zap.Logger
}

func NewPRDHandler(projectService *service.ProjectService, aiCfg config.AIAgentConfig, log *zap.Logger) *PRDHandler {
	timeoutSec := aiCfg.TimeoutSec
	if timeoutSec <= 0 {
		timeoutSec = 30
	}
	return &PRDHandler{
		projectService: projectService,
		aiAgentBaseURL: strings.TrimRight(strings.TrimSpace(aiCfg.BaseURL), "/"),
		aiAgentHTTP: &http.Client{
			Timeout: time.Duration(timeoutSec) * time.Second,
		},
		log: log,
	}
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
	var req dto.SaveDraftReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败: "+err.Error())
		return
	}

	cat, ok := normalizeDraftCategory(req.Category)
	if !ok {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "category 不合法")
		return
	}

	if req.BudgetMin != nil && req.BudgetMax != nil && *req.BudgetMax < *req.BudgetMin {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "budget_max 不能小于 budget_min")
		return
	}

	userUUID := c.GetString("user_uuid")

	title := strings.TrimSpace(req.Title)
	if title == "" {
		title = "草稿-" + cat
	}
	desc := strings.TrimSpace(req.Description)
	if desc == "" {
		desc = "需求草稿，待完善"
	}

	matchMode := req.MatchMode
	if matchMode == 0 {
		matchMode = 1
	}

	project, err := h.projectService.Create(userUUID, title, desc, cat, req.BudgetMin, req.BudgetMax, nil, matchMode, true)
	if err != nil {
		response.ErrorInternal(c, "保存草稿失败")
		return
	}
	response.SuccessMsg(c, "草稿已保存", gin.H{
		"draft_id": project.UUID,
		"uuid":     project.UUID,
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

	if content, version, err := h.fetchLatestPRDContent(c, project.UUID); err == nil && strings.TrimSpace(content) != "" {
		response.Success(c, gin.H{
			"project_id": project.UUID,
			"title":      project.Title + " PRD",
			"version":    fmt.Sprintf("%d", version),
			"created_at": project.CreatedAt,
			"content":    content,
		})
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

type aiAgentEnvelope struct {
	Code    int             `json:"code"`
	Message string          `json:"message"`
	Data    json.RawMessage `json:"data"`
}

type aiDocumentRow struct {
	ID       int    `json:"id"`
	Stage    string `json:"stage"`
	Filename string `json:"filename"`
	Version  int    `json:"version"`
}

func (h *PRDHandler) fetchLatestPRDContent(c *gin.Context, projectUUID string) (string, int, error) {
	if h.aiAgentBaseURL == "" || h.aiAgentHTTP == nil {
		return "", 0, fmt.Errorf("ai-agent unavailable")
	}

	listURL := h.aiAgentBaseURL + "/api/v2/documents/" + projectUUID
	listReq, err := http.NewRequestWithContext(c.Request.Context(), http.MethodGet, listURL, nil)
	if err != nil {
		return "", 0, err
	}
	if rid := c.GetString("request_id"); rid != "" {
		listReq.Header.Set("X-Request-ID", rid)
	}
	listResp, err := h.aiAgentHTTP.Do(listReq)
	if err != nil {
		return "", 0, err
	}
	defer listResp.Body.Close()
	if listResp.StatusCode != http.StatusOK {
		return "", 0, fmt.Errorf("list documents status %d", listResp.StatusCode)
	}
	raw, err := io.ReadAll(listResp.Body)
	if err != nil {
		return "", 0, err
	}
	var env aiAgentEnvelope
	if err := json.Unmarshal(raw, &env); err != nil {
		return "", 0, err
	}
	if env.Code != 0 {
		return "", 0, fmt.Errorf("ai-agent code %d", env.Code)
	}

	var docs []aiDocumentRow
	if len(env.Data) > 0 && string(env.Data) != "null" {
		if err := json.Unmarshal(env.Data, &docs); err != nil {
			return "", 0, err
		}
	}
	if len(docs) == 0 {
		return "", 0, nil
	}

	var latest *aiDocumentRow
	for i := range docs {
		d := docs[i]
		if d.Filename != "requirement.md" && d.Stage != "requirement" {
			continue
		}
		if latest == nil || d.Version > latest.Version {
			latest = &d
		}
	}
	if latest == nil {
		return "", 0, nil
	}

	downloadURL := h.aiAgentBaseURL + "/api/v2/documents/" + projectUUID + "/download/" + strconv.Itoa(latest.ID)
	downloadReq, err := http.NewRequestWithContext(c.Request.Context(), http.MethodGet, downloadURL, nil)
	if err != nil {
		return "", 0, err
	}
	if rid := c.GetString("request_id"); rid != "" {
		downloadReq.Header.Set("X-Request-ID", rid)
	}
	downloadResp, err := h.aiAgentHTTP.Do(downloadReq)
	if err != nil {
		return "", 0, err
	}
	defer downloadResp.Body.Close()
	if downloadResp.StatusCode != http.StatusOK {
		return "", 0, fmt.Errorf("download prd status %d", downloadResp.StatusCode)
	}
	contentBytes, err := io.ReadAll(downloadResp.Body)
	if err != nil {
		return "", 0, err
	}
	return string(contentBytes), latest.Version, nil
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
