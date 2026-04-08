package model

import (
	"time"

	"gorm.io/gorm"
)

// 入驻审核状态（与 users.onboarding_status 一致）
const (
	OnboardingPending  int16 = 1
	OnboardingApproved int16 = 2
	OnboardingRejected int16 = 3
)

// 团队审核状态（teams.approval_status）
const (
	TeamApprovalPending  int16 = 1
	TeamApprovalApproved int16 = 2
	TeamApprovalRejected int16 = 3
)

// InviteCode 团队邀请码（hash 核销；当前有效码的明文存 code_plain 供管理端查看）
type InviteCode struct {
	ID               int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID             string     `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	TeamID           *int64     `gorm:"index" json:"team_id,omitempty"`
	CodeHash         string     `gorm:"type:varchar(64);not null;uniqueIndex" json:"-"`
	CodePlain        *string    `gorm:"type:varchar(32)" json:"code_plain,omitempty"`
	CodeHint         string     `gorm:"type:varchar(20);not null;default:''" json:"code_hint"`
	Note             string     `gorm:"type:varchar(200)" json:"note"`
	MaxUses          int        `gorm:"not null;default:1" json:"max_uses"`
	UsedCount        int        `gorm:"not null;default:0" json:"used_count"`
	ExpiresAt        *time.Time `json:"expires_at,omitempty"`
	AllowedRoles     JSON       `gorm:"type:json" json:"allowed_roles,omitempty"`
	DisabledAt       *time.Time `json:"disabled_at,omitempty"`
	CreatedByUserID  *int64     `json:"created_by_user_id,omitempty"`
	CreatedAt        time.Time  `gorm:"not null;autoCreateTime" json:"created_at"`
	UpdatedAt        time.Time  `gorm:"not null;autoUpdateTime" json:"updated_at"`
}

func (InviteCode) TableName() string {
	return "invite_codes"
}

func (ic *InviteCode) BeforeCreate(tx *gorm.DB) error {
	if ic.UUID == "" {
		ic.UUID = GenerateUUID()
	}
	return nil
}
