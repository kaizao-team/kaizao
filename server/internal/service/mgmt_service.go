package service

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/vibebuild/server/internal/dto"
	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/repository"
	"go.uber.org/zap"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type TaskService struct {
	repos *repository.Repositories
	log   *zap.Logger
}

func NewTaskService(repos *repository.Repositories, log *zap.Logger) *TaskService {
	return &TaskService{repos: repos, log: log}
}

func (s *TaskService) ListByProject(projectUUID string) ([]*model.Task, error) {
	project, err := s.repos.Project.FindByUUID(projectUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrProjectNotFound)
	}
	tasks, _, err := s.repos.Task.ListByProjectID(project.ID, 0, 500, nil)
	return tasks, err
}

func (s *TaskService) UpdateStatus(taskUUID string, status string) (*model.Task, error) {
	task, err := s.repos.Task.FindByUUID(taskUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrTaskNotFound)
	}
	statusMap := map[string]int16{"todo": 1, "in_progress": 2, "completed": 3}
	newStatus, ok := statusMap[status]
	if !ok {
		newStatus = 1
	}
	fields := map[string]interface{}{"status": newStatus}
	if status == "in_progress" && task.StartedAt == nil {
		now := time.Now()
		fields["started_at"] = &now
	}
	if status == "completed" {
		now := time.Now()
		fields["completed_at"] = &now
	}
	if err := s.repos.Task.UpdateFields(task.ID, fields); err != nil {
		return nil, err
	}
	return s.repos.Task.FindByUUID(taskUUID)
}

// Create 手动创建任务卡片（仅需求方或已选服务方）；事务内锁项目行并生成 project 内唯一 task_code（T{序号}）。
func (s *TaskService) Create(projectUUID, actorUserUUID string, req *dto.CreateTaskReq) (*model.Task, error) {
	u, err := s.repos.User.FindByUUID(actorUserUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrUserNotFound)
	}
	p, err := s.repos.Project.FindByUUID(projectUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrProjectNotFound)
	}
	if !isProjectParticipant(p, u.ID) {
		return nil, fmt.Errorf("%d", errcode.ErrProjectParticipantOnly)
	}

	var milestoneID *int64
	if req.MilestoneID != nil && strings.TrimSpace(*req.MilestoneID) != "" {
		ms, err := s.repos.Milestone.FindByUUID(strings.TrimSpace(*req.MilestoneID))
		if err != nil || ms.ProjectID != p.ID {
			return nil, fmt.Errorf("%d", errcode.ErrMilestoneNotFound)
		}
		milestoneID = &ms.ID
	}

	var assigneeID *int64
	if req.AssigneeID != nil && strings.TrimSpace(*req.AssigneeID) != "" {
		au, err := s.repos.User.FindByUUID(strings.TrimSpace(*req.AssigneeID))
		if err != nil {
			return nil, fmt.Errorf("%d", errcode.ErrUserNotFound)
		}
		if !isAllowedTaskAssignee(p, au.ID, s.repos) {
			return nil, fmt.Errorf("%d", errcode.ErrTaskAssigneeInvalid)
		}
		assigneeID = &au.ID
	}

	priority := int16(2)
	if req.Priority != nil {
		priority = *req.Priority
	}

	sortOrder := 0
	if req.SortOrder != nil {
		sortOrder = *req.SortOrder
	}

	fullText := req.EarsBehavior
	if req.EarsFullText != nil && strings.TrimSpace(*req.EarsFullText) != "" {
		fullText = strings.TrimSpace(*req.EarsFullText)
	}

	emptyArr := model.JSON([]byte("[]"))
	var out *model.Task
	err = s.repos.DB().Transaction(func(tx *gorm.DB) error {
		var proj model.Project
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).Where("id = ?", p.ID).First(&proj).Error; err != nil {
			return err
		}

		var cnt int64
		if err := tx.Model(&model.Task{}).Where("project_id = ?", p.ID).Count(&cnt).Error; err != nil {
			return err
		}
		seq := cnt + 1
		taskCode := fmt.Sprintf("T%d", seq)
		if len(taskCode) > 20 {
			taskCode = taskCode[:20]
		}

		t := &model.Task{
			ProjectID:          p.ID,
			MilestoneID:        milestoneID,
			TaskCode:           taskCode,
			Title:              req.Title,
			EarsType:           req.EarsType,
			EarsTrigger:        req.EarsTrigger,
			EarsBehavior:       req.EarsBehavior,
			EarsFullText:       fullText,
			Module:             req.Module,
			RoleTag:            req.RoleTag,
			AssigneeID:         assigneeID,
			Priority:           priority,
			EstimatedHours:     req.EstimatedHours,
			AcceptanceCriteria: emptyArr,
			Dependencies:       emptyArr,
			Blockers:           emptyArr,
			Status:             1,
			SortOrder:          sortOrder,
			IsAIGenerated:      false,
		}
		if err := tx.Create(t).Error; err != nil {
			return err
		}
		out = t
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

type MilestoneService struct {
	repos *repository.Repositories
	log   *zap.Logger
}

func NewMilestoneService(repos *repository.Repositories, log *zap.Logger) *MilestoneService {
	return &MilestoneService{repos: repos, log: log}
}

func (s *MilestoneService) ListByProject(projectUUID string) ([]*model.Milestone, error) {
	project, err := s.repos.Project.FindByUUID(projectUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrProjectNotFound)
	}
	return s.repos.Milestone.ListByProjectID(project.ID)
}

// MilestoneUUIDByID 将里程碑主键解析为 UUID（用于 API 响应）。
func (s *MilestoneService) MilestoneUUIDByID(id int64) (string, error) {
	m, err := s.repos.Milestone.FindByID(id)
	if err != nil {
		return "", err
	}
	return m.UUID, nil
}

// isAllowedTaskAssignee 任务指派人须为需求方、已选服务方，或（项目绑定团队时）该团队成员。
func isAllowedTaskAssignee(p *model.Project, assigneeUserID int64, repos *repository.Repositories) bool {
	return CanAccessProjectWorkspace(p, assigneeUserID, repos)
}

// Create 创建里程碑（仅需求方或已选服务方可操作）；若项目有 agreed_price 且传入 payment_ratio（0–100），则 payment_amount = agreed_price × payment_ratio / 100。
// 默认 sort_order 在事务内对项目行加锁后计算，避免并发下重复序号；项目内 payment_ratio（非空）累计不可超过 100%。
func (s *MilestoneService) Create(projectUUID, actorUserUUID string, req *dto.CreateMilestoneReq) (*model.Milestone, error) {
	u, err := s.repos.User.FindByUUID(actorUserUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrUserNotFound)
	}
	p, err := s.repos.Project.FindByUUID(projectUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrProjectNotFound)
	}
	if !isProjectParticipant(p, u.ID) {
		return nil, fmt.Errorf("%d", errcode.ErrProjectParticipantOnly)
	}

	var due *time.Time
	if req.DueDate != nil && strings.TrimSpace(*req.DueDate) != "" {
		t, err := time.ParseInLocation("2006-01-02", strings.TrimSpace(*req.DueDate), time.Local)
		if err != nil {
			return nil, fmt.Errorf("%d", errcode.ErrParamInvalid)
		}
		due = &t
	}

	var out *model.Milestone
	err = s.repos.DB().Transaction(func(tx *gorm.DB) error {
		var proj model.Project
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).Where("id = ?", p.ID).First(&proj).Error; err != nil {
			return err
		}

		var existing []*model.Milestone
		if err := tx.Where("project_id = ?", p.ID).Find(&existing).Error; err != nil {
			return err
		}
		var sumRatio float64
		for _, m := range existing {
			if m.PaymentRatio != nil {
				sumRatio += *m.PaymentRatio
			}
		}
		if req.PaymentRatio != nil {
			sumRatio += *req.PaymentRatio
		}
		if sumRatio > 100.0+1e-4 {
			return fmt.Errorf("%d", errcode.ErrMilestonePaymentRatioSum)
		}

		sortOrder := 0
		if req.SortOrder != nil {
			sortOrder = *req.SortOrder
		} else {
			var next int
			if err := tx.Raw(`SELECT COALESCE(MAX(sort_order), -1) + 1 FROM milestones WHERE project_id = ?`, p.ID).Scan(&next).Error; err != nil {
				return err
			}
			sortOrder = next
		}

		ms := &model.Milestone{
			ProjectID:    p.ID,
			Title:        req.Title,
			Description:  req.Description,
			SortOrder:    sortOrder,
			PaymentRatio: req.PaymentRatio,
			Status:       1,
			DueDate:      due,
		}
		if req.PaymentRatio != nil && proj.AgreedPrice != nil && *proj.AgreedPrice > 0 {
			ratio := *req.PaymentRatio
			amt := *proj.AgreedPrice * ratio / 100.0
			ms.PaymentAmount = &amt
		}
		if err := tx.Create(ms).Error; err != nil {
			return err
		}
		out = ms
		return nil
	})
	return out, err
}

func (s *MilestoneService) GetAcceptance(msUUID string) (*model.Milestone, []*model.Task, error) {
	ms, err := s.repos.Milestone.FindByUUID(msUUID)
	if err != nil {
		return nil, nil, fmt.Errorf("%d", errcode.ErrMilestoneNotFound)
	}
	tasks, _, err := s.repos.Task.ListByProjectID(ms.ProjectID, 0, 500, map[string]interface{}{"milestone_id": ms.ID})
	if err != nil {
		return ms, nil, nil
	}
	return ms, tasks, nil
}

// Deliver 服务方提交里程碑交付物；成功后状态为待验收（5），并通知需求方。
func (s *MilestoneService) Deliver(msUUID, actorUserUUID string, req *dto.DeliverMilestoneReq) (*model.Milestone, error) {
	u, err := s.repos.User.FindByUUID(actorUserUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrUserNotFound)
	}
	ms, err := s.repos.Milestone.FindByUUID(msUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrMilestoneNotFound)
	}
	p, err := s.repos.Project.FindByID(ms.ProjectID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrProjectNotFound)
	}
	if p.ProviderID == nil || *p.ProviderID != u.ID {
		return nil, fmt.Errorf("%d", errcode.ErrMilestoneDeliverProviderOnly)
	}
	switch ms.Status {
	case 3:
		return nil, fmt.Errorf("%d", errcode.ErrMilestoneStatusInvalid)
	case 5:
		return nil, fmt.Errorf("%d", errcode.ErrDeliveryAlreadySubmitted)
	case 1:
		return nil, fmt.Errorf("%d", errcode.ErrMilestoneDeliverNotReady)
	case 2, 4:
	default:
		return nil, fmt.Errorf("%d", errcode.ErrMilestoneStatusInvalid)
	}
	note := ""
	if req != nil && req.DeliveryNote != nil {
		note = strings.TrimSpace(*req.DeliveryNote)
	}
	url := ""
	if req != nil && req.PreviewURL != nil {
		url = strings.TrimSpace(*req.PreviewURL)
	}
	if note == "" && url == "" {
		return nil, fmt.Errorf("%d", errcode.ErrParamInvalid)
	}
	now := time.Now()
	ms.Status = 5
	ms.DeliveredAt = &now
	ms.RejectionReason = nil
	if note != "" {
		ms.DeliveryNote = &note
	} else {
		ms.DeliveryNote = nil
	}
	if url != "" {
		ms.PreviewURL = &url
	} else {
		ms.PreviewURL = nil
	}

	var out *model.Milestone
	err = s.repos.DB().Transaction(func(tx *gorm.DB) error {
		txRepos := repository.NewRepositories(tx)
		if err := txRepos.Milestone.Update(ms); err != nil {
			return err
		}
		targetType := "milestone"
		mid := ms.ID
		deliverSourceRole := "provider"
		deliverTargetUUID := p.UUID
		n := &model.Notification{
			UserID:           p.OwnerID,
			SourceRole:       &deliverSourceRole,
			Title:            "里程碑待验收",
			Content:          fmt.Sprintf("项目「%s」的里程碑「%s」已提交交付，请及时验收。", p.Title, ms.Title),
			NotificationType: model.NotificationTypeMilestoneDelivered,
			TargetType:       &targetType,
			TargetID:         &mid,
			TargetUUID:       &deliverTargetUUID,
		}
		if err := txRepos.Notification.Create(n); err != nil {
			s.log.Error("Deliver: notify owner", zap.Error(err))
			return err
		}
		out = ms
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (s *MilestoneService) Accept(msUUID, actorUserUUID string) (*model.Milestone, error) {
	u, err := s.repos.User.FindByUUID(actorUserUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrUserNotFound)
	}
	ms, err := s.repos.Milestone.FindByUUID(msUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrMilestoneNotFound)
	}
	p, err := s.repos.Project.FindByID(ms.ProjectID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrProjectNotFound)
	}
	if p.OwnerID != u.ID {
		return nil, fmt.Errorf("%d", errcode.ErrProjectOwnerOnly)
	}
	if ms.Status != 5 {
		return nil, fmt.Errorf("%d", errcode.ErrMilestoneStatusInvalid)
	}
	now := time.Now()
	ms.Status = 3
	ms.AcceptedAt = &now
	if err := s.repos.Milestone.Update(ms); err != nil {
		return nil, err
	}
	return ms, nil
}

func (s *MilestoneService) RequestRevision(msUUID, actorUserUUID, description string, relatedItems []string) (string, error) {
	u, err := s.repos.User.FindByUUID(actorUserUUID)
	if err != nil {
		return "", fmt.Errorf("%d", errcode.ErrUserNotFound)
	}
	ms, err := s.repos.Milestone.FindByUUID(msUUID)
	if err != nil {
		return "", fmt.Errorf("%d", errcode.ErrMilestoneNotFound)
	}
	p, err := s.repos.Project.FindByID(ms.ProjectID)
	if err != nil {
		return "", fmt.Errorf("%d", errcode.ErrProjectNotFound)
	}
	if p.OwnerID != u.ID {
		return "", fmt.Errorf("%d", errcode.ErrProjectOwnerOnly)
	}
	if ms.Status != 5 {
		return "", fmt.Errorf("%d", errcode.ErrMilestoneStatusInvalid)
	}
	ms.Status = 4
	note := description
	if len(relatedItems) > 0 {
		b, _ := json.Marshal(relatedItems)
		note += " [related: " + string(b) + "]"
	}
	ms.RejectionReason = &note
	if err := s.repos.Milestone.Update(ms); err != nil {
		return "", err
	}
	return model.GenerateUUID(), nil
}

func (s *MilestoneService) GetDailyReports(projectUUID string) ([]map[string]interface{}, error) {
	_, err := s.repos.Project.FindByUUID(projectUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrProjectNotFound)
	}
	today := time.Now().Format("2006-01-02")
	return []map[string]interface{}{
		{
			"id":                model.GenerateUUID(),
			"date":              today,
			"summary":           "项目进展正常，各模块按计划推进中",
			"completed_tasks":   []string{},
			"in_progress_tasks": []string{},
			"risk_items":        []string{},
			"tomorrow_plan":     "继续推进当前迭代任务",
		},
	}, nil
}
