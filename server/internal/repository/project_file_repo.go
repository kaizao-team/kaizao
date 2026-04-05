package repository

import (
	"github.com/vibebuild/server/internal/model"
	"gorm.io/gorm"
)

type projectFileRepository struct {
	db *gorm.DB
}

func NewProjectFileRepository(db *gorm.DB) ProjectFileRepository {
	return &projectFileRepository{db: db}
}

func (r *projectFileRepository) Create(f *model.ProjectFile) error {
	return r.db.Create(f).Error
}

func (r *projectFileRepository) FindByUUIDAndProjectID(projectID int64, fileUUID string) (*model.ProjectFile, error) {
	var f model.ProjectFile
	err := r.db.Preload("Uploader").Where("project_id = ? AND uuid = ?", projectID, fileUUID).First(&f).Error
	if err != nil {
		return nil, err
	}
	return &f, nil
}

func (r *projectFileRepository) ListByProjectID(projectID int64, fileKind string, milestoneID *int64, offset, limit int) ([]*model.ProjectFile, int64, error) {
	var list []*model.ProjectFile
	var total int64
	q := r.db.Model(&model.ProjectFile{}).Where("project_id = ?", projectID)
	if fileKind != "" {
		q = q.Where("file_kind = ?", fileKind)
	}
	if milestoneID != nil {
		q = q.Where("milestone_id = ?", *milestoneID)
	}
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := q.Preload("Uploader").Order("id DESC").Offset(offset).Limit(limit).Find(&list).Error
	if err != nil {
		return nil, 0, err
	}
	return list, total, nil
}
