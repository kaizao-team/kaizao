package repository

import (
	"github.com/vibebuild/server/internal/model"
	"gorm.io/gorm"
)

type favoriteRepository struct {
	db *gorm.DB
}

func NewFavoriteRepository(db *gorm.DB) FavoriteRepository {
	return &favoriteRepository{db: db}
}

func (r *favoriteRepository) Create(fav *model.Favorite) error {
	return r.db.Create(fav).Error
}

func (r *favoriteRepository) Delete(userID int64, targetType, targetID string) error {
	return r.db.Where("user_id = ? AND target_type = ? AND target_id = ?", userID, targetType, targetID).
		Delete(&model.Favorite{}).Error
}

func (r *favoriteRepository) FindByUserAndTarget(userID int64, targetType, targetID string) (*model.Favorite, error) {
	var fav model.Favorite
	err := r.db.Where("user_id = ? AND target_type = ? AND target_id = ?", userID, targetType, targetID).
		First(&fav).Error
	if err != nil {
		return nil, err
	}
	return &fav, nil
}

func (r *favoriteRepository) ListByUserID(userID int64, targetType string, offset, limit int) ([]*model.Favorite, int64, error) {
	var favs []*model.Favorite
	var total int64
	q := r.db.Model(&model.Favorite{}).Where("user_id = ?", userID)
	if targetType != "" {
		q = q.Where("target_type = ?", targetType)
	}
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	if err := q.Order("created_at DESC").Offset(offset).Limit(limit).Find(&favs).Error; err != nil {
		return nil, 0, err
	}
	return favs, total, nil
}
