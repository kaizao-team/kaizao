package repository

import (
	"errors"

	"github.com/vibebuild/server/internal/model"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type projectRepository struct {
	db *gorm.DB
}

func NewProjectRepository(db *gorm.DB) ProjectRepository {
	return &projectRepository{db: db}
}

func (r *projectRepository) Create(project *model.Project) error {
	return r.db.Create(project).Error
}

func (r *projectRepository) FindByID(id int64) (*model.Project, error) {
	var project model.Project
	err := r.db.Preload("Owner").Preload("Provider").Where("id = ?", id).First(&project).Error
	if err != nil {
		return nil, err
	}
	return &project, nil
}

func (r *projectRepository) FindByUUID(uuid string) (*model.Project, error) {
	var project model.Project
	err := r.db.Preload("Owner").Preload("Provider").Where("uuid = ?", uuid).First(&project).Error
	if err != nil {
		return nil, err
	}
	return &project, nil
}

func (r *projectRepository) Update(project *model.Project) error {
	return r.db.Save(project).Error
}

func (r *projectRepository) UpdateFields(id int64, fields map[string]interface{}) error {
	return r.db.Model(&model.Project{}).Where("id = ?", id).Updates(fields).Error
}

func (r *projectRepository) AddFavoriteCountDelta(id int64, delta int) error {
	if delta == 0 {
		return nil
	}
	q := r.db.Model(&model.Project{}).Where("id = ?", id)
	if delta > 0 {
		return q.UpdateColumn("favorite_count", gorm.Expr("favorite_count + ?", delta)).Error
	}
	return q.UpdateColumn("favorite_count", gorm.Expr("GREATEST(favorite_count - ?, 0)", -delta)).Error
}

func (r *projectRepository) LockByIDForUpdate(id int64) error {
	return r.db.Clauses(clause.Locking{Strength: "UPDATE"}).Where("id = ?", id).First(&model.Project{}).Error
}

func (r *projectRepository) List(offset, limit int, conditions map[string]interface{}, sortBy, sortOrder string) ([]*model.Project, int64, error) {
	var projects []*model.Project
	var total int64

	query := r.db.Model(&model.Project{}).Preload("Owner").Preload("Provider")
	for k, v := range conditions {
		query = query.Where(k+" = ?", v)
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	orderClause := sortBy + " " + sortOrder
	if err := query.Order(orderClause).Offset(offset).Limit(limit).Find(&projects).Error; err != nil {
		return nil, 0, err
	}

	return projects, total, nil
}

func (r *projectRepository) ListByOwnerID(ownerID int64, offset, limit int) ([]*model.Project, int64, error) {
	return r.List(offset, limit, map[string]interface{}{"owner_id": ownerID}, "created_at", "desc")
}

func (r *projectRepository) ListByProviderID(providerID int64, offset, limit int) ([]*model.Project, int64, error) {
	return r.List(offset, limit, map[string]interface{}{"provider_id": providerID}, "created_at", "desc")
}

func (r *projectRepository) ListByProviderOrBidder(userID int64, offset, limit int) ([]*model.Project, int64, error) {
	var projects []*model.Project
	var total int64

	query := r.db.Model(&model.Project{}).Preload("Owner").Preload("Provider").
		Where("provider_id = ? OR id IN (SELECT project_id FROM bids WHERE bidder_id = ? AND status = 1)", userID, userID)

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	if err := query.Order("created_at desc").Offset(offset).Limit(limit).Find(&projects).Error; err != nil {
		return nil, 0, err
	}
	return projects, total, nil
}

func (r *projectRepository) ListMine(userID int64, offset, limit int, conditions map[string]interface{}, sortBy, sortOrder string) ([]*model.Project, int64, error) {
	var projects []*model.Project
	var total int64

	query := r.db.Model(&model.Project{}).Preload("Owner").Preload("Provider").
		Where(r.db.Where("owner_id = ?", userID).Or("provider_id = ?", userID))
	for k, v := range conditions {
		query = query.Where(k+" = ?", v)
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	orderClause := sortBy + " " + sortOrder
	if err := query.Order(orderClause).Offset(offset).Limit(limit).Find(&projects).Error; err != nil {
		return nil, 0, err
	}

	return projects, total, nil
}

func (r *projectRepository) ListMarket(offset, limit int, filter ProjectFilter) ([]*model.Project, int64, error) {
	var projects []*model.Project
	var total int64

	query := r.db.Model(&model.Project{}).Preload("Owner").Preload("Provider").Where("status = 2")

	if filter.Category != "" && filter.Category != "all" {
		query = query.Where("category = ?", filter.Category)
	}
	if filter.BudgetMin > 0 {
		query = query.Where("budget_max >= ?", filter.BudgetMin)
	}
	if filter.BudgetMax > 0 {
		query = query.Where("budget_min <= ?", filter.BudgetMax)
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	switch filter.Sort {
	case "budget_desc":
		query = query.Order("budget_max DESC")
	default:
		query = query.Order("published_at DESC")
	}

	if err := query.Offset(offset).Limit(limit).Find(&projects).Error; err != nil {
		return nil, 0, err
	}

	return projects, total, nil
}

func (r *projectRepository) CountByOwnerID(ownerID int64) (int64, error) {
	var count int64
	err := r.db.Model(&model.Project{}).Where("owner_id = ?", ownerID).Count(&count).Error
	return count, err
}

func (r *projectRepository) CountByCategory() (map[string]int64, error) {
	type Result struct {
		Category string
		Count    int64
	}
	var results []Result
	err := r.db.Model(&model.Project{}).
		Select("category, count(*) as count").
		Where("status = 2").
		Group("category").
		Scan(&results).Error
	if err != nil {
		return nil, err
	}
	m := make(map[string]int64)
	for _, r := range results {
		m[r.Category] = r.Count
	}
	return m, nil
}

// --- Bid Repository ---

type bidRepository struct {
	db *gorm.DB
}

func NewBidRepository(db *gorm.DB) BidRepository {
	return &bidRepository{db: db}
}

func (r *bidRepository) Create(bid *model.Bid) error {
	return r.db.Create(bid).Error
}

func (r *bidRepository) FindByID(id int64) (*model.Bid, error) {
	var bid model.Bid
	err := r.db.Preload("Bidder").Where("id = ?", id).First(&bid).Error
	if err != nil {
		return nil, err
	}
	return &bid, nil
}

func (r *bidRepository) FindByUUID(uuid string) (*model.Bid, error) {
	var bid model.Bid
	err := r.db.Preload("Bidder").Where("uuid = ?", uuid).First(&bid).Error
	if err != nil {
		return nil, err
	}
	return &bid, nil
}

func (r *bidRepository) Update(bid *model.Bid) error {
	return r.db.Save(bid).Error
}

func (r *bidRepository) UpdateFields(id int64, fields map[string]interface{}) error {
	return r.db.Model(&model.Bid{}).Where("id = ?", id).Updates(fields).Error
}

func (r *bidRepository) ListByProjectID(projectID int64, offset, limit int) ([]*model.Bid, int64, error) {
	var bids []*model.Bid
	var total int64
	query := r.db.Model(&model.Bid{}).Preload("Bidder").Preload("Team.Members.User").Where("project_id = ?", projectID)
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	if err := query.Order("created_at DESC").Offset(offset).Limit(limit).Find(&bids).Error; err != nil {
		return nil, 0, err
	}
	return bids, total, nil
}

func (r *bidRepository) FindPendingByProjectAndBidderID(projectID, bidderID int64) (*model.Bid, error) {
	var bid model.Bid
	err := r.db.Preload("Bidder").
		Where("project_id = ? AND bidder_id = ? AND status = ?", projectID, bidderID, 1).
		Order("created_at DESC").
		First(&bid).Error
	if err != nil {
		return nil, err
	}
	return &bid, nil
}

func (r *bidRepository) FindLatestByProjectAndBidderID(projectID, bidderID int64) (*model.Bid, error) {
	var bid model.Bid
	err := r.db.Where("project_id = ? AND bidder_id = ?", projectID, bidderID).
		Order("created_at DESC").
		First(&bid).Error
	if err != nil {
		return nil, err
	}
	return &bid, nil
}

// --- Task Repository ---

type taskRepository struct {
	db *gorm.DB
}

func NewTaskRepository(db *gorm.DB) TaskRepository {
	return &taskRepository{db: db}
}

func (r *taskRepository) Create(task *model.Task) error {
	return r.db.Create(task).Error
}

func (r *taskRepository) FindByID(id int64) (*model.Task, error) {
	var task model.Task
	err := r.db.Preload("Assignee").Where("id = ?", id).First(&task).Error
	if err != nil {
		return nil, err
	}
	return &task, nil
}

func (r *taskRepository) FindByUUID(uuid string) (*model.Task, error) {
	var task model.Task
	err := r.db.Preload("Assignee").Where("uuid = ?", uuid).First(&task).Error
	if err != nil {
		return nil, err
	}
	return &task, nil
}

func (r *taskRepository) Update(task *model.Task) error {
	return r.db.Save(task).Error
}

func (r *taskRepository) UpdateFields(id int64, fields map[string]interface{}) error {
	return r.db.Model(&model.Task{}).Where("id = ?", id).Updates(fields).Error
}

func (r *taskRepository) ListByProjectID(projectID int64, offset, limit int, conditions map[string]interface{}) ([]*model.Task, int64, error) {
	var tasks []*model.Task
	var total int64
	query := r.db.Model(&model.Task{}).Preload("Assignee").Where("project_id = ?", projectID)
	for k, v := range conditions {
		query = query.Where(k+" = ?", v)
	}
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	if err := query.Order("sort_order ASC").Offset(offset).Limit(limit).Find(&tasks).Error; err != nil {
		return nil, 0, err
	}
	return tasks, total, nil
}

// --- Milestone Repository ---

type milestoneRepository struct {
	db *gorm.DB
}

func NewMilestoneRepository(db *gorm.DB) MilestoneRepository {
	return &milestoneRepository{db: db}
}

func (r *milestoneRepository) Create(milestone *model.Milestone) error {
	return r.db.Create(milestone).Error
}

func (r *milestoneRepository) FindByID(id int64) (*model.Milestone, error) {
	var m model.Milestone
	err := r.db.Where("id = ?", id).First(&m).Error
	if err != nil {
		return nil, err
	}
	return &m, nil
}

func (r *milestoneRepository) FindByUUID(uuid string) (*model.Milestone, error) {
	var m model.Milestone
	err := r.db.Where("uuid = ?", uuid).First(&m).Error
	if err != nil {
		return nil, err
	}
	return &m, nil
}

func (r *milestoneRepository) Update(milestone *model.Milestone) error {
	return r.db.Save(milestone).Error
}

func (r *milestoneRepository) UpdateFields(id int64, fields map[string]interface{}) error {
	return r.db.Model(&model.Milestone{}).Where("id = ?", id).Updates(fields).Error
}

func (r *milestoneRepository) ListByProjectID(projectID int64) ([]*model.Milestone, error) {
	var milestones []*model.Milestone
	err := r.db.Where("project_id = ?", projectID).Order("sort_order ASC").Find(&milestones).Error
	return milestones, err
}

// --- Order Repository ---

type orderRepository struct {
	db *gorm.DB
}

func NewOrderRepository(db *gorm.DB) OrderRepository {
	return &orderRepository{db: db}
}

func (r *orderRepository) Create(order *model.Order) error {
	return r.db.Create(order).Error
}

func (r *orderRepository) FindByID(id int64) (*model.Order, error) {
	var order model.Order
	err := r.db.Where("id = ?", id).First(&order).Error
	if err != nil {
		return nil, err
	}
	return &order, nil
}

func (r *orderRepository) FindByProjectID(projectID int64) (*model.Order, error) {
	var order model.Order
	err := r.db.Where("project_id = ?", projectID).Order("created_at DESC").First(&order).Error
	if err != nil {
		return nil, err
	}
	return &order, nil
}

func (r *orderRepository) FindPendingByProjectID(projectID int64) (*model.Order, error) {
	var order model.Order
	err := r.db.Where("project_id = ? AND status = ?", projectID, 1).Order("id DESC").First(&order).Error
	if err != nil {
		return nil, err
	}
	return &order, nil
}

func (r *orderRepository) FindByUUID(uuid string) (*model.Order, error) {
	var order model.Order
	err := r.db.Where("uuid = ?", uuid).First(&order).Error
	if err != nil {
		return nil, err
	}
	return &order, nil
}

func (r *orderRepository) FindByOrderNo(orderNo string) (*model.Order, error) {
	var order model.Order
	err := r.db.Where("order_no = ?", orderNo).First(&order).Error
	if err != nil {
		return nil, err
	}
	return &order, nil
}

func (r *orderRepository) Update(order *model.Order) error {
	return r.db.Save(order).Error
}

func (r *orderRepository) SumPaidByPayerID(payerID int64) (float64, error) {
	var result struct{ Total *float64 }
	err := r.db.Model(&model.Order{}).
		Select("COALESCE(SUM(amount), 0) as total").
		Where("payer_id = ? AND status IN (2,3,4)", payerID).
		Scan(&result).Error
	if err != nil {
		return 0, err
	}
	if result.Total == nil {
		return 0, nil
	}
	return *result.Total, nil
}

// --- Wallet Repository ---

type walletRepository struct {
	db *gorm.DB
}

func NewWalletRepository(db *gorm.DB) WalletRepository {
	return &walletRepository{db: db}
}

func (r *walletRepository) FindByUserID(userID int64) (*model.Wallet, error) {
	var wallet model.Wallet
	err := r.db.Where("user_id = ?", userID).First(&wallet).Error
	if err != nil {
		return nil, err
	}
	return &wallet, nil
}

func (r *walletRepository) Create(wallet *model.Wallet) error {
	return r.db.Create(wallet).Error
}

func (r *walletRepository) Update(wallet *model.Wallet) error {
	return r.db.Save(wallet).Error
}

func (r *walletRepository) CreateTransaction(txn *model.WalletTransaction) error {
	return r.db.Create(txn).Error
}

func (r *walletRepository) ListTransactions(walletID int64, offset, limit int, conditions map[string]interface{}) ([]*model.WalletTransaction, int64, error) {
	var txns []*model.WalletTransaction
	var total int64
	query := r.db.Model(&model.WalletTransaction{}).Where("wallet_id = ?", walletID)
	for k, v := range conditions {
		query = query.Where(k+" = ?", v)
	}
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	if err := query.Order("created_at DESC").Offset(offset).Limit(limit).Find(&txns).Error; err != nil {
		return nil, 0, err
	}
	return txns, total, nil
}

// --- Conversation Repository ---

type conversationRepository struct {
	db *gorm.DB
}

func NewConversationRepository(db *gorm.DB) ConversationRepository {
	return &conversationRepository{db: db}
}

func (r *conversationRepository) Create(conv *model.Conversation) error {
	return r.db.Create(conv).Error
}

func (r *conversationRepository) Update(conv *model.Conversation) error {
	return r.db.Save(conv).Error
}

func (r *conversationRepository) FindByUUID(uuid string) (*model.Conversation, error) {
	var conv model.Conversation
	err := r.db.Where("uuid = ?", uuid).First(&conv).Error
	if err != nil {
		return nil, err
	}
	return &conv, nil
}

func (r *conversationRepository) FindActiveByUUID(uuid string) (*model.Conversation, error) {
	var conv model.Conversation
	err := r.db.Where("uuid = ? AND status = 1", uuid).First(&conv).Error
	if err != nil {
		return nil, err
	}
	return &conv, nil
}

func (r *conversationRepository) EnsurePrivateMembers(conv *model.Conversation) error {
	if conv == nil || conv.UserAID == nil || conv.UserBID == nil {
		return nil
	}
	for _, uid := range []int64{*conv.UserAID, *conv.UserBID} {
		var existing model.ConversationMember
		err := r.db.Where("conversation_id = ? AND user_id = ?", conv.ID, uid).First(&existing).Error
		if err == nil {
			continue
		}
		if !errors.Is(err, gorm.ErrRecordNotFound) {
			return err
		}
		cm := &model.ConversationMember{
			ConversationID: conv.ID,
			UserID:         uid,
			Role:           1,
		}
		if err := r.db.Create(cm).Error; err != nil {
			return err
		}
	}
	return nil
}

func (r *conversationRepository) FindMember(conversationID, userID int64) (*model.ConversationMember, error) {
	var m model.ConversationMember
	err := r.db.Where("conversation_id = ? AND user_id = ?", conversationID, userID).First(&m).Error
	if err != nil {
		return nil, err
	}
	return &m, nil
}

func (r *conversationRepository) UpdateMemberLastRead(conversationID, userID, lastReadMsgID int64) error {
	return r.db.Model(&model.ConversationMember{}).
		Where("conversation_id = ? AND user_id = ?", conversationID, userID).
		Update("last_read_msg_id", lastReadMsgID).Error
}

func (r *conversationRepository) ListByUserID(userID int64, offset, limit int) ([]*model.Conversation, int64, error) {
	var convs []*model.Conversation
	var total int64
	query := r.db.Model(&model.Conversation{}).
		Where("(user_a_id = ? OR user_b_id = ?) AND status = 1", userID, userID)
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	// MySQL 不支持 NULLS LAST，用 IS NULL 排序替代
	if err := query.Order("last_message_at IS NULL, last_message_at DESC").
		Offset(offset).Limit(limit).Find(&convs).Error; err != nil {
		return nil, 0, err
	}
	return convs, total, nil
}

func (r *conversationRepository) FindPrivateConversation(userAID, userBID int64) (*model.Conversation, error) {
	var conv model.Conversation
	minID, maxID := userAID, userBID
	if minID > maxID {
		minID, maxID = maxID, minID
	}
	err := r.db.Where("user_a_id = ? AND user_b_id = ? AND conversation_type = 1", minID, maxID).First(&conv).Error
	if err != nil {
		return nil, err
	}
	return &conv, nil
}

// --- Message Repository ---

type messageRepository struct {
	db *gorm.DB
}

func NewMessageRepository(db *gorm.DB) MessageRepository {
	return &messageRepository{db: db}
}

func (r *messageRepository) Create(msg *model.Message) error {
	return r.db.Create(msg).Error
}

func (r *messageRepository) ListByConversationID(conversationID int64, beforeID int64, limit int) ([]*model.Message, error) {
	var messages []*model.Message
	query := r.db.Preload("Sender").Where("conversation_id = ?", conversationID)
	if beforeID > 0 {
		query = query.Where("id < ?", beforeID)
	}
	err := query.Order("id DESC").Limit(limit).Find(&messages).Error
	return messages, err
}

func (r *messageRepository) CountUnreadFromOthersAfter(conversationID, viewerUserID, afterMsgID int64) (int64, error) {
	var n int64
	err := r.db.Model(&model.Message{}).
		Where("conversation_id = ? AND sender_id != ? AND id > ?", conversationID, viewerUserID, afterMsgID).
		Count(&n).Error
	return n, err
}

func (r *messageRepository) MaxIDByConversation(conversationID int64) (int64, error) {
	var maxID int64
	err := r.db.Model(&model.Message{}).
		Where("conversation_id = ?", conversationID).
		Select("COALESCE(MAX(id), 0)").
		Scan(&maxID).Error
	return maxID, err
}

// --- Review Repository ---

type reviewRepository struct {
	db *gorm.DB
}

func NewReviewRepository(db *gorm.DB) ReviewRepository {
	return &reviewRepository{db: db}
}

func (r *reviewRepository) Create(review *model.Review) error {
	return r.db.Create(review).Error
}

func (r *reviewRepository) FindByUUID(uuid string) (*model.Review, error) {
	var review model.Review
	err := r.db.Preload("Reviewer").Preload("Reviewee").Where("uuid = ?", uuid).First(&review).Error
	if err != nil {
		return nil, err
	}
	return &review, nil
}

func (r *reviewRepository) Update(review *model.Review) error {
	return r.db.Save(review).Error
}

func (r *reviewRepository) ListByRevieweeID(revieweeID int64, offset, limit int) ([]*model.Review, int64, error) {
	var reviews []*model.Review
	var total int64
	query := r.db.Model(&model.Review{}).Preload("Reviewer").Where("reviewee_id = ? AND status = 1", revieweeID)
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	if err := query.Order("created_at DESC").Offset(offset).Limit(limit).Find(&reviews).Error; err != nil {
		return nil, 0, err
	}
	return reviews, total, nil
}

func (r *reviewRepository) ListByProjectID(projectID int64, offset, limit int) ([]*model.Review, int64, error) {
	var reviews []*model.Review
	var total int64
	query := r.db.Model(&model.Review{}).Preload("Reviewer").Preload("Reviewee").Where("project_id = ? AND status = 1", projectID)
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	if err := query.Order("created_at DESC").Offset(offset).Limit(limit).Find(&reviews).Error; err != nil {
		return nil, 0, err
	}
	return reviews, total, nil
}

func (r *reviewRepository) FindByProjectAndReviewer(projectID, reviewerID int64) (*model.Review, error) {
	var review model.Review
	err := r.db.Where("project_id = ? AND reviewer_id = ?", projectID, reviewerID).First(&review).Error
	if err != nil {
		return nil, err
	}
	return &review, nil
}

// --- Team Repository ---

type teamRepository struct {
	db *gorm.DB
}

func NewTeamRepository(db *gorm.DB) TeamRepository {
	return &teamRepository{db: db}
}

func (r *teamRepository) Create(team *model.Team) error {
	return r.db.Create(team).Error
}

func (r *teamRepository) FindByUUID(uuid string) (*model.Team, error) {
	var team model.Team
	err := r.db.Preload("Leader").Preload("Members.User").Where("uuid = ?", uuid).First(&team).Error
	if err != nil {
		return nil, err
	}
	return &team, nil
}

func (r *teamRepository) FindPrimaryTeamForUser(userID int64) (*model.Team, error) {
	var asLeader model.Team
	err := r.db.Where("leader_id = ? AND status = 1", userID).Order("id DESC").First(&asLeader).Error
	if err == nil {
		return &asLeader, nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}
	var m model.TeamMember
	err = r.db.Where("user_id = ? AND status = 1", userID).Order("joined_at DESC").First(&m).Error
	if err != nil {
		return nil, err
	}
	var t model.Team
	err = r.db.Where("id = ? AND status = 1", m.TeamID).First(&t).Error
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (r *teamRepository) Update(team *model.Team) error {
	return r.db.Save(team).Error
}

func (r *teamRepository) UpdateFields(teamID int64, fields map[string]interface{}) error {
	return r.db.Model(&model.Team{}).Where("id = ?", teamID).Updates(fields).Error
}

func (r *teamRepository) ListActiveTeams(offset, limit int) ([]*model.Team, int64, error) {
	var teams []*model.Team
	var total int64
	query := r.db.Model(&model.Team{}).
		Where("teams.status = 1 AND teams.available_status = 1 AND teams.approval_status = ?", model.TeamApprovalApproved).
		Where(`EXISTS (
			SELECT 1 FROM users u
			WHERE u.id = teams.leader_id
			  AND u.role IN (2,3)
			  AND u.status = 1
			  AND u.onboarding_status = ?
		)`, model.OnboardingApproved)
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	if err := query.Preload("Leader").Preload("Members.User").
		Order("teams.vibe_power DESC, teams.avg_rating DESC").
		Offset(offset).Limit(limit).Find(&teams).Error; err != nil {
		return nil, 0, err
	}
	return teams, total, nil
}

func (r *teamRepository) CreateMember(member *model.TeamMember) error {
	return r.db.Create(member).Error
}

func (r *teamRepository) FindMember(teamID, userID int64) (*model.TeamMember, error) {
	var m model.TeamMember
	err := r.db.Where("team_id = ? AND user_id = ? AND status = 1", teamID, userID).First(&m).Error
	if err != nil {
		return nil, err
	}
	return &m, nil
}

func (r *teamRepository) UpdateMemberRatio(teamID, userID int64, ratio float64) error {
	return r.db.Model(&model.TeamMember{}).Where("team_id = ? AND user_id = ?", teamID, userID).Update("split_ratio", ratio).Error
}

func (r *teamRepository) ListMembers(teamID int64) ([]*model.TeamMember, error) {
	var members []*model.TeamMember
	err := r.db.Preload("User").Where("team_id = ? AND status = 1", teamID).Find(&members).Error
	return members, err
}

func (r *teamRepository) CreateInvite(invite *model.TeamInvite) error {
	return r.db.Create(invite).Error
}

func (r *teamRepository) FindInviteByUUID(uuid string) (*model.TeamInvite, error) {
	var invite model.TeamInvite
	err := r.db.Where("uuid = ?", uuid).First(&invite).Error
	if err != nil {
		return nil, err
	}
	return &invite, nil
}

func (r *teamRepository) UpdateInvite(invite *model.TeamInvite) error {
	return r.db.Save(invite).Error
}

func (r *teamRepository) CreatePost(post *model.TeamPost) error {
	return r.db.Create(post).Error
}

func (r *teamRepository) ListPosts(offset, limit int, conditions map[string]interface{}) ([]*model.TeamPost, int64, error) {
	var posts []*model.TeamPost
	var total int64
	query := r.db.Model(&model.TeamPost{}).Preload("Author")
	for k, v := range conditions {
		query = query.Where(k+" = ?", v)
	}
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	if err := query.Order("created_at DESC").Offset(offset).Limit(limit).Find(&posts).Error; err != nil {
		return nil, 0, err
	}
	return posts, total, nil
}

// --- Coupon Repository ---

type couponRepository struct {
	db *gorm.DB
}

func NewCouponRepository(db *gorm.DB) CouponRepository {
	return &couponRepository{db: db}
}

func (r *couponRepository) ListByUserID(userID int64) ([]*model.Coupon, error) {
	var coupons []*model.Coupon
	err := r.db.Where("user_id = ? AND status = 1 AND is_used = false", userID).Order("expire_date ASC").Find(&coupons).Error
	return coupons, err
}
