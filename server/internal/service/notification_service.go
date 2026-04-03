package service

import (
	"errors"

	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/repository"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

// ErrNotificationMarkNotFound 单条标记已读时通知不存在或非本人
var ErrNotificationMarkNotFound = errors.New("notification not found")

// NotificationService 通知业务
type NotificationService struct {
	repos *repository.Repositories
	log   *zap.Logger
}

func NewNotificationService(repos *repository.Repositories, log *zap.Logger) *NotificationService {
	return &NotificationService{repos: repos, log: log}
}

// List 分页列表，可选按 notification_type 筛选（query 参数 type）
func (s *NotificationService) List(userUUID string, page, pageSize int, typeFilter *int16) ([]*model.Notification, int64, error) {
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return nil, 0, err
	}
	if page <= 0 {
		page = 1
	}
	if pageSize <= 0 {
		pageSize = 20
	}
	if pageSize > 100 {
		pageSize = 100
	}
	offset := (page - 1) * pageSize
	conds := map[string]interface{}{}
	if typeFilter != nil {
		conds["notification_type"] = *typeFilter
	}
	return s.repos.Notification.ListByUserID(user.ID, offset, pageSize, conds)
}

func (s *NotificationService) MarkRead(userUUID, notifUUID string) error {
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return err
	}
	if err := s.repos.Notification.MarkReadByUserAndUUID(user.ID, notifUUID); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrNotificationMarkNotFound
		}
		return err
	}
	return nil
}

func (s *NotificationService) MarkAllRead(userUUID string) error {
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return err
	}
	return s.repos.Notification.MarkAllRead(user.ID)
}

func (s *NotificationService) UnreadCount(userUUID string) (int64, error) {
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return 0, err
	}
	return s.repos.Notification.CountUnread(user.ID)
}
