package service

import (
	"errors"
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/repository"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

const defaultPlatformFeeRate = 0.12

func roundMoney2(v float64) float64 {
	return math.Round(v*100) / 100
}

type OrderService struct {
	repos *repository.Repositories
	log   *zap.Logger
}

func NewOrderService(repos *repository.Repositories, log *zap.Logger) *OrderService {
	return &OrderService{repos: repos, log: log}
}

// CreatePendingProjectOrder 创建待支付订单（platform_fee = amount * platform_fee_rate）；同项目已存在待支付订单则失败。
func (s *OrderService) CreatePendingProjectOrder(projectID, payerID, payeeID int64, amount float64) (*model.Order, error) {
	if amount <= 0 {
		return nil, fmt.Errorf("%d", errcode.ErrParamInvalid)
	}
	existing, err := s.repos.Order.FindByProjectID(projectID)
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}
	if err == nil && existing.Status == 1 {
		return nil, fmt.Errorf("%d", errcode.ErrOrderAlreadyExists)
	}
	orderNo := strings.ReplaceAll(model.GenerateUUID(), "-", "")
	if len(orderNo) > 32 {
		orderNo = orderNo[:32]
	}
	feeRate := defaultPlatformFeeRate
	platFee := roundMoney2(amount * feeRate)
	payee := payeeID
	ord := &model.Order{
		OrderNo:         orderNo,
		ProjectID:       projectID,
		PayerID:         payerID,
		PayeeID:         &payee,
		Amount:          amount,
		PlatformFeeRate: feeRate,
		PlatformFee:     platFee,
		Status:          1,
	}
	if err := s.repos.Order.Create(ord); err != nil {
		return nil, err
	}
	return ord, nil
}

// NotifyPayerPendingOrder 通知需求方支付（撮合自动建单或手动建单后可调用）
func (s *OrderService) NotifyPayerPendingOrder(payerID int64, ord *model.Order, projectTitle string) error {
	if ord == nil {
		return nil
	}
	tt := "order"
	oid := ord.ID
	total := roundMoney2(ord.Amount + ord.PlatformFee)
	content := fmt.Sprintf(
		"请支付项目款项。项目「%s」应付金额 %.2f 元（项目款 %.2f 元 + 平台服务费 %.2f 元）。",
		projectTitle, total, ord.Amount, ord.PlatformFee,
	)
	n := &model.Notification{
		UserID:           payerID,
		Title:            "请支付项目款项",
		Content:          content,
		NotificationType: model.NotificationTypePayReminder,
		TargetType:       &tt,
		TargetID:         &oid,
	}
	return s.repos.Notification.Create(n)
}

// CreateOrderByOwner 当前用户作为需求方为已撮合项目手动创建待支付订单（金额默认项目 agreed_price）
func (s *OrderService) CreateOrderByOwner(ownerUUID, projectUUID string, amount float64) (*model.Order, error) {
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
	if project.ProviderID == nil {
		return nil, fmt.Errorf("%d", errcode.ErrProjectStatusInvalid)
	}
	amt := amount
	if amt <= 0 {
		if project.AgreedPrice != nil && *project.AgreedPrice > 0 {
			amt = *project.AgreedPrice
		} else {
			return nil, fmt.Errorf("%d", errcode.ErrParamInvalid)
		}
	}
	ord, err := s.CreatePendingProjectOrder(project.ID, project.OwnerID, *project.ProviderID, amt)
	if err != nil {
		return nil, err
	}
	if err := s.NotifyPayerPendingOrder(project.OwnerID, ord, project.Title); err != nil {
		s.log.Error("CreateOrderByOwner: notify", zap.Error(err))
		return nil, err
	}
	return ord, nil
}

func (s *OrderService) GetByUUID(uuid string) (*model.Order, error) {
	order, err := s.repos.Order.FindByUUID(uuid)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrOrderNotFound)
	}
	return order, nil
}

type OrderDetail struct {
	ID             string                   `json:"id"`
	ProjectID      string                   `json:"project_id"`
	ProjectTitle   string                   `json:"project_title"`
	PayeeName      string                   `json:"payee_name"`
	ProjectAmount  float64                  `json:"project_amount"`
	PlatformFee    float64                  `json:"platform_fee"`
	Discount       float64                  `json:"discount"`
	TotalAmount    float64                  `json:"total_amount"`
	Milestones     []map[string]interface{} `json:"milestones"`
	GuaranteeText  string                   `json:"guarantee_text"`
	Status         string                   `json:"status"`
}

func (s *OrderService) GetDetail(orderUUID, viewerUUID string) (*OrderDetail, error) {
	viewer, err := s.repos.User.FindByUUID(viewerUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrUserNotFound)
	}
	order, err := s.repos.Order.FindByUUID(orderUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrOrderNotFound)
	}
	if order.PayerID != viewer.ID && (order.PayeeID == nil || *order.PayeeID != viewer.ID) {
		return nil, fmt.Errorf("%d", errcode.ErrOrderNotFound)
	}
	projectTitle := ""
	projectUUID := ""
	if p, err := s.repos.Project.FindByID(order.ProjectID); err == nil {
		projectTitle = p.Title
		projectUUID = p.UUID
	}
	payeeName := ""
	if order.PayeeID != nil {
		if u, err := s.repos.User.FindByID(*order.PayeeID); err == nil {
			payeeName = u.Nickname
		}
	}
	status := "pending"
	if order.Status == 2 {
		status = "paid"
	} else if order.Status == 3 {
		status = "completed"
	}
	milestones, _ := s.repos.Milestone.ListByProjectID(order.ProjectID)
	msList := make([]map[string]interface{}, 0, len(milestones))
	for _, ms := range milestones {
		msStatus := "pending"
		if ms.Status == 3 {
			msStatus = "paid"
		} else if ms.Status == 2 {
			msStatus = "current"
		}
		msList = append(msList, map[string]interface{}{
			"title":  ms.Title,
			"amount": ms.PaymentAmount,
			"status": msStatus,
		})
	}
	return &OrderDetail{
		ID:            order.UUID,
		ProjectID:     projectUUID,
		ProjectTitle:  projectTitle,
		PayeeName:     payeeName,
		ProjectAmount: order.Amount,
		PlatformFee:   order.PlatformFee,
		Discount:      0,
		TotalAmount:   order.Amount + order.PlatformFee,
		Milestones:    msList,
		GuaranteeText: "资金由平台托管，验收通过后释放给供给方",
		Status:        status,
	}, nil
}

func (s *OrderService) Prepay(uuid, paymentMethod string) (map[string]interface{}, error) {
	order, err := s.repos.Order.FindByUUID(uuid)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrOrderNotFound)
	}
	now := time.Now()
	order.PaymentMethod = &paymentMethod
	order.Status = 2
	order.PaidAt = &now
	if err := s.repos.Order.Update(order); err != nil {
		return nil, err
	}
	return map[string]interface{}{
		"payment_id":     model.GenerateUUID(),
		"payment_method": paymentMethod,
		"payment_url":    "https://pay.example.com/mock",
		"status":         "success",
	}, nil
}

func (s *OrderService) GetStatus(uuid string) (map[string]interface{}, error) {
	order, err := s.repos.Order.FindByUUID(uuid)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrOrderNotFound)
	}
	status := "pending"
	var paidAmount float64
	var paidAt *time.Time
	if order.Status >= 2 {
		status = "success"
		paidAmount = order.Amount
		paidAt = order.PaidAt
	}
	result := map[string]interface{}{
		"status":      status,
		"paid_amount": paidAmount,
	}
	if paidAt != nil {
		result["paid_at"] = paidAt
	}
	return result, nil
}

type WalletService struct {
	repos *repository.Repositories
	log   *zap.Logger
}

func NewWalletService(repos *repository.Repositories, log *zap.Logger) *WalletService {
	return &WalletService{repos: repos, log: log}
}

func (s *WalletService) GetBalance(userUUID string) (map[string]interface{}, error) {
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return nil, err
	}
	wallet, err := s.repos.Wallet.FindByUserID(user.ID)
	if err != nil {
		return map[string]interface{}{
			"available":       0.0,
			"frozen":          0.0,
			"total_earned":    0.0,
			"total_withdrawn": 0.0,
		}, nil
	}
	return map[string]interface{}{
		"available":       wallet.AvailableBalance,
		"frozen":          wallet.FrozenBalance,
		"total_earned":    wallet.TotalIncome,
		"total_withdrawn": wallet.TotalWithdrawn,
	}, nil
}

type TxnItem struct {
	ID        string    `json:"id"`
	Type      string    `json:"type"`
	Title     string    `json:"title"`
	Amount    float64   `json:"amount"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"created_at"`
}

func (s *WalletService) ListTransactions(userUUID string, page, pageSize int) ([]TxnItem, int64, error) {
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return nil, 0, err
	}
	wallet, err := s.repos.Wallet.FindByUserID(user.ID)
	if err != nil {
		return []TxnItem{}, 0, nil
	}
	offset := (page - 1) * pageSize
	txns, total, err := s.repos.Wallet.ListTransactions(wallet.ID, offset, pageSize, nil)
	if err != nil {
		return nil, 0, err
	}
	items := make([]TxnItem, 0, len(txns))
	for _, t := range txns {
		typ := "income"
		if t.TransactionType == 2 {
			typ = "withdraw"
		} else if t.TransactionType == 3 {
			typ = "fee"
		}
		status := "completed"
		if t.Status == 1 {
			status = "processing"
		}
		title := "交易"
		if t.Remark != nil {
			title = *t.Remark
		}
		items = append(items, TxnItem{
			ID:        t.UUID,
			Type:      typ,
			Title:     title,
			Amount:    t.Amount,
			Status:    status,
			CreatedAt: t.CreatedAt,
		})
	}
	return items, total, nil
}

func (s *WalletService) Withdraw(userUUID string, amount float64, method string) (map[string]interface{}, error) {
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return nil, err
	}
	wallet, err := s.repos.Wallet.FindByUserID(user.ID)
	if err != nil {
		wallet = &model.Wallet{UserID: user.ID}
		s.repos.Wallet.Create(wallet)
	}
	if wallet.AvailableBalance < amount {
		return nil, fmt.Errorf("%d", errcode.ErrWithdrawExceedBalance)
	}
	wallet.AvailableBalance -= amount
	wallet.TotalWithdrawn += amount
	s.repos.Wallet.Update(wallet)

	remark := "提现到" + method
	txn := &model.WalletTransaction{
		WalletID:        wallet.ID,
		UserID:          user.ID,
		TransactionType: 2,
		Amount:          amount,
		BalanceBefore:   wallet.AvailableBalance + amount,
		BalanceAfter:    wallet.AvailableBalance,
		WithdrawMethod:  &method,
		Remark:          &remark,
		Status:          1,
	}
	s.repos.Wallet.CreateTransaction(txn)

	return map[string]interface{}{
		"withdraw_id":       txn.UUID,
		"amount":            amount,
		"method":            method,
		"status":            "processing",
		"estimated_arrival": "T+1个工作日",
	}, nil
}

func (s *OrderService) ListCoupons(userUUID string) ([]map[string]interface{}, error) {
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return []map[string]interface{}{}, nil
	}
	coupons, err := s.repos.Coupon.ListByUserID(user.ID)
	if err != nil || len(coupons) == 0 {
		return []map[string]interface{}{}, nil
	}
	result := make([]map[string]interface{}, 0, len(coupons))
	for _, c := range coupons {
		isAvailable := c.ExpireDate.After(time.Now()) && !c.IsUsed
		result = append(result, map[string]interface{}{
			"id":               c.UUID,
			"title":            c.Title,
			"discount_amount":  c.DiscountAmount,
			"min_order_amount": c.MinOrderAmount,
			"expire_date":      c.ExpireDate.Format("2006-01-02"),
			"is_available":     isAvailable,
			"reason":           nil,
		})
	}
	return result, nil
}
