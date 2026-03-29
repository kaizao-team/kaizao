package service

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/repository"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

type BidService struct {
	repos    *repository.Repositories
	orderSvc *OrderService
	log      *zap.Logger
}

func NewBidService(repos *repository.Repositories, orderSvc *OrderService, log *zap.Logger) *BidService {
	return &BidService{repos: repos, orderSvc: orderSvc, log: log}
}

func (s *BidService) ListByProject(projectUUID string) ([]*model.Bid, error) {
	project, err := s.repos.Project.FindByUUID(projectUUID)
	if err != nil {
		return nil, err
	}
	bids, _, err := s.repos.Bid.ListByProjectID(project.ID, 0, 100)
	return bids, err
}

func (s *BidService) Create(bidderUUID, projectUUID string, amount float64, durationDays int, proposal, bidType string, teamID *string) (*model.Bid, error) {
	bidder, err := s.repos.User.FindByUUID(bidderUUID)
	if err != nil {
		return nil, err
	}
	project, err := s.repos.Project.FindByUUID(projectUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrProjectNotFound)
	}
	if project.OwnerID == bidder.ID {
		return nil, fmt.Errorf("%d", errcode.ErrBidOwnProject)
	}

	bid := &model.Bid{
		ProjectID:     project.ID,
		BidderID:      &bidder.ID,
		Price:         amount,
		EstimatedDays: durationDays,
		Proposal:      &proposal,
		Status:        1,
	}
	if err := s.repos.Bid.Create(bid); err != nil {
		return nil, err
	}

	s.repos.Project.UpdateFields(project.ID, map[string]interface{}{
		"bid_count": project.BidCount + 1,
	})
	return bid, nil
}

func displayPhoneForNotify(u *model.User) string {
	if u == nil {
		return "（未留电话）"
	}
	if u.ContactPhone != nil {
		if t := strings.TrimSpace(*u.ContactPhone); t != "" {
			return t
		}
	}
	if u.Phone != nil && *u.Phone != "" {
		p := *u.Phone
		if len(p) >= 11 {
			return p[:3] + "****" + p[7:]
		}
		return p
	}
	return "（未留电话）"
}

func (s *BidService) Accept(bidUUID, ownerUUID string) (*model.Bid, error) {
	bid, err := s.repos.Bid.FindByUUID(bidUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrBidNotFound)
	}
	if bid.Status == 2 {
		return bid, nil
	}
	if bid.Status != 1 {
		return nil, fmt.Errorf("%d", errcode.ErrBidClosed)
	}
	if bid.BidderID == nil {
		return nil, fmt.Errorf("%d", errcode.ErrBidNotFound)
	}

	ownerUser, err := s.repos.User.FindByUUID(ownerUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrUserNotFound)
	}
	project, err := s.repos.Project.FindByID(bid.ProjectID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrProjectNotFound)
	}
	if project.OwnerID != ownerUser.ID {
		return nil, fmt.Errorf("%d", errcode.ErrProjectOwnerOnly)
	}

	providerID := *bid.BidderID
	providerUser, err := s.repos.User.FindByID(providerID)
	if err != nil {
		s.log.Error("AcceptBid: load provider", zap.Error(err))
		return nil, err
	}

	now := time.Now()
	projectTitle := project.Title
	demanderPhone := displayPhoneForNotify(ownerUser)
	expertPhone := displayPhoneForNotify(providerUser)
	targetType := "project"
	tid := project.ID
	contentDemander := fmt.Sprintf(
		"已有团队/专家撮合成功，我们将尽快接洽。项目「%s」。对方联系电话：%s",
		projectTitle, expertPhone,
	)
	nDemander := &model.Notification{
		UserID:           project.OwnerID,
		Title:            "撮合成功",
		Content:          contentDemander,
		NotificationType: model.NotificationTypeMatchSuccess,
		TargetType:       &targetType,
		TargetID:         &tid,
	}
	contentExpert := fmt.Sprintf(
		"您已被选定为「%s」的服务方，请尽快联系需求方沟通详情。需求方联系电话：%s",
		projectTitle, demanderPhone,
	)
	nExpert := &model.Notification{
		UserID:           providerID,
		Title:            "恭喜被选定",
		Content:          contentExpert,
		NotificationType: model.NotificationTypeMatchSuccess,
		TargetType:       &targetType,
		TargetID:         &tid,
	}

	var createdPayOrd *model.Order
	if err := s.repos.DB().Transaction(func(tx *gorm.DB) error {
		txRepos := repository.NewRepositories(tx)
		bid.Status = 2
		bid.AcceptedAt = &now
		if err := txRepos.Bid.Update(bid); err != nil {
			return err
		}
		if err := txRepos.Project.UpdateFields(bid.ProjectID, map[string]interface{}{
			"provider_id":  providerID,
			"bid_id":       bid.ID,
			"status":       3,
			"agreed_price": bid.Price,
			"matched_at":   &now,
		}); err != nil {
			return err
		}
		if err := txRepos.Notification.Create(nDemander); err != nil {
			s.log.Error("AcceptBid: notify demander", zap.Error(err))
			return err
		}
		if err := txRepos.Notification.Create(nExpert); err != nil {
			s.log.Error("AcceptBid: notify expert", zap.Error(err))
			return err
		}

		aID, bID := project.OwnerID, providerID
		if aID > bID {
			aID, bID = bID, aID
		}
		pid := project.ID
		var conv *model.Conversation
		existing, errConv := txRepos.Conversation.FindPrivateConversation(project.OwnerID, providerID)
		if errConv == nil {
			conv = existing
			if conv.ProjectID == nil || *conv.ProjectID != project.ID {
				conv.ProjectID = &pid
				if err := txRepos.Conversation.Update(conv); err != nil {
					s.log.Error("AcceptBid: update conversation project_id", zap.Error(err))
					return err
				}
			}
		} else if errors.Is(errConv, gorm.ErrRecordNotFound) {
			conv = &model.Conversation{
				ProjectID:        &pid,
				ConversationType: 1,
				UserAID:          &aID,
				UserBID:          &bID,
				Status:           1,
			}
			if err := txRepos.Conversation.Create(conv); err != nil {
				s.log.Error("AcceptBid: create conversation", zap.Error(err))
				return err
			}
		} else {
			return errConv
		}

		sysText := "撮合成功！你们已经可以开始沟通了"
		sysType := "system"
		msg := &model.Message{
			ConversationID: conv.ID,
			SenderID:       project.OwnerID,
			ContentType:    sysType,
			Content:        &sysText,
			Status:         1,
		}
		if err := txRepos.Message.Create(msg); err != nil {
			s.log.Error("AcceptBid: system message", zap.Error(err))
			return err
		}
		conv.LastMessageContent = &sysText
		conv.LastMessageType = &sysType
		conv.LastMessageAt = &now
		ownerID := project.OwnerID
		conv.LastMessageUserID = &ownerID
		if err := txRepos.Conversation.Update(conv); err != nil {
			s.log.Error("AcceptBid: update conversation last message", zap.Error(err))
			return err
		}

		payOrd, errOrd := s.orderSvc.createPendingProjectOrderWithRepos(txRepos, project.ID, project.OwnerID, providerID, bid.Price)
		if errOrd != nil {
			code, _ := strconv.Atoi(errOrd.Error())
			if code != errcode.ErrOrderAlreadyExists {
				s.log.Error("AcceptBid: create order", zap.Error(errOrd))
				return errOrd
			}
			payOrd = nil
		}
		createdPayOrd = payOrd
		return nil
	}); err != nil {
		return nil, err
	}

	if createdPayOrd != nil {
		if err := s.orderSvc.NotifyPayerPendingOrder(project.OwnerID, createdPayOrd, projectTitle); err != nil {
			s.log.Error("AcceptBid: payment notify", zap.Error(err))
		}
	}

	return bid, nil
}
