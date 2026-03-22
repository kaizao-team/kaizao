package service

import (
	"time"

	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/repository"
	"go.uber.org/zap"
)

// UserService 用户服务
type UserService struct {
	repos *repository.Repositories
	log   *zap.Logger
}

// NewUserService 创建用户服务
func NewUserService(repos *repository.Repositories, log *zap.Logger) *UserService {
	return &UserService{repos: repos, log: log}
}

// GetByUUID 根据 UUID 获取用户
func (s *UserService) GetByUUID(uuid string) (*model.User, error) {
	return s.repos.User.FindByUUID(uuid)
}

// UpdateProfile 更新用户资料
func (s *UserService) UpdateProfile(uuid string, fields map[string]interface{}) (*model.User, error) {
	user, err := s.repos.User.FindByUUID(uuid)
	if err != nil {
		return nil, err
	}

	if err := s.repos.User.UpdateFields(user.ID, fields); err != nil {
		return nil, err
	}

	return s.repos.User.FindByUUID(uuid)
}

// ProjectService 项目服务
type ProjectService struct {
	repos *repository.Repositories
	log   *zap.Logger
}

// NewProjectService 创建项目服务
func NewProjectService(repos *repository.Repositories, log *zap.Logger) *ProjectService {
	return &ProjectService{repos: repos, log: log}
}

// Create 创建项目
func (s *ProjectService) Create(ownerUUID string, title, description, category string, budgetMin, budgetMax *float64, matchMode int, isDraft bool) (*model.Project, error) {
	owner, err := s.repos.User.FindByUUID(ownerUUID)
	if err != nil {
		return nil, err
	}

	status := int16(2) // 已发布
	var publishedAt *time.Time
	if isDraft {
		status = 1 // 草稿
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

	if err := s.repos.Project.Create(project); err != nil {
		return nil, err
	}

	// 重新加载（带 Owner 关联）
	return s.repos.Project.FindByUUID(project.UUID)
}

// GetByUUID 获取项目详情
func (s *ProjectService) GetByUUID(uuid string) (*model.Project, error) {
	project, err := s.repos.Project.FindByUUID(uuid)
	if err != nil {
		return nil, err
	}

	// 增加浏览量
	s.repos.Project.UpdateFields(project.ID, map[string]interface{}{
		"view_count": project.ViewCount + 1,
	})

	return project, nil
}

// List 项目列表
func (s *ProjectService) List(page, pageSize int, conditions map[string]interface{}, sortBy, sortOrder string) ([]*model.Project, int64, error) {
	offset := (page - 1) * pageSize
	return s.repos.Project.List(offset, pageSize, conditions, sortBy, sortOrder)
}

// Update 更新项目
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

// Close 关闭项目
func (s *ProjectService) Close(uuid, reason string) error {
	project, err := s.repos.Project.FindByUUID(uuid)
	if err != nil {
		return err
	}

	return s.repos.Project.UpdateFields(project.ID, map[string]interface{}{
		"status":       8,
		"close_reason": reason,
	})
}
