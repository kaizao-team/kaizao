package service

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/repository"
	"go.uber.org/zap"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

// MaxPortfoliosPerUser 单用户活跃作品集数量上限（status=1）
const MaxPortfoliosPerUser = 50

// UserService 用户资料、技能、入驻与统计
type UserService struct {
	repos *repository.Repositories
	log   *zap.Logger
}

// NewUserService 创建用户服务
func NewUserService(repos *repository.Repositories, log *zap.Logger) *UserService {
	return &UserService{repos: repos, log: log}
}

// UserStats 用户统计数据（GET /users/me 内嵌 stats）
type UserStats struct {
	CompletedProjects int     `json:"completed_projects"`
	ApprovalRate      float64 `json:"approval_rate"`
	AvgDeliveryDays   int     `json:"avg_delivery_days"`
	TotalEarnings     float64 `json:"total_earnings"`
	PublishedProjects int64   `json:"published_projects"`
	TotalSpent        float64 `json:"total_spent"`
	DaysOnPlatform    int     `json:"days_on_platform"`
}

func (s *UserService) GetByUUID(uuid string) (*model.User, error) {
	return s.repos.User.FindByUUID(uuid)
}

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
	if c, err := s.repos.Project.CountByOwnerID(user.ID); err == nil {
		stats.PublishedProjects = c
	}
	if spent, err := s.repos.Order.SumPaidByPayerID(user.ID); err == nil {
		stats.TotalSpent = spent
	}
	return stats
}

func (s *UserService) ListUserSkills(userID int64) ([]*model.UserSkill, error) {
	return s.repos.User.ListUserSkills(userID)
}

func (s *UserService) UpdateProfile(uuid string, fields map[string]interface{}) (*model.User, error) {
	u, err := s.repos.User.FindByUUID(uuid)
	if err != nil {
		return nil, err
	}

	teamFields := make(map[string]interface{})
	if v, ok := fields["hourly_rate"]; ok {
		teamFields["hourly_rate"] = v
	}
	if v, ok := fields["available_status"]; ok {
		teamFields["available_status"] = v
	}

	if err := s.repos.DB().Transaction(func(tx *gorm.DB) error {
		txRepos := repository.NewRepositories(tx)
		if err := txRepos.User.UpdateFields(u.ID, fields); err != nil {
			return err
		}
		if len(teamFields) > 0 && (u.Role == 2 || u.Role == 3) {
			team, err := txRepos.Team.FindPrimaryTeamForUser(u.ID)
			if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
				return err
			}
			if err == nil && team != nil {
				if err := txRepos.Team.UpdateFields(team.ID, teamFields); err != nil {
					return err
				}
			}
		}
		return nil
	}); err != nil {
		return nil, err
	}

	return s.repos.User.FindByUUID(uuid)
}

func (s *UserService) ListUserPortfolios(userID int64) ([]*model.Portfolio, error) {
	return s.repos.User.ListUserPortfolios(userID)
}

func (s *UserService) CreatePortfolio(p *model.Portfolio) error {
	// 事务内锁定用户行再计数 + 插入，避免并发下同时通过「未满」检查导致超上限
	return s.repos.DB().Transaction(func(tx *gorm.DB) error {
		var lock model.User
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).Where("id = ?", p.UserID).First(&lock).Error; err != nil {
			return err
		}
		var n int64
		if err := tx.Model(&model.Portfolio{}).Where("user_id = ? AND status = 1", p.UserID).Count(&n).Error; err != nil {
			return err
		}
		if n >= MaxPortfoliosPerUser {
			return fmt.Errorf("%d", errcode.ErrPortfolioExceedLimit)
		}
		return tx.Create(p).Error
	})
}

func (s *UserService) FindPortfolioByUUID(uuid string) (*model.Portfolio, error) {
	return s.repos.User.FindPortfolioByUUID(uuid)
}

func (s *UserService) UpdatePortfolioFields(id int64, fields map[string]interface{}) error {
	return s.repos.User.UpdatePortfolioFields(id, fields)
}

func (s *UserService) ListExperts(page, pageSize int) ([]*model.User, int64, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 50 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize
	return s.repos.User.ListExperts(offset, pageSize)
}

// ListExpertTeams 以团队为主实体的专家列表（市场广场 / 首页推荐）
func (s *UserService) ListExpertTeams(page, pageSize int) ([]*model.Team, int64, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 50 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize
	return s.repos.Team.ListActiveTeams(offset, pageSize)
}

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
	if resume == "" && len(portfolioUUIDs) == 0 {
		return fmt.Errorf("%d", errcode.ErrOnboardingApplicationInvalid)
	}
	if len(portfolioUUIDs) > 0 {
		n, err := s.repos.User.CountPortfoliosByUserAndUUIDs(user.ID, portfolioUUIDs)
		if err != nil || n != int64(len(portfolioUUIDs)) {
			return fmt.Errorf("%d", errcode.ErrOnboardingApplicationInvalid)
		}
	}
	now := time.Now()
	fields := map[string]interface{}{
		"onboarding_status":          model.OnboardingPending,
		"onboarding_submitted_at":    &now,
		"onboarding_reject_reason":   nil,
	}
	if resume != "" {
		fields["resume_url"] = resume
	} else {
		fields["resume_url"] = nil
	}
	if note != nil && strings.TrimSpace(*note) != "" {
		t := strings.TrimSpace(*note)
		fields["onboarding_application_note"] = t
	} else {
		fields["onboarding_application_note"] = nil
	}
	return s.repos.User.UpdateFields(user.ID, fields)
}

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
	icID := consumed.ID
	return s.repos.User.UpdateFields(user.ID, map[string]interface{}{
		"onboarding_status":        model.OnboardingApproved,
		"invite_code_id":           &icID,
		"onboarding_reject_reason": nil,
		"onboarding_reviewed_at":   nil,
		"onboarding_reviewer_id":   nil,
	})
}
