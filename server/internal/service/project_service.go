package service

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/repository"
	"go.uber.org/zap"
	"gorm.io/gorm"
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

// ListUserSkills 获取用户技能
func (s *UserService) ListUserSkills(userID int64) ([]*model.UserSkill, error) {
	return s.repos.User.ListUserSkills(userID)
}

// ListUserPortfolios 获取用户作品集
func (s *UserService) ListUserPortfolios(userID int64) ([]*model.Portfolio, error) {
	return s.repos.User.ListUserPortfolios(userID)
}

// UserStats 用户统计数据
type UserStats struct {
	CompletedProjects int     `json:"completed_projects"`
	ApprovalRate      float64 `json:"approval_rate"`
	AvgDeliveryDays   int     `json:"avg_delivery_days"`
	TotalEarnings     float64 `json:"total_earnings"`
	PublishedProjects int64   `json:"published_projects"`
	TotalSpent        float64 `json:"total_spent"`
	DaysOnPlatform    int     `json:"days_on_platform"`
}

// GetUserStats 获取用户完整统计数据
func (s *UserService) GetUserStats(user *model.User) *UserStats {
	stats := &UserStats{
		CompletedProjects: user.CompletedOrders,
		ApprovalRate:      user.CompletionRate,
		AvgDeliveryDays:   0,
		TotalEarnings:     user.TotalEarnings,
	}
	days := int(time.Since(user.CreatedAt).Hours() / 24)
	if days < 1 {
		days = 1
	}
	stats.DaysOnPlatform = days
	publishedCount, err := s.repos.Project.CountByOwnerID(user.ID)
	if err == nil {
		stats.PublishedProjects = publishedCount
	}
	totalSpent, err := s.repos.Order.SumPaidByPayerID(user.ID)
	if err == nil {
		stats.TotalSpent = totalSpent
	}
	return stats
}

// ListExperts 获取专家列表
func (s *UserService) ListExperts(page, pageSize int) ([]*model.User, int64, error) {
	offset := (page - 1) * pageSize
	return s.repos.User.ListExperts(offset, pageSize)
}

// SetOnboarding 管理端更新用户入驻状态
func (s *UserService) SetOnboarding(userUUID string, status int16, reason *string, reviewerUserID int64) error {
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return err
	}
	fields := map[string]interface{}{
		"onboarding_status": status,
	}
	now := time.Now()
	fields["onboarding_reviewed_at"] = &now
	fields["onboarding_reviewer_id"] = reviewerUserID
	if status == model.OnboardingRejected && reason != nil {
		fields["onboarding_reject_reason"] = *reason
	}
	if status == model.OnboardingApproved {
		fields["onboarding_reject_reason"] = nil
	}
	return s.repos.User.UpdateFields(user.ID, fields)
}

// SubmitOnboardingApplication 专家提交简历/作品集进入人工审核
func (s *UserService) SubmitOnboardingApplication(userUUID string, resumeURL *string, note *string, portfolioUUIDs []string) error {
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return err
	}
	if user.Role != 2 && user.Role != 3 {
		return fmt.Errorf("%d", errcode.ErrOnboardingNeedExpertRole)
	}
	if user.OnboardingStatus == model.OnboardingApproved {
		return fmt.Errorf("%d", errcode.ErrOnboardingAlreadyApproved)
	}
	resume := ""
	if resumeURL != nil {
		resume = strings.TrimSpace(*resumeURL)
	}
	noteText := ""
	if note != nil {
		noteText = strings.TrimSpace(*note)
	}
	var portfolioOK bool
	if len(portfolioUUIDs) > 0 {
		cnt, err := s.repos.User.CountPortfoliosByUserAndUUIDs(user.ID, portfolioUUIDs)
		if err != nil {
			return err
		}
		if cnt != int64(len(portfolioUUIDs)) {
			return fmt.Errorf("%d", errcode.ErrOnboardingApplicationInvalid)
		}
		portfolioOK = true
	}
	if resume == "" && !portfolioOK {
		return fmt.Errorf("%d", errcode.ErrOnboardingApplicationInvalid)
	}
	now := time.Now()
	fields := map[string]interface{}{
		"onboarding_status":       model.OnboardingPending,
		"onboarding_submitted_at": &now,
	}
	if resume != "" {
		fields["resume_url"] = resume
	} else {
		fields["resume_url"] = nil
	}
	if noteText != "" {
		fields["onboarding_application_note"] = noteText
	} else {
		fields["onboarding_application_note"] = nil
	}
	return s.repos.User.UpdateFields(user.ID, fields)
}

// RedeemTeamInviteForOnboarding 兑换团队邀请码：直接通过入驻、加入团队；码作废并轮换新码
func (s *UserService) RedeemTeamInviteForOnboarding(userUUID, plain string) error {
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return err
	}
	if user.Role != 2 && user.Role != 3 {
		return fmt.Errorf("%d", errcode.ErrOnboardingNeedExpertRole)
	}
	if user.OnboardingStatus == model.OnboardingApproved {
		return fmt.Errorf("%d", errcode.ErrOnboardingAlreadyApproved)
	}
	consumed, _, err := s.repos.InviteCode.ConsumeTeamInviteAndRotate(strings.TrimSpace(plain))
	if err != nil {
		return err
	}
	teamID := *consumed.TeamID
	if _, err := s.repos.Team.FindMember(teamID, user.ID); errors.Is(err, gorm.ErrRecordNotFound) {
		member := &model.TeamMember{
			TeamID:     teamID,
			UserID:     user.ID,
			RoleInTeam: "member",
			SplitRatio: 0,
			Status:     1,
		}
		if err := s.repos.Team.CreateMember(member); err != nil {
			return err
		}
	}
	fields := map[string]interface{}{
		"onboarding_status":        model.OnboardingApproved,
		"invite_code_id":           consumed.ID,
		"onboarding_submitted_at":  nil,
		"onboarding_reject_reason": nil,
	}
	return s.repos.User.UpdateFields(user.ID, fields)
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

// GetByID 获取项目详情（通过 ID）
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

// GetByUUID 获取项目详情（通过 UUID）
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

// ---- HomeService ----

// HomeService 首页数据服务
type HomeService struct {
	repos *repository.Repositories
	log   *zap.Logger
}

// NewHomeService 创建首页服务
func NewHomeService(repos *repository.Repositories, log *zap.Logger) *HomeService {
	return &HomeService{repos: repos, log: log}
}

// CategoryInfo 分类信息
type CategoryInfo struct {
	Key   string `json:"key"`
	Name  string `json:"name"`
	Icon  string `json:"icon"`
	Count int64  `json:"count"`
}

// ExpertBrief 专家简要信息
type ExpertBrief struct {
	ID              string   `json:"id"`
	Nickname        string   `json:"nickname"`
	AvatarURL       *string  `json:"avatar_url"`
	Rating          float64  `json:"rating"`
	Skill           string   `json:"skill"`
	HourlyRate      *float64 `json:"hourly_rate"`
	CompletedOrders int      `json:"completed_orders"`
}

// ProjectBrief 项目简要信息（用于首页/广场等聚合接口）
type ProjectBrief struct {
	ID               string    `json:"id"`
	UUID             string    `json:"uuid"`
	OwnerID          string    `json:"owner_id"`
	Title            string    `json:"title"`
	Description      string    `json:"description"`
	Category         string    `json:"category"`
	BudgetMin        *float64  `json:"budget_min"`
	BudgetMax        *float64  `json:"budget_max"`
	Progress         int16     `json:"progress"`
	Status           int16     `json:"status"`
	TechRequirements []string  `json:"tech_requirements"`
	ViewCount        int       `json:"view_count"`
	BidCount         int       `json:"bid_count"`
	CreatedAt        time.Time `json:"created_at"`
}

func toProjectBrief(p *model.Project) ProjectBrief {
	ownerID := ""
	if p.Owner != nil {
		ownerID = p.Owner.UUID
	}
	var techReqs []string
	if len(p.TechRequirements) > 0 {
		json.Unmarshal([]byte(p.TechRequirements), &techReqs)
	}
	if techReqs == nil {
		techReqs = []string{}
	}
	return ProjectBrief{
		ID:               p.UUID,
		UUID:             p.UUID,
		OwnerID:          ownerID,
		Title:            p.Title,
		Description:      p.Description,
		Category:         p.Category,
		BudgetMin:        p.BudgetMin,
		BudgetMax:        p.BudgetMax,
		Progress:         p.Progress,
		Status:           p.Status,
		TechRequirements: techReqs,
		ViewCount:        p.ViewCount,
		BidCount:         p.BidCount,
		CreatedAt:        p.CreatedAt,
	}
}

// DemanderHomeData 需求方首页数据
type DemanderHomeData struct {
	AIPrompt           string         `json:"ai_prompt"`
	Categories         []CategoryInfo `json:"categories"`
	MyProjects         []ProjectBrief `json:"my_projects"`
	RecommendedExperts []ExpertBrief  `json:"recommended_experts"`
}

// RevenueSummary 收入摘要
type RevenueSummary struct {
	TotalIncome   float64 `json:"total_income"`
	MonthIncome   float64 `json:"month_income"`
	PendingIncome float64 `json:"pending_income"`
	Trend         float64 `json:"trend"`
}

// SkillHeat 技能热度
type SkillHeat struct {
	Name string `json:"name"`
	Heat int    `json:"heat"`
}

// TeamOpportunity 团队机会
type TeamOpportunity struct {
	ID           string  `json:"id"`
	ProjectTitle string  `json:"project_title"`
	NeededRole   string  `json:"needed_role"`
	TeamSize     int     `json:"team_size"`
	Budget       float64 `json:"budget"`
}

// ExpertHomeData 专家首页数据
type ExpertHomeData struct {
	Revenue            RevenueSummary    `json:"revenue"`
	RecommendedDemands []ProjectBrief    `json:"recommended_demands"`
	SkillHeat          []SkillHeat       `json:"skill_heat"`
	TeamOpportunities  []TeamOpportunity `json:"team_opportunities"`
}

var categoryMeta = []struct {
	Key  string
	Name string
	Icon string
}{
	{"data", "数据", "bar_chart"},
	{"dev", "研发", "code"},
	{"visual", "视觉设计", "brush"},
	{"solution", "解决方案", "lightbulb"},
}

// expertSkillDisplayName 单条关联的展示名：优先预加载的 Skill.Name，否则用 namesBySkillID 兜底（避免仓储未 Preload 时静默为空）。
func expertSkillDisplayName(us *model.UserSkill, namesBySkillID map[int64]string) string {
	if us == nil {
		return ""
	}
	if n := strings.TrimSpace(us.Skill.Name); n != "" {
		return n
	}
	if us.SkillID > 0 && namesBySkillID != nil {
		if n := strings.TrimSpace(namesBySkillID[us.SkillID]); n != "" {
			return n
		}
	}
	return ""
}

// expertPrimarySkillName 取专家展示用主技能名：优先 is_primary，否则取首条有效技能名。
func expertPrimarySkillName(skills []*model.UserSkill, namesBySkillID map[int64]string) string {
	for _, us := range skills {
		if us != nil && us.IsPrimary {
			if n := expertSkillDisplayName(us, namesBySkillID); n != "" {
				return n
			}
		}
	}
	for _, us := range skills {
		if n := expertSkillDisplayName(us, namesBySkillID); n != "" {
			return n
		}
	}
	return ""
}

func groupUserSkillsByUserID(skills []*model.UserSkill) map[int64][]*model.UserSkill {
	by := make(map[int64][]*model.UserSkill)
	for _, us := range skills {
		if us == nil {
			continue
		}
		by[us.UserID] = append(by[us.UserID], us)
	}
	return by
}

// skillIDsMissingPreloadedName 收集「关联行存在但 Skill 未预加载出名称」的技能 ID，用于批量补全。
func skillIDsMissingPreloadedName(skills []*model.UserSkill) []int64 {
	seen := make(map[int64]struct{})
	var ids []int64
	for _, us := range skills {
		if us == nil || us.SkillID == 0 {
			continue
		}
		if strings.TrimSpace(us.Skill.Name) != "" {
			continue
		}
		if _, ok := seen[us.SkillID]; ok {
			continue
		}
		seen[us.SkillID] = struct{}{}
		ids = append(ids, us.SkillID)
	}
	return ids
}

// GetDemanderHome 获取需求方首页数据
func (s *HomeService) GetDemanderHome(userUUID string) (*DemanderHomeData, error) {
	counts, _ := s.repos.Project.CountByCategory()

	categories := make([]CategoryInfo, 0, len(categoryMeta))
	for _, m := range categoryMeta {
		categories = append(categories, CategoryInfo{
			Key:   m.Key,
			Name:  m.Name,
			Icon:  m.Icon,
			Count: counts[m.Key],
		})
	}

	myProjects := make([]ProjectBrief, 0)
	user, err := s.repos.User.FindByUUID(userUUID)
	if err == nil {
		projects, _, _ := s.repos.Project.ListByOwnerID(user.ID, 0, 5)
		for _, p := range projects {
			myProjects = append(myProjects, toProjectBrief(p))
		}
	}

	experts, _, _ := s.repos.User.ListExperts(0, 5)
	expertIDs := make([]int64, 0, len(experts))
	for _, e := range experts {
		expertIDs = append(expertIDs, e.ID)
	}
	var namesBySkillID map[int64]string
	skillsByUser := make(map[int64][]*model.UserSkill)
	if len(expertIDs) > 0 {
		if allSkills, err := s.repos.User.ListUserSkillsForUsers(expertIDs); err == nil {
			if missing := skillIDsMissingPreloadedName(allSkills); len(missing) > 0 {
				if m, err := s.repos.User.FindSkillNamesByIDs(missing); err == nil {
					namesBySkillID = m
				}
			}
			skillsByUser = groupUserSkillsByUserID(allSkills)
		}
	}

	expertBriefs := make([]ExpertBrief, 0, len(experts))
	for _, e := range experts {
		skillName := expertPrimarySkillName(skillsByUser[e.ID], namesBySkillID)
		eb := ExpertBrief{
			ID:              e.UUID,
			Nickname:        e.Nickname,
			AvatarURL:       e.AvatarURL,
			Rating:          e.AvgRating,
			Skill:           skillName,
			HourlyRate:      e.HourlyRate,
			CompletedOrders: e.CompletedOrders,
		}
		expertBriefs = append(expertBriefs, eb)
	}

	return &DemanderHomeData{
		AIPrompt:           "告诉我你想做什么，AI 帮你生成需求文档",
		Categories:         categories,
		MyProjects:         myProjects,
		RecommendedExperts: expertBriefs,
	}, nil
}

// GetExpertHome 获取专家首页数据
func (s *HomeService) GetExpertHome(userUUID string) (*ExpertHomeData, error) {
	revenue := RevenueSummary{}
	user, err := s.repos.User.FindByUUID(userUUID)
	if err == nil {
		revenue.TotalIncome = user.TotalEarnings
	}

	projects, _, _ := s.repos.Project.ListMarket(0, 5, repository.ProjectFilter{Sort: "latest"})
	demands := make([]ProjectBrief, 0, len(projects))
	for _, p := range projects {
		demands = append(demands, toProjectBrief(p))
	}

	skillHeat := []SkillHeat{
		{Name: "Flutter", Heat: 95},
		{Name: "Vue.js", Heat: 88},
		{Name: "Go", Heat: 82},
		{Name: "React", Heat: 79},
		{Name: "Python", Heat: 75},
	}

	return &ExpertHomeData{
		Revenue:            revenue,
		RecommendedDemands: demands,
		SkillHeat:          skillHeat,
		TeamOpportunities:  []TeamOpportunity{},
	}, nil
}
