package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/dto"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/response"
	"github.com/vibebuild/server/internal/service"
	"go.uber.org/zap"
)

type TaskHandler struct {
	taskService      *service.TaskService
	milestoneService *service.MilestoneService
	log              *zap.Logger
}

func NewTaskHandler(taskService *service.TaskService, milestoneService *service.MilestoneService, log *zap.Logger) *TaskHandler {
	return &TaskHandler{taskService: taskService, milestoneService: milestoneService, log: log}
}

func (h *TaskHandler) ListTasks(c *gin.Context) {
	projectID := c.Param("id")
	tasks, err := h.taskService.ListByProject(projectID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrProjectNotFound, "项目不存在")
		return
	}
	statusMap := map[int16]string{1: "todo", 2: "in_progress", 3: "completed"}
	priorityMap := map[int16]string{0: "P2", 1: "P0", 2: "P1", 3: "P2"}
	list := make([]gin.H, 0, len(tasks))
	for _, t := range tasks {
		status := statusMap[t.Status]
		if status == "" {
			status = "todo"
		}
		priority := priorityMap[t.Priority]
		if priority == "" {
			priority = "P2"
		}
		assignee := ""
		if t.Assignee != nil {
			assignee = t.Assignee.Nickname
		}
		msID := ""
		if t.MilestoneID != nil {
			msID = strconv.FormatInt(*t.MilestoneID, 10)
		}
		list = append(list, gin.H{
			"id":             t.UUID,
			"title":          t.Title,
			"description":    t.EarsBehavior,
			"status":         status,
			"priority":       priority,
			"assignee":       assignee,
			"milestone_id":   msID,
			"effort_hours":   t.EstimatedHours,
			"is_at_risk":     false,
			"created_at":     t.CreatedAt,
			"completed_at":   t.CompletedAt,
		})
	}
	response.Success(c, list)
}

func (h *TaskHandler) UpdateTaskStatus(c *gin.Context) {
	taskID := c.Param("taskId")
	var req struct {
		Status string `json:"status" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	_, err := h.taskService.UpdateStatus(taskID, req.Status)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrTaskNotFound, "任务不存在")
		return
	}
	response.SuccessMsg(c, "状态已更新", gin.H{
		"status": req.Status,
	})
}

func (h *TaskHandler) ListMilestones(c *gin.Context) {
	projectID := c.Param("id")
	milestones, err := h.milestoneService.ListByProject(projectID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrProjectNotFound, "项目不存在")
		return
	}
	statusMap := map[int16]string{1: "pending", 2: "in_progress", 3: "completed"}
	list := make([]gin.H, 0, len(milestones))
	for _, m := range milestones {
		status := statusMap[m.Status]
		if status == "" {
			status = "pending"
		}
		progress := 0
		if m.Status == 3 {
			progress = 100
		} else if m.Status == 2 {
			progress = 50
		}
		list = append(list, gin.H{
			"id":                   m.UUID,
			"title":                m.Title,
			"status":               status,
			"progress":             progress,
			"due_date":             m.DueDate,
			"amount":               m.PaymentAmount,
			"task_count":           0,
			"completed_task_count": 0,
		})
	}
	response.Success(c, list)
}

func (h *TaskHandler) CreateMilestone(c *gin.Context) {
	projectUUID := c.Param("id")
	userUUID := c.GetString("user_uuid")
	var req dto.CreateMilestoneReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败: "+err.Error())
		return
	}
	ms, err := h.milestoneService.Create(projectUUID, userUUID, &req)
	if err != nil {
		code, convErr := strconv.Atoi(err.Error())
		if convErr == nil && code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			return
		}
		response.ErrorInternal(c, "创建里程碑失败")
		return
	}
	var amount interface{}
	if ms.PaymentAmount != nil {
		amount = *ms.PaymentAmount
	}
	response.SuccessMsg(c, "里程碑创建成功", gin.H{
		"id":             ms.UUID,
		"uuid":           ms.UUID,
		"project_id":     projectUUID,
		"title":          ms.Title,
		"description":    ms.Description,
		"sort_order":     ms.SortOrder,
		"due_date":       ms.DueDate,
		"payment_ratio":  ms.PaymentRatio,
		"payment_amount": amount,
		"status":         ms.Status,
		"created_at":     ms.CreatedAt,
	})
}

func (h *TaskHandler) GetDailyReports(c *gin.Context) {
	projectID := c.Param("id")
	reports, err := h.milestoneService.GetDailyReports(projectID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrProjectNotFound, "项目不存在")
		return
	}
	response.Success(c, reports)
}

func (h *TaskHandler) GetAcceptance(c *gin.Context) {
	msID := c.Param("id")
	ms, tasks, err := h.milestoneService.GetAcceptance(msID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrMilestoneNotFound, "里程碑不存在")
		return
	}
	items := make([]gin.H, 0)
	for _, t := range tasks {
		items = append(items, gin.H{
			"id":          t.UUID,
			"description": t.Title,
			"is_checked":  t.Status == 3,
			"source_card": t.TaskCode,
		})
	}
	result := gin.H{
		"milestone_id":    ms.UUID,
		"milestone_title": ms.Title,
		"amount":          ms.PaymentAmount,
		"payee_name":      "",
		"preview_url":     ms.PreviewURL,
		"items":           items,
	}
	response.Success(c, result)
}

func (h *TaskHandler) AcceptMilestone(c *gin.Context) {
	msID := c.Param("id")
	ms, err := h.milestoneService.Accept(msID)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrMilestoneNotFound, "里程碑不存在")
		return
	}
	var amount float64
	if ms.PaymentAmount != nil {
		amount = *ms.PaymentAmount
	}
	response.SuccessMsg(c, "验收通过，款项已释放", gin.H{
		"status":          "accepted",
		"released_amount": amount,
	})
}

func (h *TaskHandler) RequestRevision(c *gin.Context) {
	msID := c.Param("id")
	var req struct {
		Description  string   `json:"description" binding:"required"`
		RelatedItems []string `json:"related_items"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	revID, err := h.milestoneService.RequestRevision(msID, req.Description, req.RelatedItems)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrMilestoneNotFound, "里程碑不存在")
		return
	}
	response.SuccessMsg(c, "修改请求已提交", gin.H{
		"revision_id": revID,
		"status":      "revision_requested",
	})
}
