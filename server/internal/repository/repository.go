package repository

import (
	"github.com/vibebuild/server/internal/model"
	"gorm.io/gorm"
)

// InviteCodeRepository 团队邀请码
type InviteCodeRepository interface {
	Create(ic *model.InviteCode) error
	DisableActiveUnusedForTeam(teamID int64) error
	List(offset, limit int, teamID *int64) ([]*model.InviteCode, int64, error)
	FindActiveByTeamID(teamID int64) (*model.InviteCode, error)
	ConsumeTeamInviteAndRotate(plain string) (consumed *model.InviteCode, newRow *model.InviteCode, err error)
}

// TeamStaticAssetRepository 团队静态文件元数据
type TeamStaticAssetRepository interface {
	Create(a *model.TeamStaticAsset) error
	ListByTeamID(teamID int64, offset, limit int) ([]*model.TeamStaticAsset, int64, error)
}

// Repositories 所有 Repository 的集合
type Repositories struct {
	db *gorm.DB
	User         UserRepository
	Project      ProjectRepository
	Bid          BidRepository
	Task         TaskRepository
	Milestone    MilestoneRepository
	Order        OrderRepository
	Wallet       WalletRepository
	Conversation ConversationRepository
	Message      MessageRepository
	Review       ReviewRepository
	Team         TeamRepository
	Notification NotificationRepository
	Coupon       CouponRepository
	InviteCode       InviteCodeRepository
	TeamStaticAsset  TeamStaticAssetRepository
}

// DB 返回构造时使用的 *gorm.DB（用于开启事务等）
func (r *Repositories) DB() *gorm.DB {
	if r == nil {
		return nil
	}
	return r.db
}

// NewRepositories 创建所有 Repository
func NewRepositories(db *gorm.DB) *Repositories {
	return &Repositories{
		db:           db,
		User:         NewUserRepository(db),
		Project:      NewProjectRepository(db),
		Bid:          NewBidRepository(db),
		Task:         NewTaskRepository(db),
		Milestone:    NewMilestoneRepository(db),
		Order:        NewOrderRepository(db),
		Wallet:       NewWalletRepository(db),
		Conversation: NewConversationRepository(db),
		Message:      NewMessageRepository(db),
		Review:       NewReviewRepository(db),
		Team:         NewTeamRepository(db),
		Notification: NewNotificationRepository(db),
		Coupon:       NewCouponRepository(db),
		InviteCode:      NewInviteCodeRepository(db),
		TeamStaticAsset: NewTeamStaticAssetRepository(db),
	}
}

// UserRepository 用户数据访问接口
type UserRepository interface {
	Create(user *model.User) error
	FindByID(id int64) (*model.User, error)
	FindByUUID(uuid string) (*model.User, error)
	FindByPhoneHash(phoneHash string) (*model.User, error)
	FindByWechatOpenID(openID string) (*model.User, error)
	Update(user *model.User) error
	UpdateFields(id int64, fields map[string]interface{}) error
	ListExperts(offset, limit int) ([]*model.User, int64, error)
	CountPortfoliosByUserAndUUIDs(userID int64, uuids []string) (int64, error)
	ListUserSkills(userID int64) ([]*model.UserSkill, error)
	// ListUserSkillsForUsers 一次查询多名用户的技能关联，Preload Skill；按 user_id、主技能优先排序。
	ListUserSkillsForUsers(userIDs []int64) ([]*model.UserSkill, error)
	// FindSkillNamesByIDs 按技能 ID 批量取展示名（仅 status=1），用于预加载缺失时的兜底。
	FindSkillNamesByIDs(skillIDs []int64) (map[int64]string, error)
	ReplaceUserSkills(userID int64, skills []*model.UserSkill) error
	FindSkillByID(id int64) (*model.Skill, error)
	EnsureSkill(name, category string) (*model.Skill, error)
	ListUserPortfolios(userID int64) ([]*model.Portfolio, error)
}

// ProjectFilter 项目列表筛选条件
type ProjectFilter struct {
	Category  string
	Status    int
	OwnerID   int64
	BudgetMin float64
	BudgetMax float64
	Sort      string // latest / budget_desc / match
}

// ProjectRepository 项目数据访问接口
type ProjectRepository interface {
	Create(project *model.Project) error
	FindByID(id int64) (*model.Project, error)
	FindByUUID(uuid string) (*model.Project, error)
	Update(project *model.Project) error
	UpdateFields(id int64, fields map[string]interface{}) error
	// LockByIDForUpdate 对项目行加悲观锁，用于与订单创建等同事务内串行化
	LockByIDForUpdate(id int64) error
	List(offset, limit int, conditions map[string]interface{}, sortBy, sortOrder string) ([]*model.Project, int64, error)
	ListByOwnerID(ownerID int64, offset, limit int) ([]*model.Project, int64, error)
	ListByProviderID(providerID int64, offset, limit int) ([]*model.Project, int64, error)
	ListMarket(offset, limit int, filter ProjectFilter) ([]*model.Project, int64, error)
	CountByCategory() (map[string]int64, error)
	CountByOwnerID(ownerID int64) (int64, error)
}

// BidRepository 投标数据访问接口
type BidRepository interface {
	Create(bid *model.Bid) error
	FindByID(id int64) (*model.Bid, error)
	FindByUUID(uuid string) (*model.Bid, error)
	Update(bid *model.Bid) error
	UpdateFields(id int64, fields map[string]interface{}) error
	ListByProjectID(projectID int64, offset, limit int) ([]*model.Bid, int64, error)
}

// TaskRepository 任务数据访问接口
type TaskRepository interface {
	Create(task *model.Task) error
	FindByID(id int64) (*model.Task, error)
	FindByUUID(uuid string) (*model.Task, error)
	Update(task *model.Task) error
	UpdateFields(id int64, fields map[string]interface{}) error
	ListByProjectID(projectID int64, offset, limit int, conditions map[string]interface{}) ([]*model.Task, int64, error)
}

// MilestoneRepository 里程碑数据访问接口
type MilestoneRepository interface {
	Create(milestone *model.Milestone) error
	FindByID(id int64) (*model.Milestone, error)
	FindByUUID(uuid string) (*model.Milestone, error)
	Update(milestone *model.Milestone) error
	ListByProjectID(projectID int64) ([]*model.Milestone, error)
}

// OrderRepository 订单数据访问接口
type OrderRepository interface {
	Create(order *model.Order) error
	FindByID(id int64) (*model.Order, error)
	FindByUUID(uuid string) (*model.Order, error)
	FindByOrderNo(orderNo string) (*model.Order, error)
	Update(order *model.Order) error
	FindByProjectID(projectID int64) (*model.Order, error)
	// FindPendingByProjectID 待支付(status=1)订单，用于判重（非「最新一条任意状态」）
	FindPendingByProjectID(projectID int64) (*model.Order, error)
	SumPaidByPayerID(payerID int64) (float64, error)
}

// CouponRepository 优惠券数据访问接口
type CouponRepository interface {
	ListByUserID(userID int64) ([]*model.Coupon, error)
}

// WalletRepository 钱包数据访问接口
type WalletRepository interface {
	FindByUserID(userID int64) (*model.Wallet, error)
	Create(wallet *model.Wallet) error
	Update(wallet *model.Wallet) error
	CreateTransaction(txn *model.WalletTransaction) error
	ListTransactions(walletID int64, offset, limit int, conditions map[string]interface{}) ([]*model.WalletTransaction, int64, error)
}

// ConversationRepository 会话数据访问接口
type ConversationRepository interface {
	Create(conv *model.Conversation) error
	FindByUUID(uuid string) (*model.Conversation, error)
	Update(conv *model.Conversation) error
	ListByUserID(userID int64, offset, limit int) ([]*model.Conversation, int64, error)
	FindPrivateConversation(userAID, userBID int64) (*model.Conversation, error)
}

// MessageRepository 消息数据访问接口
type MessageRepository interface {
	Create(msg *model.Message) error
	ListByConversationID(conversationID int64, beforeID int64, limit int) ([]*model.Message, error)
}

// ReviewRepository 评价数据访问接口
type ReviewRepository interface {
	Create(review *model.Review) error
	FindByUUID(uuid string) (*model.Review, error)
	Update(review *model.Review) error
	ListByRevieweeID(revieweeID int64, offset, limit int) ([]*model.Review, int64, error)
	ListByProjectID(projectID int64, offset, limit int) ([]*model.Review, int64, error)
	FindByProjectAndReviewer(projectID, reviewerID int64) (*model.Review, error)
}

// TeamRepository 团队数据访问接口
type TeamRepository interface {
	Create(team *model.Team) error
	FindByUUID(uuid string) (*model.Team, error)
	Update(team *model.Team) error
	CreateMember(member *model.TeamMember) error
	FindMember(teamID, userID int64) (*model.TeamMember, error)
	UpdateMemberRatio(teamID, userID int64, ratio float64) error
	ListMembers(teamID int64) ([]*model.TeamMember, error)
	CreateInvite(invite *model.TeamInvite) error
	FindInviteByUUID(uuid string) (*model.TeamInvite, error)
	UpdateInvite(invite *model.TeamInvite) error
	CreatePost(post *model.TeamPost) error
	ListPosts(offset, limit int, conditions map[string]interface{}) ([]*model.TeamPost, int64, error)
}

// NotificationRepository 通知数据访问接口
type NotificationRepository interface {
	Create(notification *model.Notification) error
	FindByUUID(uuid string) (*model.Notification, error)
	Update(notification *model.Notification) error
	ListByUserID(userID int64, offset, limit int, conditions map[string]interface{}) ([]*model.Notification, int64, error)
	CountUnread(userID int64) (int64, error)
	MarkAllRead(userID int64) error
	MarkReadByUserAndUUID(userID int64, uuid string) error
}
