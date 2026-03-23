package service

import (
	"encoding/json"
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
	{"app", "App 开发", "phone_android"},
	{"web", "Web 开发", "web"},
	{"miniprogram", "小程序", "qr_code"},
	{"design", "UI/UX 设计", "brush"},
	{"data", "数据分析", "bar_chart"},
	{"consult", "技术咨询", "support_agent"},
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
	expertBriefs := make([]ExpertBrief, 0, len(experts))
	for _, e := range experts {
		eb := ExpertBrief{
			ID:              e.UUID,
			Nickname:        e.Nickname,
			AvatarURL:       e.AvatarURL,
			Rating:          e.AvgRating,
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
