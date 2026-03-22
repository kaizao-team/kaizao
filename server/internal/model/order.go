package model

import (
	"time"

	"gorm.io/gorm"
)

// Order 订单模型
type Order struct {
	ID              int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID            string     `gorm:"type:uuid;not null;uniqueIndex;default:gen_random_uuid()" json:"uuid"`
	OrderNo         string     `gorm:"type:varchar(32);not null;uniqueIndex" json:"order_no"`
	ProjectID       int64      `gorm:"not null;index" json:"project_id"`
	MilestoneID     *int64     `gorm:"index" json:"milestone_id,omitempty"`
	PayerID         int64      `gorm:"not null;index" json:"payer_id"`
	PayeeID         *int64     `gorm:"index" json:"payee_id,omitempty"`
	PayeeTeamID     *int64     `gorm:"index" json:"payee_team_id,omitempty"`
	Amount          float64    `gorm:"type:decimal(10,2);not null" json:"amount"`
	PlatformFeeRate float64    `gorm:"type:decimal(5,4);not null;default:0.1200" json:"platform_fee_rate"`
	PlatformFee     float64    `gorm:"type:decimal(10,2);not null;default:0.00" json:"platform_fee"`
	ActualAmount    *float64   `gorm:"type:decimal(10,2)" json:"actual_amount,omitempty"`
	PaymentMethod   *string    `gorm:"type:varchar(20)" json:"payment_method,omitempty"`
	TradeNo         *string    `gorm:"type:varchar(64)" json:"trade_no,omitempty"`
	Status          int16      `gorm:"not null;default:1;index" json:"status"`
	RefundAmount    *float64   `gorm:"type:decimal(10,2)" json:"refund_amount,omitempty"`
	RefundReason    *string    `gorm:"type:varchar(200)" json:"refund_reason,omitempty"`
	RefundTradeNo   *string    `gorm:"type:varchar(64)" json:"refund_trade_no,omitempty"`
	PaidAt          *time.Time `json:"paid_at,omitempty"`
	EscrowAt        *time.Time `json:"escrow_at,omitempty"`
	ReleasedAt      *time.Time `json:"released_at,omitempty"`
	WithdrawnAt     *time.Time `json:"withdrawn_at,omitempty"`
	RefundedAt      *time.Time `json:"refunded_at,omitempty"`
	ExpireAt        *time.Time `json:"expire_at,omitempty"`
	AutoReleaseAt   *time.Time `json:"auto_release_at,omitempty"`
	CreatedAt       time.Time  `gorm:"not null;default:now()" json:"created_at"`
	UpdatedAt       time.Time  `gorm:"not null;default:now()" json:"updated_at"`
}

func (Order) TableName() string {
	return "orders"
}

func (o *Order) BeforeCreate(tx *gorm.DB) error {
	if o.UUID == "" {
		o.UUID = GenerateUUID()
	}
	return nil
}

// SplitRecord 分账记录模型
type SplitRecord struct {
	ID         int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID       string     `gorm:"type:uuid;not null;uniqueIndex;default:gen_random_uuid()" json:"uuid"`
	OrderID    int64      `gorm:"not null;index" json:"order_id"`
	TeamID     int64      `gorm:"not null;index" json:"team_id"`
	UserID     int64      `gorm:"not null;index" json:"user_id"`
	SplitRatio float64    `gorm:"type:decimal(5,2);not null" json:"split_ratio"`
	Amount     float64    `gorm:"type:decimal(10,2);not null" json:"amount"`
	Status     int16      `gorm:"not null;default:1;index" json:"status"`
	SplitAt    *time.Time `json:"split_at,omitempty"`
	CreatedAt  time.Time  `gorm:"not null;default:now()" json:"created_at"`
}

func (SplitRecord) TableName() string {
	return "split_records"
}

// Wallet 钱包模型
type Wallet struct {
	ID               int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	UserID           int64     `gorm:"not null;uniqueIndex" json:"user_id"`
	AvailableBalance float64   `gorm:"type:decimal(12,2);not null;default:0.00" json:"available_balance"`
	FrozenBalance    float64   `gorm:"type:decimal(12,2);not null;default:0.00" json:"frozen_balance"`
	TotalIncome      float64   `gorm:"type:decimal(12,2);not null;default:0.00" json:"total_income"`
	TotalWithdrawn   float64   `gorm:"type:decimal(12,2);not null;default:0.00" json:"total_withdrawn"`
	UpdatedAt        time.Time `gorm:"not null;default:now()" json:"updated_at"`
	CreatedAt        time.Time `gorm:"not null;default:now()" json:"created_at"`
}

func (Wallet) TableName() string {
	return "wallets"
}

// WalletTransaction 钱包交易流水模型
type WalletTransaction struct {
	ID              int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID            string    `gorm:"type:uuid;not null;uniqueIndex;default:gen_random_uuid()" json:"uuid"`
	WalletID        int64     `gorm:"not null;index" json:"wallet_id"`
	UserID          int64     `gorm:"not null;index" json:"user_id"`
	OrderID         *int64    `gorm:"index" json:"order_id,omitempty"`
	TransactionType int16     `gorm:"not null;index" json:"transaction_type"`
	Amount          float64   `gorm:"type:decimal(10,2);not null" json:"amount"`
	BalanceBefore   float64   `gorm:"type:decimal(12,2);not null" json:"balance_before"`
	BalanceAfter    float64   `gorm:"type:decimal(12,2);not null" json:"balance_after"`
	WithdrawMethod  *string   `gorm:"type:varchar(20)" json:"withdraw_method,omitempty"`
	WithdrawAccount *string   `gorm:"type:varchar(200)" json:"withdraw_account,omitempty"`
	WithdrawTradeNo *string   `gorm:"type:varchar(64)" json:"withdraw_trade_no,omitempty"`
	Remark          *string   `gorm:"type:varchar(200)" json:"remark,omitempty"`
	Status          int16     `gorm:"not null;default:1" json:"status"`
	CreatedAt       time.Time `gorm:"not null;default:now()" json:"created_at"`
}

func (WalletTransaction) TableName() string {
	return "wallet_transactions"
}
