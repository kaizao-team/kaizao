package service

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"
	"unicode/utf8"

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

// ListMine 当前用户创建或作为服务方承接的项目（owner_id 或 provider_id）
func (s *ProjectService) ListMine(userUUID string, page, pageSize int, conditions map[string]interface{}, sortBy, sortOrder string) ([]*model.Project, int64, error) {
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return nil, 0, err
	}
	offset := (page - 1) * pageSize
	return s.repos.Project.ListMine(user.ID, offset, pageSize, conditions, sortBy, sortOrder)
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

func truncateRunes(s string, max int) string {
	if utf8.RuneCountInString(s) <= max {
		return s
	}
	r := []rune(s)
	return string(r[:max])
}

// normalizePublishCategory 对齐 dto.CreateProjectReq.category：data / dev / visual / solution
func normalizePublishCategory(cat string) string {
	c := strings.ToLower(strings.TrimSpace(cat))
	switch c {
	case "design", "visual":
		return "visual"
	case "data", "dev", "solution":
		return c
	case "":
		return "dev"
	case "app", "web", "miniprogram", "backend":
		return "dev"
	default:
		return "dev"
	}
}

func ensurePublishTitle(title, category string) string {
	t := strings.TrimSpace(title)
	if utf8.RuneCountInString(t) >= 5 {
		return truncateRunes(t, 200)
	}
	cat := normalizePublishCategory(category)
	short := "草稿-" + cat
	if utf8.RuneCountInString(short) < 5 {
		short = short + "需求"
	}
	return truncateRunes(short, 200)
}

func ensurePublishDescription(desc string) string {
	d := strings.TrimSpace(desc)
	if utf8.RuneCountInString(d) >= 20 {
		return d
	}
	if d == "" {
		return "需求说明：本项目由发布流程在草稿阶段生成，发布后将补充更完整需求描述与交付范围。"
	}
	out := d + "（需求细节已在对话与确认流程中完善。）"
	for utf8.RuneCountInString(out) < 20 {
		out = out + "。"
	}
	return out
}

// errPublishDraftForStatus 在已排除「已发布 idempotent」后，校验是否允许从草稿发布。
func errPublishDraftForStatus(status int16) error {
	switch status {
	case 1:
		return nil
	case 4:
		return fmt.Errorf("%d", errcode.ErrProjectAlreadyClosed)
	default:
		return fmt.Errorf("%d", errcode.ErrProjectStatusInvalid)
	}
}

// PublishDraft 将草稿发布为已发布状态（仅 owner、且 status=1）。
// 发布前补全 title/description 并归一化 category，与 CreateProjectReq 校验一致（前端未 PUT 时仍可通过发布接口落库）。
func (s *ProjectService) PublishDraft(projectUUID, ownerUserUUID string) (*model.Project, error) {
	p, err := s.GetPeekIfOwner(projectUUID, ownerUserUUID)
	if err != nil {
		return nil, err
	}
	if p.Status == 2 {
		return p, nil
	}
	if err := errPublishDraftForStatus(p.Status); err != nil {
		return nil, err
	}
	now := time.Now()
	title := ensurePublishTitle(p.Title, p.Category)
	desc := ensurePublishDescription(p.Description)
	cat := normalizePublishCategory(p.Category)
	fields := map[string]interface{}{
		"title":        title,
		"description":  desc,
		"category":     cat,
		"status":       int16(2),
		"published_at": now,
	}
	if err := s.repos.Project.UpdateFields(p.ID, fields); err != nil {
		return nil, err
	}
	return s.repos.Project.FindByUUID(projectUUID)
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
