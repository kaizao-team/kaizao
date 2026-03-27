package model

import (
	"time"

	"gorm.io/gorm"
)

// Bid 投标模型
type Bid struct {
	ID            int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID          string     `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	ProjectID     int64      `gorm:"not null;index" json:"project_id"`
	BidderID      *int64     `gorm:"index" json:"bidder_id,omitempty"`
	TeamID        *int64     `gorm:"index" json:"team_id,omitempty"`
	Price         float64    `gorm:"type:decimal(10,2);not null" json:"price"`
	EstimatedDays int        `gorm:"not null" json:"estimated_days"`
	Proposal      *string    `gorm:"type:text" json:"proposal,omitempty"`
	TechSolution  *string    `gorm:"type:text" json:"tech_solution,omitempty"`
	Status        int16      `gorm:"not null;default:1;index" json:"status"`
	RejectReason  *string    `gorm:"type:varchar(200)" json:"reject_reason,omitempty"`
	AcceptedAt    *time.Time `json:"accepted_at,omitempty"`
	CreatedAt     time.Time  `gorm:"not null;autoCreateTime" json:"created_at"`
	UpdatedAt     time.Time  `gorm:"not null;autoUpdateTime" json:"updated_at"`

	// 关联
	Project *Project `gorm:"foreignKey:ProjectID" json:"project,omitempty"`
	Bidder  *User    `gorm:"foreignKey:BidderID" json:"bidder,omitempty"`
	Team    *Team    `gorm:"foreignKey:TeamID" json:"team,omitempty"`
}

func (Bid) TableName() string {
	return "bids"
}

func (b *Bid) BeforeCreate(tx *gorm.DB) error {
	if b.UUID == "" {
		b.UUID = GenerateUUID()
	}
	return nil
}
