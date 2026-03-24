package model

import (
	"time"

	"gorm.io/gorm"
)

// Coupon 优惠券模型
type Coupon struct {
	ID              int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID            string     `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	UserID          int64      `gorm:"not null;index" json:"user_id"`
	Title           string     `gorm:"type:varchar(100);not null" json:"title"`
	DiscountAmount  float64    `gorm:"type:decimal(10,2);not null" json:"discount_amount"`
	MinOrderAmount  float64    `gorm:"type:decimal(10,2);not null;default:0" json:"min_order_amount"`
	ExpireDate      time.Time  `gorm:"type:date;not null" json:"expire_date"`
	IsUsed          bool       `gorm:"not null;default:false" json:"is_used"`
	UsedAt          *time.Time `json:"used_at,omitempty"`
	Status          int16      `gorm:"not null;default:1" json:"status"`
	CreatedAt       time.Time  `gorm:"not null;autoCreateTime" json:"created_at"`
}

func (Coupon) TableName() string {
	return "coupons"
}

func (c *Coupon) BeforeCreate(tx *gorm.DB) error {
	if c.UUID == "" {
		c.UUID = GenerateUUID()
	}
	return nil
}
