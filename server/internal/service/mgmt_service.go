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

func isProjectParticipant(p *model.Project, userID int64) bool {
	if p.OwnerID == userID {
		return true
	}
	if p.ProviderID != nil && *p.ProviderID == userID {
		return true
	}
	return false
}

// Create 创建里程碑（仅需求方或已选服务方可操作）；若项目有 agreed_price 且传入 payment_ratio（0–100），则 payment_amount = agreed_price × payment_ratio / 100。
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

	sortOrder := 0
	if req.SortOrder != nil {
		sortOrder = *req.SortOrder
	} else {
		sortOrder, err = s.repos.Milestone.NextSortOrder(p.ID)
		if err != nil {
			return nil, err
		}
	}

	ms := &model.Milestone{
		ProjectID:    p.ID,
		Title:        req.Title,
		Description:  req.Description,
		SortOrder:    sortOrder,
		PaymentRatio: req.PaymentRatio,
		Status:       1,
	}

	if req.DueDate != nil && strings.TrimSpace(*req.DueDate) != "" {
		t, err := time.ParseInLocation("2006-01-02", strings.TrimSpace(*req.DueDate), time.Local)
		if err != nil {
			return nil, fmt.Errorf("%d", errcode.ErrParamInvalid)
		}
		ms.DueDate = &t
	}

	if req.PaymentRatio != nil && p.AgreedPrice != nil && *p.AgreedPrice > 0 {
		ratio := *req.PaymentRatio
		amt := *p.AgreedPrice * ratio / 100.0
		ms.PaymentAmount = &amt
	}

	if err := s.repos.Milestone.Create(ms); err != nil {
		return nil, err
	}
	return ms, nil
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

func (s *MilestoneService) Accept(msUUID string) (*model.Milestone, error) {
	ms, err := s.repos.Milestone.FindByUUID(msUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrMilestoneNotFound)
	}
	now := time.Now()
	ms.Status = 3
	ms.AcceptedAt = &now
	if err := s.repos.Milestone.Update(ms); err != nil {
		return nil, err
	}
	return ms, nil
}

func (s *MilestoneService) RequestRevision(msUUID, description string, relatedItems []string) (string, error) {
	ms, err := s.repos.Milestone.FindByUUID(msUUID)
	if err != nil {
		return "", fmt.Errorf("%d", errcode.ErrMilestoneNotFound)
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
