package service

import (
	"fmt"
	"time"

	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/repository"
	"go.uber.org/zap"
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

func (s *ConversationService) ListByUser(userUUID string) ([]ConvListItem, error) {
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return nil, err
	}
	convs, _, err := s.repos.Conversation.ListByUserID(user.ID, 0, 50)
	if err != nil {
		return nil, err
	}
	result := make([]ConvListItem, 0, len(convs))
	for _, c := range convs {
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
		result = append(result, ConvListItem{
			ID:              c.UUID,
			PeerID:          peerUUID,
			PeerName:        peerName,
			PeerAvatar:      peerAvatar,
			LastMessage:     lastMsg,
			LastMessageTime: c.LastMessageAt,
			UnreadCount:     0,
			ProjectTitle:    "",
		})
	}
	return result, nil
}

func (s *ConversationService) ListMessages(convUUID string, beforeID int64, limit int) ([]*model.Message, error) {
	conv, err := s.repos.Conversation.FindByUUID(convUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrConversationNotFound)
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
	conv, err := s.repos.Conversation.FindByUUID(convUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrConversationNotFound)
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
	s.repos.Conversation.Update(conv)
	return msg, nil
}

func (s *ConversationService) MarkRead(userUUID, convUUID string) error {
	_, err := s.repos.Conversation.FindByUUID(convUUID)
	if err != nil {
		return fmt.Errorf("%d", errcode.ErrConversationNotFound)
	}
	return nil
}

func (s *ConversationService) Delete(userUUID, convUUID string) error {
	conv, err := s.repos.Conversation.FindByUUID(convUUID)
	if err != nil {
		return fmt.Errorf("%d", errcode.ErrConversationNotFound)
	}
	conv.Status = 2
	return s.repos.Conversation.Update(conv)
}
