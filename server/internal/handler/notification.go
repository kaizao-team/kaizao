package handler

import (
	"errors"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/response"
	"github.com/vibebuild/server/internal/service"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

type NotificationHandler struct {
	svc *service.NotificationService
	log *zap.Logger
}

func NewNotificationHandler(svc *service.NotificationService, log *zap.Logger) *NotificationHandler {
	return &NotificationHandler{svc: svc, log: log}
}

// List GET /notifications
func (h *NotificationHandler) List(c *gin.Context) {
	userUUID := c.GetString("user_uuid")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	var typeFilter *int16
	if ts := c.Query("type"); ts != "" {
		v, err := strconv.ParseInt(ts, 10, 16)
		if err != nil {
			response.ErrorBadRequest(c, errcode.ErrParamInvalid, "type 参数无效")
			return
		}
		t := int16(v)
		typeFilter = &t
	}

	items, total, err := h.svc.List(userUUID, page, pageSize, typeFilter)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.ErrorNotFound(c, errcode.ErrUserNotFound, "用户不存在")
			return
		}
		response.ErrorInternal(c, "获取通知列表失败")
		return
	}

	list := make([]gin.H, 0, len(items))
	for _, n := range items {
		var targetType interface{}
		if n.TargetType != nil {
			targetType = *n.TargetType
		}
		var targetID interface{}
		if n.TargetID != nil {
			targetID = *n.TargetID
		}
		var readAt interface{}
		if n.ReadAt != nil {
			readAt = *n.ReadAt
		}
		list = append(list, gin.H{
			"id":                 n.UUID,
			"uuid":               n.UUID,
			"title":              n.Title,
			"content":            n.Content,
			"type":               n.NotificationType,
			"notification_type":  n.NotificationType,
			"target_type":        targetType,
			"target_id":          targetID,
			"is_read":            n.IsRead,
			"read_at":            readAt,
			"created_at":         n.CreatedAt,
		})
	}
	response.SuccessWithMeta(c, list, response.BuildMeta(page, pageSize, total))
}

// MarkRead PUT /notifications/:uuid/read
func (h *NotificationHandler) MarkRead(c *gin.Context) {
	userUUID := c.GetString("user_uuid")
	uuid := c.Param("uuid")
	if uuid == "" {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数错误")
		return
	}
	if err := h.svc.MarkRead(userUUID, uuid); err != nil {
		if errors.Is(err, service.ErrNotificationMarkNotFound) {
			response.ErrorNotFound(c, errcode.ErrNotificationNotFound, errcode.GetMessage(errcode.ErrNotificationNotFound))
			return
		}
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.ErrorNotFound(c, errcode.ErrUserNotFound, "用户不存在")
			return
		}
		response.ErrorInternal(c, "操作失败")
		return
	}
	response.SuccessMsg(c, "ok", nil)
}

// MarkAllRead PUT /notifications/read-all
func (h *NotificationHandler) MarkAllRead(c *gin.Context) {
	userUUID := c.GetString("user_uuid")
	if err := h.svc.MarkAllRead(userUUID); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.ErrorNotFound(c, errcode.ErrUserNotFound, "用户不存在")
			return
		}
		response.ErrorInternal(c, "操作失败")
		return
	}
	response.SuccessMsg(c, "ok", nil)
}

// UnreadCount GET /notifications/unread-count
func (h *NotificationHandler) UnreadCount(c *gin.Context) {
	userUUID := c.GetString("user_uuid")
	n, err := h.svc.UnreadCount(userUUID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.ErrorNotFound(c, errcode.ErrUserNotFound, "用户不存在")
			return
		}
		response.ErrorInternal(c, "获取未读数失败")
		return
	}
	response.Success(c, gin.H{"unread_count": n})
}
