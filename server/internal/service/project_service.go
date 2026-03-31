package service

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/repository"
	"go.uber.org/zap"
)

// ProjectService 项目/需求
type ProjectService struct {
	repos *repository.Repositories
	log   *zap.Logger
}

// NewProjectService 创建项目服务
func NewProjectService(repos *repository.Repositories, log *zap.Logger) *ProjectService {
	return &ProjectService{repos: repos, log: log}
}

// Create 创建项目
func (s *ProjectService) Create(ownerUUID, title, description, category string, budgetMin, budgetMax *float64, techReqs []string, matchMode int, isDraft bool) (*model.Project, error) {
	owner, err := s.repos.User.FindByUUID(ownerUUID)
	if err != nil {
		return nil, err
	}

	status := int16(2)
	var publishedAt *time.Time
	if isDraft {
		status = 1
	} else {
		now := time.Now()
		publishedAt = &now
	}

	if matchMode == 0 {
		matchMode = 1
	}

	project := &model.Project{
		OwnerID:     owner.ID,
		Title:       title,
		Description: description,
		Category:    category,
		BudgetMin:   budgetMin,
		BudgetMax:   budgetMax,
		MatchMode:   int16(matchMode),
		Status:      status,
		PublishedAt: publishedAt,
	}

	if len(techReqs) > 0 {
		b, _ := json.Marshal(techReqs)
		project.TechRequirements = model.JSON(b)
	}

	if err := s.repos.Project.Create(project); err != nil {
		return nil, err
	}

	return s.repos.Project.FindByUUID(project.UUID)
}

// GetByID 获取项目详情（通过 ID），并增加浏览量
func (s *ProjectService) GetByID(id int64) (*model.Project, error) {
	project, err := s.repos.Project.FindByID(id)
	if err != nil {
		return nil, err
	}
	s.repos.Project.UpdateFields(project.ID, map[string]interface{}{
		"view_count": project.ViewCount + 1,
	})
	return project, nil
}

// GetByUUID 获取项目详情（通过 UUID），并增加浏览量
func (s *ProjectService) GetByUUID(uuid string) (*model.Project, error) {
	project, err := s.repos.Project.FindByUUID(uuid)
	if err != nil {
		return nil, err
	}
	s.repos.Project.UpdateFields(project.ID, map[string]interface{}{
		"view_count": project.ViewCount + 1,
	})
	return project, nil
}

// PeekByUUID 获取项目（不增加浏览量）
func (s *ProjectService) PeekByUUID(uuid string) (*model.Project, error) {
	return s.repos.Project.FindByUUID(uuid)
}

// GetPeekIfOwner 校验当前用户为需求发布方后返回项目（不增加浏览量）
func (s *ProjectService) GetPeekIfOwner(projectUUID, ownerUserUUID string) (*model.Project, error) {
	p, err := s.repos.Project.FindByUUID(projectUUID)
	if err != nil {
		return nil, err
	}
	u, err := s.repos.User.FindByUUID(ownerUserUUID)
	if err != nil {
		return nil, err
	}
	if p.OwnerID != u.ID {
		return nil, fmt.Errorf("%d", errcode.ErrProjectOwnerOnly)
	}
	return p, nil
}

// List 项目列表
func (s *ProjectService) List(page, pageSize int, conditions map[string]interface{}, sortBy, sortOrder string) ([]*model.Project, int64, error) {
	offset := (page - 1) * pageSize
	return s.repos.Project.List(offset, pageSize, conditions, sortBy, sortOrder)
}

// ListByRole 按角色获取项目列表: role=1 需求方(我发布的), role=2 专家(我参与的)
func (s *ProjectService) ListByRole(userUUID string, role, page, pageSize int) ([]*model.Project, int64, error) {
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return nil, 0, err
	}
	offset := (page - 1) * pageSize
	if role == 2 {
		return s.repos.Project.ListByProviderID(user.ID, offset, pageSize)
	}
	return s.repos.Project.ListByOwnerID(user.ID, offset, pageSize)
}

// ListMarket 需求广场列表
func (s *ProjectService) ListMarket(page, pageSize int, filter repository.ProjectFilter) ([]*model.Project, int64, error) {
	offset := (page - 1) * pageSize
	return s.repos.Project.ListMarket(offset, pageSize, filter)
}

// Update 更新项目字段
func (s *ProjectService) Update(uuid string, fields map[string]interface{}) (*model.Project, error) {
	project, err := s.repos.Project.FindByUUID(uuid)
	if err != nil {
		return nil, err
	}
	if err := s.repos.Project.UpdateFields(project.ID, fields); err != nil {
		return nil, err
	}
	return s.repos.Project.FindByUUID(uuid)
}

// Close 关闭需求（已发布/草稿均可关闭；已撮合进行中不可关闭）
func (s *ProjectService) Close(uuid string, reason string) error {
	p, err := s.repos.Project.FindByUUID(uuid)
	if err != nil {
		return err
	}
	if p.Status == 4 {
		return fmt.Errorf("%d", errcode.ErrProjectAlreadyClosed)
	}
	if p.Status == 3 {
		return fmt.Errorf("%d", errcode.ErrProjectStatusInvalid)
	}
	fields := map[string]interface{}{"status": int16(4)}
	if t := strings.TrimSpace(reason); t != "" {
		fields["close_reason"] = t
	}
	return s.repos.Project.UpdateFields(p.ID, fields)
}
