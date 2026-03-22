package repository

import (
	"github.com/vibebuild/server/internal/model"
	"gorm.io/gorm"
)

// Repositories 所有 Repository 的集合
type Repositories struct {
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
}

// NewRepositories 创建所有 Repository
func NewRepositories(db *gorm.DB) *Repositories {
	return &Repositories{
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
}

// ProjectRepository 项目数据访问接口
type ProjectRepository interface {
	Create(project *model.Project) error
	FindByID(id int64) (*model.Project, error)
	FindByUUID(uuid string) (*model.Project, error)
	Update(project *model.Project) error
	UpdateFields(id int64, fields map[string]interface{}) error
	List(offset, limit int, conditions map[string]interface{}, sortBy, sortOrder string) ([]*model.Project, int64, error)
	ListByOwnerID(ownerID int64, offset, limit int) ([]*model.Project, int64, error)
	ListByProviderID(providerID int64, offset, limit int) ([]*model.Project, int64, error)
}

// BidRepository 投标数据访问接口
type BidRepository interface {
	Create(bid *model.Bid) error
	FindByID(id int64) (*model.Bid, error)
	FindByUUID(uuid string) (*model.Bid, error)
	Update(bid *model.Bid) error
	ListByProjectID(projectID int64, offset, limit int) ([]*model.Bid, int64, error)
}

// TaskRepository 任务数据访问接口
type TaskRepository interface {
	Create(task *model.Task) error
	FindByUUID(uuid string) (*model.Task, error)
	Update(task *model.Task) error
	UpdateFields(id int64, fields map[string]interface{}) error
	ListByProjectID(projectID int64, offset, limit int, conditions map[string]interface{}) ([]*model.Task, int64, error)
}

// MilestoneRepository 里程碑数据访问接口
type MilestoneRepository interface {
	Create(milestone *model.Milestone) error
	FindByUUID(uuid string) (*model.Milestone, error)
	Update(milestone *model.Milestone) error
	ListByProjectID(projectID int64) ([]*model.Milestone, error)
}

// OrderRepository 订单数据访问接口
type OrderRepository interface {
	Create(order *model.Order) error
	FindByUUID(uuid string) (*model.Order, error)
	FindByOrderNo(orderNo string) (*model.Order, error)
	Update(order *model.Order) error
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
	FindByProjectAndReviewer(projectID, reviewerID int64) (*model.Review, error)
}

// TeamRepository 团队数据访问接口
type TeamRepository interface {
	Create(team *model.Team) error
	FindByUUID(uuid string) (*model.Team, error)
	Update(team *model.Team) error
	CreateMember(member *model.TeamMember) error
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
}
