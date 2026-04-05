package model

import (
	"time"

	"gorm.io/gorm"
)

// ProjectFile 项目共享文件元数据（实体在对象存储）
type ProjectFile struct {
	ID                 int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID               string     `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	ProjectID          int64      `gorm:"not null;index" json:"project_id"`
	UploadedByUserID   int64      `gorm:"not null;index" json:"uploaded_by_user_id"`
	MilestoneID        *int64     `gorm:"index" json:"milestone_id,omitempty"`
	Bucket             string     `gorm:"type:varchar(128);not null" json:"bucket"`
	ObjectKey          string     `gorm:"type:varchar(512);not null" json:"object_key"`
	OriginalName       string     `gorm:"type:varchar(255);not null" json:"original_name"`
	ContentType        string     `gorm:"type:varchar(128);not null" json:"content_type"`
	SizeBytes          int64      `gorm:"not null" json:"size_bytes"`
	FileKind           string     `gorm:"type:varchar(32);not null;default:process" json:"file_kind"`
	Storage            string     `gorm:"type:varchar(32);not null;default:minio" json:"storage"`
	CreatedAt          time.Time  `gorm:"not null;autoCreateTime" json:"created_at"`
	UpdatedAt          time.Time  `gorm:"not null;autoUpdateTime" json:"updated_at"`
	Uploader           *User      `gorm:"foreignKey:UploadedByUserID" json:"uploader,omitempty"`
}

func (ProjectFile) TableName() string {
	return "project_files"
}

func (f *ProjectFile) BeforeCreate(tx *gorm.DB) error {
	if f.UUID == "" {
		f.UUID = GenerateUUID()
	}
	return nil
}
