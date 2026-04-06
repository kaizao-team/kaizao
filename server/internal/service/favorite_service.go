package service

import (
	"errors"
	"fmt"

	"github.com/go-sql-driver/mysql"
	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/repository"
	"gorm.io/gorm"
)

// AddFavoriteOutcome 收藏结果（幂等时 AlreadyFavorited 为 true）
type AddFavoriteOutcome struct {
	UUID             string
	AlreadyFavorited bool
}

// FavoriteService 收藏与项目收藏计数
type FavoriteService struct {
	repos *repository.Repositories
}

// NewFavoriteService 创建收藏服务
func NewFavoriteService(repos *repository.Repositories) *FavoriteService {
	return &FavoriteService{repos: repos}
}

func teamEligibleForFavorite(team *model.Team) bool {
	if team == nil {
		return false
	}
	if team.Status != 1 || team.AvailableStatus != 1 {
		return false
	}
	leader := team.Leader
	if leader == nil {
		return false
	}
	return (leader.Role == 2 || leader.Role == 3) && leader.Status == 1 && leader.OnboardingStatus == model.OnboardingApproved
}

// isMySQLDuplicateKey 唯一约束冲突（并发插入同一条收藏等）
func isMySQLDuplicateKey(err error) bool {
	var me *mysql.MySQLError
	return errors.As(err, &me) && me.Number == 1062
}

func mapFindProjectErr(err error) error {
	if err == nil {
		return nil
	}
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return fmt.Errorf("%d", errcode.ErrProjectNotFound)
	}
	return err
}

func mapFindUserErr(err error) error {
	if err == nil {
		return nil
	}
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return fmt.Errorf("%d", errcode.ErrUserNotFound)
	}
	return err
}

// AddFavorite 新增收藏；target_type=project 时 target_id 为项目 UUID，target_type=expert 时为团队 UUID（传入用户 UUID 会自动解析为其主团队 UUID）
func (s *FavoriteService) AddFavorite(userID int64, targetType, targetID string) (*AddFavoriteOutcome, error) {
	if targetType != "project" && targetType != "expert" {
		return nil, fmt.Errorf("%d", errcode.ErrParamInvalid)
	}

	// expert 类型：统一解析为团队 UUID 存储
	resolvedTargetID := targetID
	if targetType == "expert" {
		resolved, err := s.resolveExpertToTeamUUID(targetID)
		if err != nil {
			return nil, err
		}
		resolvedTargetID = resolved
	}

	existing, err := s.repos.Favorite.FindByUserAndTarget(userID, targetType, resolvedTargetID)
	if err == nil {
		return &AddFavoriteOutcome{UUID: existing.UUID, AlreadyFavorited: true}, nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}

	fav := &model.Favorite{
		UserID:     userID,
		TargetType: targetType,
		TargetID:   resolvedTargetID,
	}

	if targetType == "project" {
		project, err := s.repos.Project.FindByUUID(targetID)
		if err != nil {
			return nil, mapFindProjectErr(err)
		}

		var outcome *AddFavoriteOutcome
		err = s.repos.DB().Transaction(func(tx *gorm.DB) error {
			txRepos := repository.NewRepositories(tx)
			if err := txRepos.Favorite.Create(fav); err != nil {
				if isMySQLDuplicateKey(err) {
					ex, err2 := txRepos.Favorite.FindByUserAndTarget(userID, targetType, resolvedTargetID)
					if err2 != nil {
						return err2
					}
					outcome = &AddFavoriteOutcome{UUID: ex.UUID, AlreadyFavorited: true}
					return nil
				}
				return err
			}
			if err := txRepos.Project.AddFavoriteCountDelta(project.ID, 1); err != nil {
				return err
			}
			outcome = &AddFavoriteOutcome{UUID: fav.UUID}
			return nil
		})
		if err != nil {
			return nil, err
		}
		return outcome, nil
	}

	// expert: resolvedTargetID 已经是团队 UUID
	team, err := s.repos.Team.FindByUUID(resolvedTargetID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrFavoriteExpertInvalid)
	}
	if !teamEligibleForFavorite(team) {
		return nil, fmt.Errorf("%d", errcode.ErrFavoriteExpertInvalid)
	}
	if err := s.repos.Favorite.Create(fav); err != nil {
		if isMySQLDuplicateKey(err) {
			ex, err2 := s.repos.Favorite.FindByUserAndTarget(userID, targetType, resolvedTargetID)
			if err2 != nil {
				return nil, err2
			}
			return &AddFavoriteOutcome{UUID: ex.UUID, AlreadyFavorited: true}, nil
		}
		return nil, err
	}
	return &AddFavoriteOutcome{UUID: fav.UUID}, nil
}

// resolveExpertToTeamUUID 将 targetID 统一解析为团队 UUID；若传入用户 UUID 则取其主团队
func (s *FavoriteService) resolveExpertToTeamUUID(targetID string) (string, error) {
	// 优先按团队 UUID 查找
	if _, err := s.repos.Team.FindByUUID(targetID); err == nil {
		return targetID, nil
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		return "", err
	}
	// 按用户 UUID 查找，取其主团队
	user, err := s.repos.User.FindByUUID(targetID)
	if err != nil {
		return "", fmt.Errorf("%d", errcode.ErrFavoriteExpertInvalid)
	}
	team, err := s.repos.Team.FindPrimaryTeamForUser(user.ID)
	if err != nil {
		return "", fmt.Errorf("%d", errcode.ErrFavoriteExpertInvalid)
	}
	return team.UUID, nil
}

// RemoveFavorite 取消收藏（未收藏时幂等成功）
func (s *FavoriteService) RemoveFavorite(userID int64, targetType, targetID string) error {
	if targetType != "project" && targetType != "expert" {
		return fmt.Errorf("%d", errcode.ErrParamInvalid)
	}

	resolvedTargetID := targetID
	if targetType == "expert" {
		resolved, err := s.resolveExpertToTeamUUID(targetID)
		if err != nil {
			return nil
		}
		resolvedTargetID = resolved
	}

	_, err := s.repos.Favorite.FindByUserAndTarget(userID, targetType, resolvedTargetID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil
		}
		return err
	}

	if targetType == "project" {
		project, err := s.repos.Project.FindByUUID(targetID)
		if err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return s.repos.Favorite.Delete(userID, targetType, resolvedTargetID)
			}
			return err
		}
		return s.repos.DB().Transaction(func(tx *gorm.DB) error {
			txRepos := repository.NewRepositories(tx)
			if err := txRepos.Favorite.Delete(userID, targetType, resolvedTargetID); err != nil {
				return err
			}
			return txRepos.Project.AddFavoriteCountDelta(project.ID, -1)
		})
	}

	return s.repos.Favorite.Delete(userID, targetType, resolvedTargetID)
}
