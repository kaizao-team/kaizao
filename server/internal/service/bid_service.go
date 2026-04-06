package service

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

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

func (s *BidService) FindUserByUUID(userUUID string) (*model.User, error) {
	return s.repos.User.FindByUUID(userUUID)
}

// PrimarySkillName 用户首个（含主技能优先）技能名，供推荐列表展示
func (s *BidService) PrimarySkillName(userID int64) string {
	skills, err := s.repos.User.ListUserSkills(userID)
	if err != nil || len(skills) == 0 {
		return ""
	}
	for _, us := range skills {
		if us.IsPrimary && us.Skill.Name != "" {
			return us.Skill.Name
		}
	}
	if skills[0].Skill.Name != "" {
		return skills[0].Skill.Name
	}
	return ""
}

const recommendationTeamMembersMax = 8

// RecommendationTeamForUserID 解析团队方用户的主团队及成员摘要（供智能推荐、投标列表等）。
// 若用户无活跃团队归属，返回 (nil, nil, nil)。
// maxMembers<=0 时不查询成员列表，仅返回 team。
func (s *BidService) RecommendationTeamForUserID(userID int64, maxMembers int) (*model.Team, []map[string]interface{}, error) {
	team, err := s.repos.Team.FindPrimaryTeamForUser(userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil, nil
		}
		return nil, nil, err
	}
	if maxMembers <= 0 {
		return team, nil, nil
	}
	if maxMembers > recommendationTeamMembersMax {
		maxMembers = recommendationTeamMembersMax
	}
	members, err := s.repos.Team.ListMembers(team.ID)
	if err != nil {
		return nil, nil, err
	}
	out := make([]map[string]interface{}, 0, len(members))
	for i, m := range members {
		if i >= maxMembers {
			break
		}
		row := map[string]interface{}{
			"role_in_team": m.RoleInTeam,
		}
		if m.User != nil {
			row["user_id"] = m.User.UUID
			row["nickname"] = m.User.Nickname
			if m.User.AvatarURL != nil {
				row["avatar_url"] = *m.User.AvatarURL
			}
		}
		out = append(out, row)
	}
	return team, out, nil
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
	if teamID != nil && *teamID != "" {
		team, err := s.repos.Team.FindByUUID(*teamID)
		if err != nil {
			return nil, fmt.Errorf("%d", errcode.ErrParamInvalid)
		}
		if team.LeaderID != bidder.ID {
			if _, err := s.repos.Team.FindMember(team.ID, bidder.ID); err != nil {
				return nil, fmt.Errorf("%d", errcode.ErrTeamBidLeaderOnly)
			}
		}
		bid.TeamID = &team.ID
	}
	targetType := "project"
	tid := project.ID
	content := formatNewBidNotificationContent(bidder.Nickname, project.Title, amount)
	n := &model.Notification{
		UserID:           project.OwnerID,
		Title:            "收到新投标",
		Content:          content,
		NotificationType: model.NotificationTypeNewBid,
		TargetType:       &targetType,
		TargetID:         &tid,
	}

	if err := s.repos.DB().Transaction(func(tx *gorm.DB) error {
		txRepos := repository.NewRepositories(tx)
		if err := txRepos.Bid.Create(bid); err != nil {
			return err
		}
		if err := txRepos.Project.UpdateFields(project.ID, map[string]interface{}{
			"bid_count": project.BidCount + 1,
		}); err != nil {
			return err
		}
		return txRepos.Notification.Create(n)
	}); err != nil {
		return nil, err
	}
	return bid, nil
}

func formatNewBidNotificationContent(expertName, projectTitle string, amount float64) string {
	// 使用 \u00a5 避免编辑器将「¥」误写为全角 U+FFE5，与客户端/测试字面量一致
	return fmt.Sprintf(
		"「%s」对您的项目「%s」提交了投标，报价 \u00a5%.2f",
		expertName, projectTitle, amount,
	)
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
		// status=3 已撮合/履约中（与 Close 中「不可关闭」一致）；status=4 仅用于用户主动关闭需求
		projectUpdates := map[string]interface{}{
			"provider_id":  providerID,
			"bid_id":       bid.ID,
			"status":       3,
			"agreed_price": bid.Price,
			"matched_at":   &now,
		}
		if bid.TeamID != nil {
			projectUpdates["team_id"] = *bid.TeamID
		}
		if err := txRepos.Project.UpdateFields(bid.ProjectID, projectUpdates); err != nil {
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

		if err := txRepos.Conversation.EnsurePrivateMembers(conv); err != nil {
			s.log.Error("AcceptBid: ensure conversation members", zap.Error(err))
			return err
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

// Withdraw 撤回投标（仅 pending 状态可撤回，且仅投标者本人可操作）
func (s *BidService) Withdraw(bidUUID, userUUID string) error {
	bid, err := s.repos.Bid.FindByUUID(bidUUID)
	if err != nil {
		return fmt.Errorf("%d", errcode.ErrBidNotFound)
	}
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return fmt.Errorf("%d", errcode.ErrUserNotFound)
	}
	if bid.BidderID == nil || *bid.BidderID != user.ID {
		return fmt.Errorf("%d", errcode.ErrBidNotFound)
	}
	if bid.Status != 1 {
		return fmt.Errorf("%d", errcode.ErrBidClosed)
	}

	project, err := s.repos.Project.FindByID(bid.ProjectID)
	if err != nil {
		return fmt.Errorf("%d", errcode.ErrProjectNotFound)
	}

	return s.repos.DB().Transaction(func(tx *gorm.DB) error {
		txRepos := repository.NewRepositories(tx)
		if err := txRepos.Bid.UpdateFields(bid.ID, map[string]interface{}{"status": 4}); err != nil {
			return err
		}
		newCount := project.BidCount - 1
		if newCount < 0 {
			newCount = 0
		}
		return txRepos.Project.UpdateFields(project.ID, map[string]interface{}{"bid_count": newCount})
	})
}

func pickQuickMatchPrice(p *model.Project) float64 {
	if p.BudgetMin != nil && p.BudgetMax != nil && *p.BudgetMax >= *p.BudgetMin && *p.BudgetMin > 0 {
		return (*p.BudgetMin + *p.BudgetMax) / 2
	}
	if p.BudgetMax != nil && *p.BudgetMax > 0 {
		return *p.BudgetMax
	}
	if p.BudgetMin != nil && *p.BudgetMin > 0 {
		return *p.BudgetMin
	}
	return 1000
}

func buildQuickMatchProposal(matchScore float64, reason string) string {
	r := strings.TrimSpace(reason)
	if utf8.RuneCountInString(r) > 500 {
		r = string([]rune(r)[:500]) + "…"
	}
	if r == "" {
		return fmt.Sprintf("【AI快速匹配】系统根据智能推荐选定您，匹配度 %.1f。", matchScore)
	}
	return fmt.Sprintf("【AI快速匹配】匹配度 %.1f。%s", matchScore, r)
}

// QuickMatch 需求方一键撮合：为 AI 推荐的团队方（providerUUID + providerTeamID）创建（或复用）待处理投标并立即 Accept。
func (s *BidService) QuickMatch(ownerUUID, projectUUID, providerUUID string, providerTeamID int64, matchScore float64, reason string) (*model.Bid, error) {
	owner, err := s.repos.User.FindByUUID(ownerUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrUserNotFound)
	}
	project, err := s.repos.Project.FindByUUID(projectUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrProjectNotFound)
	}
	if project.OwnerID != owner.ID {
		return nil, fmt.Errorf("%d", errcode.ErrProjectOwnerOnly)
	}
	if project.Status != 2 {
		return nil, fmt.Errorf("%d", errcode.ErrProjectStatusInvalid)
	}
	if project.ProviderID != nil {
		return nil, fmt.Errorf("%d", errcode.ErrProjectAlreadyMatched)
	}

	provider, err := s.repos.User.FindByUUID(providerUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrQuickMatchNoCandidate)
	}
	if provider.ID == project.OwnerID {
		return nil, fmt.Errorf("%d", errcode.ErrQuickMatchNoCandidate)
	}
	if providerTeamID <= 0 {
		return nil, fmt.Errorf("%d", errcode.ErrQuickMatchNoCandidate)
	}

	bid, err := s.repos.Bid.FindPendingByProjectAndBidderID(project.ID, provider.ID)
	if err != nil {
		if !errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, err
		}
		prop := buildQuickMatchProposal(matchScore, reason)
		tid := providerTeamID
		bid = &model.Bid{
			ProjectID:     project.ID,
			BidderID:      &provider.ID,
			TeamID:        &tid,
			Price:         pickQuickMatchPrice(project),
			EstimatedDays: 14,
			Proposal:      &prop,
			Status:        1,
		}
		if err := s.repos.Bid.Create(bid); err != nil {
			return nil, err
		}
		if err := s.repos.Project.UpdateFields(project.ID, map[string]interface{}{
			"bid_count": project.BidCount + 1,
		}); err != nil {
			return nil, err
		}
	} else {
		if bid.TeamID == nil || *bid.TeamID != providerTeamID {
			if err := s.repos.Bid.UpdateFields(bid.ID, map[string]interface{}{"team_id": providerTeamID}); err != nil {
				return nil, err
			}
			tid := providerTeamID
			bid.TeamID = &tid
		}
	}

	if _, err := s.Accept(bid.UUID, ownerUUID); err != nil {
		return nil, err
	}
	return s.repos.Bid.FindByUUID(bid.UUID)
}
