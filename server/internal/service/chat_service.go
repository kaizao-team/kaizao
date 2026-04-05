package service

import (
	"errors"
	"time"

	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/repository"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

// 会话接口业务错误（Handler 用 errors.Is 映射 HTTP / 业务码）
var (
	ErrChatConversationNotFound  = errors.New("chat: conversation not found")
	ErrChatConversationForbidden = errors.New("chat: conversation forbidden")
)

type ConversationService struct {
	repos *repository.Repositories
	log   *zap.Logger
}

func NewConversationService(repos *repository.Repositories, log *zap.Logger) *ConversationService {
	return &ConversationService{repos: repos, log: log}
}

type ConvListItem struct {
	ID              string     `json:"id"`
	PeerID          string     `json:"peer_id"`
	PeerName        string     `json:"peer_name"`
	PeerAvatar      *string    `json:"peer_avatar"`
	LastMessage     string     `json:"last_message"`
	LastMessageTime *time.Time `json:"last_message_time"`
	UnreadCount     int        `json:"unread_count"`
	ProjectTitle    string     `json:"project_title"`
}

func (s *ConversationService) isConversationParticipant(conv *model.Conversation, userID int64) bool {
	if conv == nil {
		return false
	}
	if conv.UserAID != nil && *conv.UserAID == userID {
		return true
	}
	if conv.UserBID != nil && *conv.UserBID == userID {
		return true
	}
	return false
}

// loadActiveConvForParticipant 未删除且当前用户为双方之一；并补全 conversation_members。
func (s *ConversationService) loadActiveConvForParticipant(userID int64, convUUID string) (*model.Conversation, error) {
	conv, err := s.repos.Conversation.FindActiveByUUID(convUUID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrChatConversationNotFound
		}
		return nil, err
	}
	if !s.isConversationParticipant(conv, userID) {
		return nil, ErrChatConversationForbidden
	}
	if err := s.repos.Conversation.EnsurePrivateMembers(conv); err != nil {
		return nil, err
	}
	return conv, nil
}

// ListByUser 分页列出当前用户会话；填充未读、项目标题。
func (s *ConversationService) ListByUser(userUUID string, offset, limit int) ([]ConvListItem, int64, error) {
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return nil, 0, err
	}
	convs, total, err := s.repos.Conversation.ListByUserID(user.ID, offset, limit)
	if err != nil {
		return nil, 0, err
	}
	result := make([]ConvListItem, 0, len(convs))
	for _, c := range convs {
		if err := s.repos.Conversation.EnsurePrivateMembers(c); err != nil {
			s.log.Warn("ListByUser: ensure members", zap.Int64("conv_id", c.ID), zap.Error(err))
		}
		var peerID int64
		if c.UserAID != nil && *c.UserAID == user.ID {
			if c.UserBID != nil {
				peerID = *c.UserBID
			}
		} else if c.UserBID != nil {
			if c.UserAID != nil {
				peerID = *c.UserAID
			}
		}
		peerName := ""
		var peerAvatar *string
		peerUUID := ""
		if peerID > 0 {
			if peer, err := s.repos.User.FindByID(peerID); err == nil {
				peerName = peer.Nickname
				peerAvatar = peer.AvatarURL
				peerUUID = peer.UUID
			}
		}
		lastMsg := ""
		if c.LastMessageContent != nil {
			lastMsg = *c.LastMessageContent
		}
		lastRead := int64(0)
		if m, err := s.repos.Conversation.FindMember(c.ID, user.ID); err == nil {
			lastRead = m.LastReadMsgID
		}
		unread, err := s.repos.Message.CountUnreadFromOthersAfter(c.ID, user.ID, lastRead)
		if err != nil {
			s.log.Warn("ListByUser: unread count", zap.Int64("conv_id", c.ID), zap.Error(err))
			unread = 0
		}
		projectTitle := ""
		if c.ProjectID != nil {
			if p, err := s.repos.Project.FindByID(*c.ProjectID); err == nil {
				projectTitle = p.Title
			}
		}
		result = append(result, ConvListItem{
			ID:              c.UUID,
			PeerID:          peerUUID,
			PeerName:        peerName,
			PeerAvatar:      peerAvatar,
			LastMessage:     lastMsg,
			LastMessageTime: c.LastMessageAt,
			UnreadCount:     int(unread),
			ProjectTitle:    projectTitle,
		})
	}
	return result, total, nil
}

func (s *ConversationService) ListMessages(userUUID, convUUID string, beforeID int64, limit int) ([]*model.Message, error) {
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return nil, err
	}
	conv, err := s.loadActiveConvForParticipant(user.ID, convUUID)
	if err != nil {
		return nil, err
	}
	if limit <= 0 {
		limit = 20
	}
	return s.repos.Message.ListByConversationID(conv.ID, beforeID, limit)
}

func (s *ConversationService) SendMessage(senderUUID, convUUID, content, msgType string) (*model.Message, error) {
	sender, err := s.repos.User.FindByUUID(senderUUID)
	if err != nil {
		return nil, err
	}
	conv, err := s.loadActiveConvForParticipant(sender.ID, convUUID)
	if err != nil {
		return nil, err
	}
	if msgType == "" {
		msgType = "text"
	}
	msg := &model.Message{
		ConversationID: conv.ID,
		SenderID:       sender.ID,
		ContentType:    msgType,
		Content:        &content,
		Status:         1,
	}
	if err := s.repos.Message.Create(msg); err != nil {
		return nil, err
	}
	now := time.Now()
	conv.LastMessageContent = &content
	conv.LastMessageType = &msgType
	conv.LastMessageAt = &now
	conv.LastMessageUserID = &sender.ID
	if err := s.repos.Conversation.Update(conv); err != nil {
		return nil, err
	}
	return msg, nil
}

func (s *ConversationService) MarkRead(userUUID, convUUID string) error {
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return err
	}
	conv, err := s.loadActiveConvForParticipant(user.ID, convUUID)
	if err != nil {
		return err
	}
	maxID, err := s.repos.Message.MaxIDByConversation(conv.ID)
	if err != nil {
		return err
	}
	return s.repos.Conversation.UpdateMemberLastRead(conv.ID, user.ID, maxID)
}

func (s *ConversationService) Delete(userUUID, convUUID string) error {
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return err
	}
	conv, err := s.loadActiveConvForParticipant(user.ID, convUUID)
	if err != nil {
		return err
	}
	conv.Status = 2
	return s.repos.Conversation.Update(conv)
}
