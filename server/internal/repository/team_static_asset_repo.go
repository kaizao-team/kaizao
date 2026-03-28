package repository

import (
	"github.com/vibebuild/server/internal/model"
	"gorm.io/gorm"
)

type teamStaticAssetRepository struct {
	db *gorm.DB
}

func NewTeamStaticAssetRepository(db *gorm.DB) TeamStaticAssetRepository {
	return &teamStaticAssetRepository{db: db}
}

func (r *teamStaticAssetRepository) Create(a *model.TeamStaticAsset) error {
	return r.db.Create(a).Error
}

func (r *teamStaticAssetRepository) ListByTeamID(teamID int64, offset, limit int) ([]*model.TeamStaticAsset, int64, error) {
	var list []*model.TeamStaticAsset
	var total int64
	q := r.db.Model(&model.TeamStaticAsset{}).Where("team_id = ?", teamID)
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	if err := q.Order("id DESC").Offset(offset).Limit(limit).Find(&list).Error; err != nil {
		return nil, 0, err
	}
	return list, total, nil
}
