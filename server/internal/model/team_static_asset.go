package model

import (
	"time"

	"gorm.io/gorm"
)

// TeamStaticAsset 团队静态文件元数据（二进制在对象存储）
type TeamStaticAsset struct {
	ID                int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID              string    `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	TeamID            int64     `gorm:"not null;index" json:"team_id"`
	UploadedByUserID  int64     `gorm:"not null;index" json:"uploaded_by_user_id"`
	Bucket            string    `gorm:"type:varchar(128);not null" json:"bucket"`
	ObjectKey         string    `gorm:"type:varchar(512);not null" json:"object_key"`
	OriginalName      string    `gorm:"type:varchar(255);not null" json:"original_name"`
	ContentType       string    `gorm:"type:varchar(128);not null" json:"content_type"`
	SizeBytes         int64     `gorm:"not null" json:"size_bytes"`
	Purpose           string    `gorm:"type:varchar(64);not null;default:content" json:"purpose"`
	Storage           string    `gorm:"type:varchar(32);not null;default:minio" json:"storage"`
	CreatedAt         time.Time `gorm:"not null;autoCreateTime" json:"created_at"`
	UpdatedAt         time.Time `gorm:"not null;autoUpdateTime" json:"updated_at"`
}

func (TeamStaticAsset) TableName() string {
	return "team_static_assets"
}

func (a *TeamStaticAsset) BeforeCreate(tx *gorm.DB) error {
	if a.UUID == "" {
		a.UUID = GenerateUUID()
	}
	return nil
}
