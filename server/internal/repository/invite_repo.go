package repository

import (
	"fmt"
	"time"

	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/invitehash"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type inviteCodeRepository struct {
	db *gorm.DB
}

func NewInviteCodeRepository(db *gorm.DB) InviteCodeRepository {
	return &inviteCodeRepository{db: db}
}

func (r *inviteCodeRepository) Create(ic *model.InviteCode) error {
	return r.db.Create(ic).Error
}

func (r *inviteCodeRepository) BatchCreate(codes []*model.InviteCode) error {
	return r.db.Create(&codes).Error
}

func (r *inviteCodeRepository) List(offset, limit int, teamID *int64) ([]*model.InviteCode, int64, error) {
	var list []*model.InviteCode
	var total int64
	q := r.db.Model(&model.InviteCode{})
	if teamID != nil {
		q = q.Where("team_id = ?", *teamID)
	}
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	if err := q.Order("id DESC").Offset(offset).Limit(limit).Find(&list).Error; err != nil {
		return nil, 0, err
	}
	return list, total, nil
}

// ConsumeWithTx 在调用方提供的事务内核销一次邀请码（行锁 → 校验 → 标记用尽）。
// 核销后不再自动生成新码。
func (r *inviteCodeRepository) ConsumeWithTx(tx *gorm.DB, plain string) (*model.InviteCode, error) {
	h := invitehash.Hash(plain)
	var ic model.InviteCode
	if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
		Where("code_hash = ?", h).First(&ic).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("%d", errcode.ErrInviteInvalid)
		}
		return nil, err
	}
	if ic.DisabledAt != nil {
		return nil, fmt.Errorf("%d", errcode.ErrInviteInvalid)
	}
	if ic.ExpiresAt != nil && time.Now().After(*ic.ExpiresAt) {
		return nil, fmt.Errorf("%d", errcode.ErrInviteInvalid)
	}
	if ic.UsedCount >= ic.MaxUses {
		return nil, fmt.Errorf("%d", errcode.ErrInviteExhausted)
	}
	if err := tx.Model(&model.InviteCode{}).Where("id = ?", ic.ID).Updates(map[string]interface{}{
		"used_count": ic.MaxUses,
		"code_plain": nil,
	}).Error; err != nil {
		return nil, err
	}
	ic.UsedCount = ic.MaxUses
	ic.CodePlain = nil
	return &ic, nil
}
