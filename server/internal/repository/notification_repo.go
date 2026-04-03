package repository

import (
	"time"

	"github.com/vibebuild/server/internal/model"
	"gorm.io/gorm"
)

type notificationRepository struct {
	db *gorm.DB
}

func NewNotificationRepository(db *gorm.DB) NotificationRepository {
	return &notificationRepository{db: db}
}

func (r *notificationRepository) Create(notification *model.Notification) error {
	return r.db.Create(notification).Error
}

func (r *notificationRepository) FindByUUID(uuid string) (*model.Notification, error) {
	var n model.Notification
	err := r.db.Where("uuid = ?", uuid).First(&n).Error
	if err != nil {
		return nil, err
	}
	return &n, nil
}

func (r *notificationRepository) Update(notification *model.Notification) error {
	return r.db.Save(notification).Error
}

func (r *notificationRepository) ListByUserID(userID int64, offset, limit int, conditions map[string]interface{}) ([]*model.Notification, int64, error) {
	var notifications []*model.Notification
	var total int64
	query := r.db.Model(&model.Notification{}).Where("user_id = ?", userID)
	for k, v := range conditions {
		query = query.Where(k+" = ?", v)
	}
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	if err := query.Order("created_at DESC").Offset(offset).Limit(limit).Find(&notifications).Error; err != nil {
		return nil, 0, err
	}
	return notifications, total, nil
}

func (r *notificationRepository) CountUnread(userID int64) (int64, error) {
	var count int64
	err := r.db.Model(&model.Notification{}).Where("user_id = ? AND is_read = ?", userID, false).Count(&count).Error
	return count, err
}

func (r *notificationRepository) MarkAllRead(userID int64) error {
	now := time.Now()
	return r.db.Model(&model.Notification{}).
		Where("user_id = ? AND is_read = ?", userID, false).
		Updates(map[string]interface{}{
			"is_read": true,
			"read_at": now,
		}).Error
}

// MarkReadByUserAndUUID 将指定用户名下某条通知标为已读；已读则幂等成功；非本人或无记录返回 ErrRecordNotFound
func (r *notificationRepository) MarkReadByUserAndUUID(userID int64, uuid string) error {
	var n model.Notification
	if err := r.db.Where("user_id = ? AND uuid = ?", userID, uuid).First(&n).Error; err != nil {
		return err
	}
	if n.IsRead {
		return nil
	}
	now := time.Now()
	return r.db.Model(&n).Updates(map[string]interface{}{
		"is_read": true,
		"read_at": now,
	}).Error
}
