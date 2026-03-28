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

func (r *inviteCodeRepository) DisableActiveUnusedForTeam(teamID int64) error {
	now := time.Now()
	return r.db.Model(&model.InviteCode{}).
		Where("team_id = ? AND disabled_at IS NULL AND used_count < max_uses", teamID).
		Updates(map[string]interface{}{"disabled_at": now}).Error
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

// FindActiveByTeamID 当前团队下仍有效的最新一条邀请码
func (r *inviteCodeRepository) FindActiveByTeamID(teamID int64) (*model.InviteCode, error) {
	var ic model.InviteCode
	err := r.db.Where("team_id = ? AND disabled_at IS NULL AND used_count < max_uses", teamID).
		Where("(expires_at IS NULL OR expires_at > NOW())").
		Order("id DESC").First(&ic).Error
	if err != nil {
		return nil, err
	}
	return &ic, nil
}

// ConsumeTeamInviteAndRotate 核销一次并为本团队生成新码（新码明文写入新行）
func (r *inviteCodeRepository) ConsumeTeamInviteAndRotate(plain string) (*model.InviteCode, *model.InviteCode, error) {
	h := invitehash.Hash(plain)
	var consumed *model.InviteCode
	var created *model.InviteCode
	err := r.db.Transaction(func(tx *gorm.DB) error {
		var ic model.InviteCode
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).Where("code_hash = ?", h).First(&ic).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				return fmt.Errorf("%d", errcode.ErrInviteInvalid)
			}
			return err
		}
		if ic.TeamID == nil || *ic.TeamID == 0 {
			return fmt.Errorf("%d", errcode.ErrInviteInvalid)
		}
		if ic.DisabledAt != nil {
			return fmt.Errorf("%d", errcode.ErrInviteInvalid)
		}
		if ic.ExpiresAt != nil && time.Now().After(*ic.ExpiresAt) {
			return fmt.Errorf("%d", errcode.ErrInviteInvalid)
		}
		if ic.UsedCount >= ic.MaxUses {
			return fmt.Errorf("%d", errcode.ErrInviteExhausted)
		}
		if err := tx.Model(&model.InviteCode{}).Where("id = ?", ic.ID).Updates(map[string]interface{}{
			"used_count": ic.MaxUses,
			"code_plain": nil,
		}).Error; err != nil {
			return err
		}

		newPlain := invitehash.GeneratePlain("KZ-")
		nh := invitehash.Hash(newPlain)
		hint := newPlain
		if len(newPlain) >= 4 {
			hint = newPlain[len(newPlain)-4:]
		}
		newRec := &model.InviteCode{
			TeamID:          ic.TeamID,
			CodeHash:        nh,
			CodePlain:       &newPlain,
			CodeHint:        hint,
			Note:            ic.Note,
			MaxUses:         1,
			UsedCount:       0,
			ExpiresAt:       ic.ExpiresAt,
			AllowedRoles:    ic.AllowedRoles,
			CreatedByUserID: ic.CreatedByUserID,
		}
		if err := tx.Create(newRec).Error; err != nil {
			return err
		}
		consumed = &ic
		created = newRec
		return nil
	})
	return consumed, created, err
}
