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

func expertEligibleForFavorite(u *model.User, team *model.Team) bool {
	if u == nil {
		return false
	}
	if !((u.Role == 2 || u.Role == 3) && u.Status == 1 && u.OnboardingStatus == model.OnboardingApproved) {
		return false
	}
	if team == nil {
		return false
	}
	return team.Status == 1 && team.AvailableStatus == 1
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

// AddFavorite 新增收藏；target_id 为项目或专家用户 UUID
func (s *FavoriteService) AddFavorite(userID int64, targetType, targetID string) (*AddFavoriteOutcome, error) {
	if targetType != "project" && targetType != "expert" {
		return nil, fmt.Errorf("%d", errcode.ErrParamInvalid)
	}

	existing, err := s.repos.Favorite.FindByUserAndTarget(userID, targetType, targetID)
	if err == nil {
		return &AddFavoriteOutcome{UUID: existing.UUID, AlreadyFavorited: true}, nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}

	fav := &model.Favorite{
		UserID:     userID,
		TargetType: targetType,
		TargetID:   targetID,
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
					ex, err2 := txRepos.Favorite.FindByUserAndTarget(userID, targetType, targetID)
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

	expert, err := s.repos.User.FindByUUID(targetID)
	if err != nil {
		return nil, mapFindUserErr(err)
	}
	team, _ := s.repos.Team.FindPrimaryTeamForUser(expert.ID)
	if !expertEligibleForFavorite(expert, team) {
		return nil, fmt.Errorf("%d", errcode.ErrFavoriteExpertInvalid)
	}
	if err := s.repos.Favorite.Create(fav); err != nil {
		if isMySQLDuplicateKey(err) {
			ex, err2 := s.repos.Favorite.FindByUserAndTarget(userID, targetType, targetID)
			if err2 != nil {
				return nil, err2
			}
			return &AddFavoriteOutcome{UUID: ex.UUID, AlreadyFavorited: true}, nil
		}
		return nil, err
	}
	return &AddFavoriteOutcome{UUID: fav.UUID}, nil
}

// RemoveFavorite 取消收藏（未收藏时幂等成功）
func (s *FavoriteService) RemoveFavorite(userID int64, targetType, targetID string) error {
	if targetType != "project" && targetType != "expert" {
		return fmt.Errorf("%d", errcode.ErrParamInvalid)
	}

	_, err := s.repos.Favorite.FindByUserAndTarget(userID, targetType, targetID)
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
				return s.repos.Favorite.Delete(userID, targetType, targetID)
			}
			return err
		}
		return s.repos.DB().Transaction(func(tx *gorm.DB) error {
			txRepos := repository.NewRepositories(tx)
			if err := txRepos.Favorite.Delete(userID, targetType, targetID); err != nil {
				return err
			}
			return txRepos.Project.AddFavoriteCountDelta(project.ID, -1)
		})
	}

	return s.repos.Favorite.Delete(userID, targetType, targetID)
}
