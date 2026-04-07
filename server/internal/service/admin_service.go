package service

import (
	"fmt"
	"time"

	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/repository"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

// AdminService 管理后台独立服务（不耦合业务 Service）
type AdminService struct {
	repos *repository.Repositories
	log   *zap.Logger
}

func NewAdminService(repos *repository.Repositories, log *zap.Logger) *AdminService {
	return &AdminService{repos: repos, log: log}
}

func (s *AdminService) db() *gorm.DB { return s.repos.DB() }

// ──────────── 用户管理 ────────────

type AdminUserListOpts struct {
	Keyword          string
	Role             *int
	Status           *int
	OnboardingStatus *int
	StartDate        string
	EndDate          string
	Page, PageSize   int
}

func (s *AdminService) ListUsers(opts AdminUserListOpts) ([]model.User, int64, error) {
	q := s.db().Model(&model.User{})
	if opts.Keyword != "" {
		like := "%" + opts.Keyword + "%"
		q = q.Where("nickname LIKE ? OR uuid LIKE ?", like, like)
	}
	if opts.Role != nil {
		q = q.Where("role = ?", *opts.Role)
	}
	if opts.Status != nil {
		dbStatus := frontStatusToDB(*opts.Status)
		q = q.Where("status = ?", dbStatus)
	}
	if opts.OnboardingStatus != nil {
		q = q.Where("onboarding_status = ?", *opts.OnboardingStatus)
	}
	if opts.StartDate != "" {
		q = q.Where("created_at >= ?", opts.StartDate)
	}
	if opts.EndDate != "" {
		q = q.Where("created_at <= ?", opts.EndDate+" 23:59:59")
	}

	var total int64
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	var users []model.User
	off := (opts.Page - 1) * opts.PageSize
	if err := q.Order("created_at DESC").Offset(off).Limit(opts.PageSize).Find(&users).Error; err != nil {
		return nil, 0, err
	}
	return users, total, nil
}

func (s *AdminService) GetUserDetail(uuid string) (*model.User, error) {
	var u model.User
	if err := s.db().Where("uuid = ?", uuid).First(&u).Error; err != nil {
		return nil, err
	}
	return &u, nil
}

func (s *AdminService) UpdateUserStatus(uuid string, frontStatus int, reason *string) error {
	var u model.User
	if err := s.db().Where("uuid = ?", uuid).First(&u).Error; err != nil {
		return err
	}
	if u.Role == 9 {
		return fmt.Errorf("cannot_freeze_super_admin")
	}
	dbStatus := frontStatusToDB(frontStatus)
	fields := map[string]interface{}{
		"status": dbStatus,
	}
	if frontStatus == 0 && reason != nil {
		fields["freeze_reason"] = *reason
	}
	if frontStatus == 1 {
		fields["freeze_reason"] = nil
	}
	return s.db().Model(&model.User{}).Where("id = ?", u.ID).Updates(fields).Error
}

// frontStatusToDB 前端 status 0=冻结→DB 3, 1=正常→DB 1
func frontStatusToDB(front int) int {
	if front == 0 {
		return 3
	}
	return 1
}

// dbStatusToFront DB status → 前端 status
func dbStatusToFront(db int16) int {
	if db == 3 || db == 2 {
		return 0
	}
	return 1
}

// ──────────── 项目管理 ────────────

type AdminProjectListOpts struct {
	Keyword              string
	Status               *int
	Category             string
	BudgetMin, BudgetMax *float64
	StartDate, EndDate   string
	Page, PageSize       int
}

func (s *AdminService) ListProjects(opts AdminProjectListOpts) ([]model.Project, int64, error) {
	q := s.db().Model(&model.Project{}).Preload("Owner")
	if opts.Keyword != "" {
		like := "%" + opts.Keyword + "%"
		q = q.Where("title LIKE ? OR uuid LIKE ?", like, like)
	}
	if opts.Status != nil {
		q = q.Where("status = ?", *opts.Status)
	}
	if opts.Category != "" {
		q = q.Where("category = ?", opts.Category)
	}
	if opts.BudgetMin != nil {
		q = q.Where("budget_min >= ?", *opts.BudgetMin)
	}
	if opts.BudgetMax != nil {
		q = q.Where("budget_max <= ?", *opts.BudgetMax)
	}
	if opts.StartDate != "" {
		q = q.Where("created_at >= ?", opts.StartDate)
	}
	if opts.EndDate != "" {
		q = q.Where("created_at <= ?", opts.EndDate+" 23:59:59")
	}

	var total int64
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	var projects []model.Project
	off := (opts.Page - 1) * opts.PageSize
	if err := q.Order("created_at DESC").Offset(off).Limit(opts.PageSize).Find(&projects).Error; err != nil {
		return nil, 0, err
	}
	return projects, total, nil
}

func (s *AdminService) ReviewProject(uuid, action string, reason *string) error {
	var p model.Project
	if err := s.db().Where("uuid = ?", uuid).First(&p).Error; err != nil {
		return err
	}
	fields := map[string]interface{}{}
	now := time.Now()
	switch action {
	case "approve":
		fields["status"] = 2
		fields["published_at"] = now
	case "reject":
		fields["status"] = 6
		if reason != nil {
			fields["close_reason"] = *reason
		}
	case "close":
		fields["status"] = 6
		if reason != nil {
			fields["close_reason"] = *reason
		}
	default:
		return fmt.Errorf("invalid_action")
	}
	return s.db().Model(&model.Project{}).Where("id = ?", p.ID).Updates(fields).Error
}

// ──────────── Dashboard ────────────

type DashboardData struct {
	UserCount              int64
	UserToday              int64
	ProjectCount           int64
	ProjectWeek            int64
	ActiveTeamCount        int64
	OrderTotalAmount       float64
	OrderMonthAmount       float64
	PendingOnboardingCount int64
	PendingReportCount     int64
	UserTrend              []TrendPoint
	ProjectTrend           []TrendPoint
	OrderTrend             []TrendPoint
}

type TrendPoint struct {
	Date  string
	Count float64
}

func (s *AdminService) GetDashboard() (*DashboardData, error) {
	d := &DashboardData{}
	db := s.db()
	now := time.Now()
	today := now.Format("2006-01-02")
	weekStart := now.AddDate(0, 0, -int(now.Weekday())).Format("2006-01-02")
	monthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location()).Format("2006-01-02")

	db.Model(&model.User{}).Count(&d.UserCount)
	db.Model(&model.User{}).Where("created_at >= ?", today).Count(&d.UserToday)
	db.Model(&model.Project{}).Count(&d.ProjectCount)
	db.Model(&model.Project{}).Where("created_at >= ?", weekStart).Count(&d.ProjectWeek)
	db.Model(&model.Team{}).Where("status = 1").Count(&d.ActiveTeamCount)

	db.Model(&model.Order{}).Where("status IN (2,3,4)").Select("COALESCE(SUM(amount),0)").Scan(&d.OrderTotalAmount)
	db.Model(&model.Order{}).Where("status IN (2,3,4) AND created_at >= ?", monthStart).Select("COALESCE(SUM(amount),0)").Scan(&d.OrderMonthAmount)

	db.Model(&model.User{}).Where("onboarding_status = ?", model.OnboardingPending).Count(&d.PendingOnboardingCount)
	db.Model(&model.Report{}).Where("status = 1").Count(&d.PendingReportCount)

	// 近 30 天趋势
	d.UserTrend = s.dailyTrend("users", 30)
	d.ProjectTrend = s.dailyTrend("projects", 30)
	d.OrderTrend = s.dailyAmountTrend(30)

	return d, nil
}

func (s *AdminService) dailyTrend(table string, days int) []TrendPoint {
	start := time.Now().AddDate(0, 0, -days+1).Format("2006-01-02")
	var rows []struct {
		Date  string
		Count float64
	}
	s.db().Raw(fmt.Sprintf(
		"SELECT DATE(created_at) AS date, COUNT(*) AS count FROM %s WHERE created_at >= ? GROUP BY DATE(created_at) ORDER BY date", table),
		start).Scan(&rows)
	points := make([]TrendPoint, len(rows))
	for i, r := range rows {
		points[i] = TrendPoint{Date: r.Date, Count: r.Count}
	}
	return points
}

func (s *AdminService) dailyAmountTrend(days int) []TrendPoint {
	start := time.Now().AddDate(0, 0, -days+1).Format("2006-01-02")
	var rows []struct {
		Date  string
		Count float64
	}
	s.db().Raw(
		"SELECT DATE(created_at) AS date, COALESCE(SUM(amount),0) AS count FROM orders WHERE status IN (2,3,4) AND created_at >= ? GROUP BY DATE(created_at) ORDER BY date",
		start).Scan(&rows)
	points := make([]TrendPoint, len(rows))
	for i, r := range rows {
		points[i] = TrendPoint{Date: r.Date, Count: r.Count}
	}
	return points
}

// ──────────── 举报 ────────────

// AdminReportRow 举报列表查询结果，含 reporter 关联信息
type AdminReportRow struct {
	model.Report
	ReporterNickname string `json:"reporter_nickname" gorm:"column:reporter_nickname"`
}

func (s *AdminService) ListReports(page, pageSize int, status *int) ([]AdminReportRow, int64, error) {
	q := s.db().Table("reports").
		Select("reports.*, u.nickname AS reporter_nickname").
		Joins("LEFT JOIN users u ON u.id = reports.reporter_id")
	if status != nil {
		q = q.Where("reports.status = ?", *status)
	}
	var total int64
	q.Count(&total)
	var list []AdminReportRow
	off := (page - 1) * pageSize
	q.Order("reports.created_at DESC").Offset(off).Limit(pageSize).Scan(&list)
	return list, total, nil
}

func (s *AdminService) HandleReport(uuid string, handleResult string, action *string, adminID int64) error {
	var r model.Report
	if err := s.db().Where("uuid = ?", uuid).First(&r).Error; err != nil {
		return err
	}
	now := time.Now()
	fields := map[string]interface{}{
		"status":        2,
		"handler_id":    adminID,
		"handle_result": handleResult,
		"handled_at":    now,
	}
	if err := s.db().Model(&model.Report{}).Where("id = ?", r.ID).Updates(fields).Error; err != nil {
		return err
	}
	if action != nil && *action == "freeze_user" {
		s.db().Model(&model.User{}).Where("id = ?", r.TargetID).Updates(map[string]interface{}{
			"status":        3,
			"freeze_reason": "举报处理：" + handleResult,
		})
	}
	return nil
}

// ──────────── 仲裁 ────────────

// AdminArbitrationRow 仲裁列表查询结果，含关联信息
type AdminArbitrationRow struct {
	model.Arbitration
	ProjectTitle       string `json:"project_title" gorm:"column:project_title"`
	ApplicantNickname  string `json:"applicant_nickname" gorm:"column:applicant_nickname"`
	RespondentNickname string `json:"respondent_nickname" gorm:"column:respondent_nickname"`
}

func (s *AdminService) ListArbitrations(page, pageSize int, status *int) ([]AdminArbitrationRow, int64, error) {
	q := s.db().Table("arbitrations").
		Select("arbitrations.*, p.title AS project_title, ua.nickname AS applicant_nickname, ur.nickname AS respondent_nickname").
		Joins("LEFT JOIN projects p ON p.id = arbitrations.project_id").
		Joins("LEFT JOIN users ua ON ua.id = arbitrations.applicant_id").
		Joins("LEFT JOIN users ur ON ur.id = arbitrations.respondent_id")
	if status != nil {
		q = q.Where("arbitrations.status = ?", *status)
	}
	var total int64
	q.Count(&total)
	var list []AdminArbitrationRow
	off := (page - 1) * pageSize
	q.Order("arbitrations.created_at DESC").Offset(off).Limit(pageSize).Scan(&list)
	return list, total, nil
}

// verdictTypeMap 前端 verdict_type 字符串 → DB int16 映射
var verdictTypeMap = map[string]int16{
	"support_applicant":  1,
	"support_respondent": 2,
	"partial_refund":     3,
	"mediation":          4,
}

func (s *AdminService) HandleArbitration(uuid string, verdict string, verdictType *string, refundAmount *float64, adminID int64) error {
	var a model.Arbitration
	if err := s.db().Where("uuid = ?", uuid).First(&a).Error; err != nil {
		return err
	}
	now := time.Now()
	fields := map[string]interface{}{
		"status":        2,
		"arbiter_id":    adminID,
		"verdict":       verdict,
		"arbitrated_at": now,
	}
	if verdictType != nil {
		if v, ok := verdictTypeMap[*verdictType]; ok {
			fields["verdict_type"] = v
		}
	}
	if refundAmount != nil {
		fields["refund_amount"] = *refundAmount
	}
	return s.db().Model(&model.Arbitration{}).Where("id = ?", a.ID).Updates(fields).Error
}

// ──────────── 订单/财务 ────────────

type AdminOrderListOpts struct {
	OrderNo              string
	Status               *int
	PaymentMethod        string
	AmountMin, AmountMax *float64
	StartDate, EndDate   string
	Page, PageSize       int
}

// AdminOrderRow 订单列表查询结果，含关联信息
type AdminOrderRow struct {
	model.Order
	ProjectTitle  string  `json:"project_title" gorm:"column:project_title"`
	PayerNickname string  `json:"payer_nickname" gorm:"column:payer_nickname"`
	PayerUUID     string  `json:"payer_id" gorm:"column:payer_uuid"`
	PayeeNickname *string `json:"payee_nickname" gorm:"column:payee_nickname"`
}

func (s *AdminService) ListOrders(opts AdminOrderListOpts) ([]AdminOrderRow, int64, error) {
	q := s.db().Table("orders").
		Select("orders.*, p.title AS project_title, up.nickname AS payer_nickname, up.uuid AS payer_uuid, ue.nickname AS payee_nickname").
		Joins("LEFT JOIN projects p ON p.id = orders.project_id").
		Joins("LEFT JOIN users up ON up.id = orders.payer_id").
		Joins("LEFT JOIN users ue ON ue.id = orders.payee_id")
	if opts.OrderNo != "" {
		q = q.Where("orders.order_no LIKE ?", "%"+opts.OrderNo+"%")
	}
	if opts.Status != nil {
		q = q.Where("orders.status = ?", *opts.Status)
	}
	if opts.PaymentMethod != "" {
		q = q.Where("orders.payment_method = ?", opts.PaymentMethod)
	}
	if opts.AmountMin != nil {
		q = q.Where("orders.amount >= ?", *opts.AmountMin)
	}
	if opts.AmountMax != nil {
		q = q.Where("orders.amount <= ?", *opts.AmountMax)
	}
	if opts.StartDate != "" {
		q = q.Where("orders.created_at >= ?", opts.StartDate)
	}
	if opts.EndDate != "" {
		q = q.Where("orders.created_at <= ?", opts.EndDate+" 23:59:59")
	}
	var total int64
	q.Count(&total)
	var list []AdminOrderRow
	off := (opts.Page - 1) * opts.PageSize
	q.Order("orders.created_at DESC").Offset(off).Limit(opts.PageSize).Scan(&list)
	return list, total, nil
}

func (s *AdminService) GetOrderDetail(id int64) (*model.Order, error) {
	var o model.Order
	if err := s.db().Where("id = ?", id).First(&o).Error; err != nil {
		return nil, err
	}
	return &o, nil
}

type FinanceSummary struct {
	TotalGMV            float64
	MonthGMV            float64
	TotalPlatformFee    float64
	PendingEscrowAmount float64
	PendingRefundCount  int64
}

func (s *AdminService) GetFinanceSummary() (*FinanceSummary, error) {
	fs := &FinanceSummary{}
	db := s.db()
	monthStart := time.Date(time.Now().Year(), time.Now().Month(), 1, 0, 0, 0, 0, time.Now().Location()).Format("2006-01-02")

	// total_gmv: 所有已支付订单金额
	db.Model(&model.Order{}).Where("status IN (2,3,4)").Select("COALESCE(SUM(amount),0)").Scan(&fs.TotalGMV)
	// month_gmv: 本月已支付
	db.Model(&model.Order{}).Where("status IN (2,3,4) AND created_at >= ?", monthStart).Select("COALESCE(SUM(amount),0)").Scan(&fs.MonthGMV)
	// total_platform_fee
	db.Model(&model.Order{}).Where("status IN (2,3,4)").Select("COALESCE(SUM(platform_fee),0)").Scan(&fs.TotalPlatformFee)
	// pending_escrow_amount: 托管中 (status=3)
	db.Model(&model.Order{}).Where("status = 3").Select("COALESCE(SUM(amount),0)").Scan(&fs.PendingEscrowAmount)
	// pending_refund_count: 退款中订单数
	db.Model(&model.Order{}).Where("status = 5").Count(&fs.PendingRefundCount)

	return fs, nil
}

// AdminWithdrawalRow 提现列表查询结果，含用户信息
type AdminWithdrawalRow struct {
	model.WalletTransaction
	UserNickname string `json:"user_nickname" gorm:"column:user_nickname"`
	UserUUID     string `json:"user_id" gorm:"column:user_uuid"`
}

func (s *AdminService) ListWithdrawals(page, pageSize int, status *int) ([]AdminWithdrawalRow, int64, error) {
	q := s.db().Table("wallet_transactions").
		Select("wallet_transactions.*, u.nickname AS user_nickname, u.uuid AS user_uuid").
		Joins("LEFT JOIN users u ON u.id = wallet_transactions.user_id").
		Where("wallet_transactions.transaction_type = 2") // type=2 withdraw
	if status != nil {
		q = q.Where("wallet_transactions.status = ?", *status)
	}
	var total int64
	q.Count(&total)
	var list []AdminWithdrawalRow
	off := (page - 1) * pageSize
	q.Order("wallet_transactions.created_at DESC").Offset(off).Limit(pageSize).Scan(&list)
	return list, total, nil
}

// ──────────── 评价管理 ────────────

type AdminReviewListOpts struct {
	Status               *int
	RatingMin, RatingMax *float64
	IsAnonymous          *bool
	StartDate, EndDate   string
	Page, PageSize       int
}

func (s *AdminService) ListReviews(opts AdminReviewListOpts) ([]model.Review, int64, error) {
	q := s.db().Model(&model.Review{}).Preload("Reviewer").Preload("Reviewee")
	if opts.Status != nil {
		q = q.Where("status = ?", *opts.Status)
	}
	if opts.RatingMin != nil {
		q = q.Where("overall_rating >= ?", *opts.RatingMin)
	}
	if opts.RatingMax != nil {
		q = q.Where("overall_rating <= ?", *opts.RatingMax)
	}
	if opts.IsAnonymous != nil {
		q = q.Where("is_anonymous = ?", *opts.IsAnonymous)
	}
	if opts.StartDate != "" {
		q = q.Where("created_at >= ?", opts.StartDate)
	}
	if opts.EndDate != "" {
		q = q.Where("created_at <= ?", opts.EndDate+" 23:59:59")
	}
	var total int64
	q.Count(&total)
	var list []model.Review
	off := (opts.Page - 1) * opts.PageSize
	q.Order("created_at DESC").Offset(off).Limit(opts.PageSize).Find(&list)
	return list, total, nil
}

func (s *AdminService) UpdateReviewStatus(uuid string, status int) error {
	return s.db().Model(&model.Review{}).Where("uuid = ?", uuid).Update("status", status).Error
}

// DBStatusToFront 导出给 handler 层使用
func DBStatusToFront(db int16) int {
	return dbStatusToFront(db)
}
