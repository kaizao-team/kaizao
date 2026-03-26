package service

import (
	"fmt"
	"time"

	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/repository"
	"go.uber.org/zap"
)

type BidService struct {
	repos *repository.Repositories
	log   *zap.Logger
}

func NewBidService(repos *repository.Repositories, log *zap.Logger) *BidService {
	return &BidService{repos: repos, log: log}
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

func (s *BidService) Accept(bidUUID, ownerUUID string) (*model.Bid, error) {
	bid, err := s.repos.Bid.FindByUUID(bidUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrBidNotFound)
	}
	now := time.Now()
	bid.Status = 2
	bid.AcceptedAt = &now
	if err := s.repos.Bid.Update(bid); err != nil {
		return nil, err
	}

	if bid.BidderID != nil {
		s.repos.Project.UpdateFields(bid.ProjectID, map[string]interface{}{
			"provider_id": *bid.BidderID,
			"bid_id":      bid.ID,
			"status":      3,
			"agreed_price": bid.Price,
			"matched_at":  &now,
		})
	}
	return bid, nil
}
