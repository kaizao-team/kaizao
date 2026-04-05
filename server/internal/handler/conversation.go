package handler

import (
	"errors"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/response"
	"github.com/vibebuild/server/internal/service"
	"go.uber.org/zap"
)

type ConversationHandler struct {
	convService *service.ConversationService
	log         *zap.Logger
}

func NewConversationHandler(convService *service.ConversationService, log *zap.Logger) *ConversationHandler {
	return &ConversationHandler{convService: convService, log: log}
}

func (h *ConversationHandler) List(c *gin.Context) {
	userUUID := c.GetString("user_uuid")
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	if offset < 0 {
		offset = 0
	}
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	items, total, err := h.convService.ListByUser(userUUID, offset, limit)
	if err != nil {
		response.ErrorInternal(c, "获取会话列表失败")
		return
	}
	page := 1
	if limit > 0 {
		page = offset/limit + 1
	}
	meta := response.BuildMeta(page, limit, total)
	response.SuccessWithMeta(c, items, meta)
}

func (h *ConversationHandler) ListMessages(c *gin.Context) {
	convUUID := c.Param("uuid")
	beforeStr := c.Query("before")
	limitStr := c.DefaultQuery("limit", "20")
	var beforeID int64
	if beforeStr != "" {
		beforeID, _ = strconv.ParseInt(beforeStr, 10, 64)
	}
	limit, _ := strconv.Atoi(limitStr)
	if limit <= 0 {
		limit = 20
	}

	userUUID := c.GetString("user_uuid")
	messages, err := h.convService.ListMessages(userUUID, convUUID, beforeID, limit)
	if err != nil {
		h.replyChatError(c, err)
		return
	}

	list := make([]gin.H, 0, len(messages))
	for _, m := range messages {
		senderID := ""
		if m.Sender != nil {
			senderID = m.Sender.UUID
		}
		item := gin.H{
			"id":         m.UUID,
			"sender_id":  senderID,
			"content":    m.Content,
			"type":       m.ContentType,
			"status":     "sent",
			"created_at": m.CreatedAt,
			"extra":      nil,
		}
		list = append(list, item)
	}
	response.Success(c, list)
}

func (h *ConversationHandler) SendMessage(c *gin.Context) {
	convUUID := c.Param("uuid")
	var req struct {
		Content string `json:"content" binding:"required"`
		Type    string `json:"type"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrMessageContentEmpty, "消息内容不能为空")
		return
	}
	userUUID := c.GetString("user_uuid")
	msg, err := h.convService.SendMessage(userUUID, convUUID, req.Content, req.Type)
	if err != nil {
		h.replyChatError(c, err)
		return
	}
	response.Success(c, gin.H{
		"id":     msg.UUID,
		"status": "sent",
	})
}

func (h *ConversationHandler) MarkRead(c *gin.Context) {
	convUUID := c.Param("uuid")
	userUUID := c.GetString("user_uuid")
	if err := h.convService.MarkRead(userUUID, convUUID); err != nil {
		h.replyChatError(c, err)
		return
	}
	response.SuccessMsg(c, "ok", nil)
}

func (h *ConversationHandler) Delete(c *gin.Context) {
	convUUID := c.Param("uuid")
	userUUID := c.GetString("user_uuid")
	if err := h.convService.Delete(userUUID, convUUID); err != nil {
		h.replyChatError(c, err)
		return
	}
	response.SuccessMsg(c, "已删除", nil)
}

func (h *ConversationHandler) replyChatError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, service.ErrChatConversationForbidden):
		response.ErrorForbidden(c, errcode.ErrConversationForbidden, errcode.GetMessage(errcode.ErrConversationForbidden))
	case errors.Is(err, service.ErrChatConversationNotFound):
		response.ErrorNotFound(c, errcode.ErrConversationNotFound, errcode.GetMessage(errcode.ErrConversationNotFound))
	default:
		h.log.Error("conversation op failed", zap.Error(err))
		response.ErrorInternal(c, "操作失败")
	}
}
