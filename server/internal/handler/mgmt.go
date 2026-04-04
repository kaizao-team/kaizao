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

// respondMilestoneCreateError 按业务码区分 HTTP 状态，避免鉴权/资源不存在与参数错误混为 400。
func respondMilestoneCreateError(c *gin.Context, err error) {
	code, convErr := strconv.Atoi(err.Error())
	if convErr != nil || code <= 0 {
		response.ErrorInternal(c, "创建里程碑失败")
		return
	}
	msg := errcode.GetMessage(code)
	switch code {
	case errcode.ErrUserNotFound, errcode.ErrProjectNotFound:
		response.ErrorNotFound(c, code, msg)
	case errcode.ErrProjectParticipantOnly:
		response.ErrorForbidden(c, code, msg)
	case errcode.ErrParamInvalid, errcode.ErrMilestonePaymentRatioSum:
		response.ErrorBadRequest(c, code, msg)
	default:
		response.ErrorBadRequest(c, code, msg)
	}
}

func respondDeliverError(c *gin.Context, err error) {
	code, convErr := strconv.Atoi(err.Error())
	if convErr != nil || code <= 0 {
		response.ErrorInternal(c, "提交交付失败")
		return
	}
	msg := errcode.GetMessage(code)
	switch code {
	case errcode.ErrUserNotFound, errcode.ErrProjectNotFound, errcode.ErrMilestoneNotFound:
		response.ErrorNotFound(c, code, msg)
	case errcode.ErrMilestoneDeliverProviderOnly:
		response.ErrorForbidden(c, code, msg)
	case errcode.ErrParamInvalid, errcode.ErrDeliveryAlreadySubmitted, errcode.ErrMilestoneStatusInvalid:
		response.ErrorBadRequest(c, code, msg)
	default:
		response.ErrorBadRequest(c, code, msg)
	}
}

func respondMilestoneAcceptanceError(c *gin.Context, err error) {
	code, convErr := strconv.Atoi(err.Error())
	if convErr != nil || code <= 0 {
		response.ErrorInternal(c, "操作失败")
		return
	}
	msg := errcode.GetMessage(code)
	switch code {
	case errcode.ErrMilestoneNotFound:
		response.ErrorNotFound(c, code, msg)
	case errcode.ErrMilestoneStatusInvalid:
		response.ErrorBadRequest(c, code, msg)
	default:
		response.ErrorBadRequest(c, code, msg)
	}
}

// respondTaskCreateError 创建任务卡片错误响应（HTTP 与业务码对齐）。
func respondTaskCreateError(c *gin.Context, err error) {
	code, convErr := strconv.Atoi(err.Error())
	if convErr != nil || code <= 0 {
		response.ErrorInternal(c, "创建任务失败")
		return
	}
	msg := errcode.GetMessage(code)
	switch code {
	case errcode.ErrUserNotFound, errcode.ErrProjectNotFound, errcode.ErrMilestoneNotFound:
		response.ErrorNotFound(c, code, msg)
	case errcode.ErrProjectParticipantOnly:
		response.ErrorForbidden(c, code, msg)
	case errcode.ErrParamInvalid, errcode.ErrEarsTypeInvalid, errcode.ErrTaskAssigneeInvalid:
		response.ErrorBadRequest(c, code, msg)
	default:
		response.ErrorBadRequest(c, code, msg)
	}
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
	msUUIDCache := make(map[int64]string)
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
			mid := *t.MilestoneID
			if u, ok := msUUIDCache[mid]; ok {
				msID = u
			} else {
				uuid, err := h.milestoneService.MilestoneUUIDByID(mid)
				if err == nil {
					msUUIDCache[mid] = uuid
					msID = uuid
				}
			}
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

func (h *TaskHandler) CreateTask(c *gin.Context) {
	projectUUID := c.Param("id")
	userUUID := c.GetString("user_uuid")
	var req dto.CreateTaskReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败: "+err.Error())
		return
	}
	t, err := h.taskService.Create(projectUUID, userUUID, &req)
	if err != nil {
		respondTaskCreateError(c, err)
		return
	}
	msUUIDStr := ""
	if t.MilestoneID != nil {
		if u, err := h.milestoneService.MilestoneUUIDByID(*t.MilestoneID); err == nil {
			msUUIDStr = u
		}
	}
	response.SuccessMsg(c, "任务创建成功", gin.H{
		"id":              t.UUID,
		"uuid":            t.UUID,
		"project_id":      projectUUID,
		"task_code":       t.TaskCode,
		"title":           t.Title,
		"ears_type":       t.EarsType,
		"milestone_id":    msUUIDStr,
		"priority":        t.Priority,
		"status":          t.Status,
		"sort_order":      t.SortOrder,
		"is_ai_generated": t.IsAIGenerated,
		"created_at":      t.CreatedAt,
	})
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
	statusMap := map[int16]string{
		1: "pending",
		2: "in_progress",
		3: "completed",
		4: "revision_requested",
		5: "delivered",
	}
	list := make([]gin.H, 0, len(milestones))
	for _, m := range milestones {
		status := statusMap[m.Status]
		if status == "" {
			status = "pending"
		}
		progress := 0
		if m.Status == 3 {
			progress = 100
		} else if m.Status == 5 {
			progress = 90
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
		respondMilestoneCreateError(c, err)
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

func (h *TaskHandler) DeliverMilestone(c *gin.Context) {
	msID := c.Param("id")
	userUUID := c.GetString("user_uuid")
	var req dto.DeliverMilestoneReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败: "+err.Error())
		return
	}
	ms, err := h.milestoneService.Deliver(msID, userUUID, &req)
	if err != nil {
		respondDeliverError(c, err)
		return
	}
	response.SuccessMsg(c, "交付已提交", gin.H{
		"milestone_id":    ms.UUID,
		"status":        "delivered",
		"delivery_note": ms.DeliveryNote,
		"preview_url":   ms.PreviewURL,
		"delivered_at":  ms.DeliveredAt,
	})
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
		respondMilestoneAcceptanceError(c, err)
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
		respondMilestoneAcceptanceError(c, err)
		return
	}
	response.SuccessMsg(c, "修改请求已提交", gin.H{
		"revision_id": revID,
		"status":      "revision_requested",
	})
}
