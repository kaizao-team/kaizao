package model

import (
	"time"

	"gorm.io/gorm"
)

// Favorite 收藏模型
type Favorite struct {
	ID         int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID       string    `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	UserID     int64     `gorm:"not null;index" json:"user_id"`
	TargetType string    `gorm:"type:varchar(20);not null" json:"target_type"` // "project" / "expert"
	TargetID   string    `gorm:"type:varchar(36);not null" json:"target_id"`   // project=项目UUID, expert=团队UUID
	CreatedAt  time.Time `gorm:"not null;autoCreateTime" json:"created_at"`
}

func (Favorite) TableName() string {
	return "favorites"
}

func (f *Favorite) BeforeCreate(tx *gorm.DB) error {
	if f.UUID == "" {
		f.UUID = GenerateUUID()
	}
	return nil
}
