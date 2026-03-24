package handler

import (
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
	items, err := h.convService.ListByUser(userUUID)
	if err != nil {
		response.ErrorInternal(c, "获取会话列表失败")
		return
	}
	response.Success(c, items)
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

	messages, err := h.convService.ListMessages(convUUID, beforeID, limit)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrConversationNotFound, "会话不存在")
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
		response.ErrorNotFound(c, errcode.ErrConversationNotFound, "会话不存在")
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
		response.ErrorNotFound(c, errcode.ErrConversationNotFound, "会话不存在")
		return
	}
	response.SuccessMsg(c, "ok", nil)
}

func (h *ConversationHandler) Delete(c *gin.Context) {
	convUUID := c.Param("uuid")
	userUUID := c.GetString("user_uuid")
	if err := h.convService.Delete(userUUID, convUUID); err != nil {
		response.ErrorNotFound(c, errcode.ErrConversationNotFound, "会话不存在")
		return
	}
	response.SuccessMsg(c, "已删除", nil)
}
