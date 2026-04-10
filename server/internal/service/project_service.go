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
	"gorm.io/gorm"
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
	case 8:
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
	publishTitle := ensurePublishTitle(p.Title, p.Category)
	desc := ensurePublishDescription(p.Description)
	cat := normalizePublishCategory(p.Category)
	fields := map[string]interface{}{
		"title":        publishTitle,
		"description":  desc,
		"category":     cat,
		"status":       int16(2),
		"published_at": now,
	}

	targetType := "project"
	sourceRole := "demander"
	targetUUID := p.UUID
	n := &model.Notification{
		UserID:           p.OwnerID,
		SourceRole:       &sourceRole,
		Title:            "项目已发布",
		Content:          fmt.Sprintf("您的项目「%s」已成功发布，等待团队方投标。", publishTitle),
		NotificationType: model.NotificationTypeProjectPublished,
		TargetType:       &targetType,
		TargetID:         &p.ID,
		TargetUUID:       &targetUUID,
	}

	if err := s.repos.DB().Transaction(func(tx *gorm.DB) error {
		txRepos := repository.NewRepositories(tx)
		if err := txRepos.Project.UpdateFields(p.ID, fields); err != nil {
			return err
		}
		return txRepos.Notification.Create(n)
	}); err != nil {
		return nil, err
	}
	return s.repos.Project.FindByUUID(projectUUID)
}

// ConfirmAlignment 项目方确认需求已对齐：status 3→4
func (s *ProjectService) ConfirmAlignment(projectUUID, ownerUUID string) error {
	p, err := s.GetPeekIfOwner(projectUUID, ownerUUID)
	if err != nil {
		return err
	}
	if p.Status != 3 {
		return fmt.Errorf("%d", errcode.ErrProjectStatusInvalid)
	}

	if err := s.repos.Project.UpdateFields(p.ID, map[string]interface{}{
		"status": int16(4),
	}); err != nil {
		return err
	}

	// 通知团队方
	if p.ProviderID != nil {
		targetType := "project"
		sourceRole := "demander"
		targetUUID := p.UUID
		n := &model.Notification{
			UserID:           *p.ProviderID,
			SourceRole:       &sourceRole,
			Title:            "需求已对齐",
			Content:          fmt.Sprintf("项目「%s」需求已对齐，等待启动", p.Title),
			NotificationType: model.NotificationTypeMatchSuccess,
			TargetType:       &targetType,
			TargetID:         &p.ID,
			TargetUUID:       &targetUUID,
		}
		_ = s.repos.Notification.Create(n)
	}
	return nil
}

// StartProject 项目方启动项目：status 4→5
func (s *ProjectService) StartProject(projectUUID, ownerUUID string) error {
	p, err := s.GetPeekIfOwner(projectUUID, ownerUUID)
	if err != nil {
		return err
	}
	if p.Status != 4 {
		return fmt.Errorf("%d", errcode.ErrProjectStatusInvalid)
	}

	now := time.Now()
	if err := s.repos.Project.UpdateFields(p.ID, map[string]interface{}{
		"status":     int16(5),
		"start_date": &now,
	}); err != nil {
		return err
	}

	// 通知团队方
	if p.ProviderID != nil {
		targetType := "project"
		sourceRole := "demander"
		targetUUID := p.UUID
		n := &model.Notification{
			UserID:           *p.ProviderID,
			SourceRole:       &sourceRole,
			Title:            "项目已启动",
			Content:          fmt.Sprintf("项目「%s」已启动，请开始履约", p.Title),
			NotificationType: model.NotificationTypeMatchSuccess,
			TargetType:       &targetType,
			TargetID:         &p.ID,
			TargetUUID:       &targetUUID,
		}
		_ = s.repos.Notification.Create(n)
	}
	return nil
}

// Close 关闭需求（已发布/草稿均可关闭；已撮合进行中不可关闭）
func (s *ProjectService) Close(uuid string, reason string) error {
	p, err := s.repos.Project.FindByUUID(uuid)
	if err != nil {
		return err
	}
	if p.Status == 8 {
		return fmt.Errorf("%d", errcode.ErrProjectAlreadyClosed)
	}
	// 已撮合(3)、需求对齐中(4)、进行中(5)、验收中(6) 不可关闭
	if p.Status >= 3 && p.Status <= 6 {
		return fmt.Errorf("%d", errcode.ErrProjectStatusInvalid)
	}
	fields := map[string]interface{}{"status": int16(8)}
	if t := strings.TrimSpace(reason); t != "" {
		fields["close_reason"] = t
	}
	return s.repos.Project.UpdateFields(p.ID, fields)
}

// IsParticipant 判断用户是否为项目参与者（需求方、服务方或团队成员）。
// userUUID 为空时直接返回 false。
func (s *ProjectService) IsParticipant(projectUUID, userUUID string) bool {
	if userUUID == "" {
		return false
	}
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return false
	}
	project, err := s.repos.Project.FindByUUID(projectUUID)
	if err != nil {
		return false
	}
	return CanAccessProjectWorkspace(project, user.ID, s.repos)
}

// FindBidByID 根据 bid ID 查找 bid（供 handler 填充 bid_id UUID）
func (s *ProjectService) FindBidByID(bidID int64) (*model.Bid, error) {
	return s.repos.Bid.FindByID(bidID)
}

// UserBidStatus returns the bid status string for the given user on a project.
// Returns "" if the user has not bid, or one of "pending", "accepted", "rejected", "withdrawn".
func (s *ProjectService) UserBidStatus(projectID int64, userUUID string) string {
	if userUUID == "" {
		return ""
	}
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return ""
	}
	bid, err := s.repos.Bid.FindLatestByProjectAndBidderID(projectID, user.ID)
	if err != nil || bid == nil {
		return ""
	}
	switch bid.Status {
	case 1:
		return "pending"
	case 2:
		return "accepted"
	case 3:
		return "rejected"
	case 4:
		return "withdrawn"
	default:
		return ""
	}
}
