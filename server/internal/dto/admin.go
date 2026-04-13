package dto

// ──────────── 用户管理 ────────────

type AdminListUsersQuery struct {
	Keyword          string `form:"keyword"`
	Role             *int   `form:"role"`
	Status           *int   `form:"status"`
	OnboardingStatus *int   `form:"onboarding_status"`
	StartDate        string `form:"start_date"`
	EndDate          string `form:"end_date"`
	Page             int    `form:"page,default=1"`
	PageSize         int    `form:"page_size,default=20"`
}

type AdminUpdateUserStatusReq struct {
	Status int     `json:"status" binding:"oneof=0 1"`
	Reason *string `json:"reason"`
}

// ──────────── 团队管理 ────────────

type AdminListTeamsQuery struct {
	Keyword        string `form:"keyword"`
	VibeLevel      string `form:"vibe_level"`
	ApprovalStatus *int   `form:"approval_status"`
	Page           int    `form:"page,default=1"`
	PageSize       int    `form:"page_size,default=20"`
}

// ──────────── 项目管理 ────────────

type AdminListProjectsQuery struct {
	Keyword   string   `form:"keyword"`
	Status    *int     `form:"status"`
	Category  string   `form:"category"`
	BudgetMin *float64 `form:"budget_min"`
	BudgetMax *float64 `form:"budget_max"`
	StartDate string   `form:"start_date"`
	EndDate   string   `form:"end_date"`
	Page      int      `form:"page,default=1"`
	PageSize  int      `form:"page_size,default=20"`
}

type AdminProjectReviewReq struct {
	Action string  `json:"action" binding:"required,oneof=approve reject close"`
	Reason *string `json:"reason"`
}

// ──────────── Dashboard ────────────

type AdminDashboardResp struct {
	UserCount              int64                   `json:"user_count"`
	UserToday              int64                   `json:"user_today"`
	ProjectCount           int64                   `json:"project_count"`
	ProjectWeek            int64                   `json:"project_week"`
	ActiveTeamCount        int64                   `json:"active_team_count"`
	OrderTotalAmount       float64                 `json:"order_total_amount"`
	OrderMonthAmount       float64                 `json:"order_month_amount"`
	PendingOnboardingCount int64                   `json:"pending_onboarding_count"`
	PendingReportCount     int64                   `json:"pending_report_count"`
	UserTrend              []AdminTrendPoint       `json:"user_trend"`
	ProjectTrend           []AdminTrendPoint       `json:"project_trend"`
	OrderTrend             []AdminOrderTrendPoint  `json:"order_trend"`
}

type AdminTrendPoint struct {
	Date  string  `json:"date"`
	Count float64 `json:"count"`
}

type AdminOrderTrendPoint struct {
	Date   string  `json:"date"`
	Amount float64 `json:"amount"`
}

// ──────────── 举报 ────────────

type AdminListReportsQuery struct {
	Status   *int `form:"status"`
	Page     int  `form:"page,default=1"`
	PageSize int  `form:"page_size,default=20"`
}

type AdminHandleReportReq struct {
	HandleResult string  `json:"handle_result" binding:"required"`
	Action       *string `json:"action"`
}

// ──────────── 仲裁 ────────────

type AdminListArbitrationsQuery struct {
	Status   *int `form:"status"`
	Page     int  `form:"page,default=1"`
	PageSize int  `form:"page_size,default=20"`
}

type AdminHandleArbitrationReq struct {
	Verdict      string   `json:"verdict" binding:"required"`
	VerdictType  *string  `json:"verdict_type"`
	RefundAmount *float64 `json:"refund_amount"`
}

// ──────────── 订单/财务 ────────────

type AdminListOrdersQuery struct {
	OrderNo       string   `form:"order_no"`
	Status        *int     `form:"status"`
	PaymentMethod string   `form:"payment_method"`
	AmountMin     *float64 `form:"amount_min"`
	AmountMax     *float64 `form:"amount_max"`
	StartDate     string   `form:"start_date"`
	EndDate       string   `form:"end_date"`
	Page          int      `form:"page,default=1"`
	PageSize      int      `form:"page_size,default=20"`
}

type AdminFinanceSummaryResp struct {
	TotalGMV            float64 `json:"total_gmv"`
	MonthGMV            float64 `json:"month_gmv"`
	TotalPlatformFee    float64 `json:"total_platform_fee"`
	PendingEscrowAmount float64 `json:"pending_escrow_amount"`
	PendingRefundCount  int64   `json:"pending_refund_count"`
}

type AdminListWithdrawalsQuery struct {
	Status   *int `form:"status"`
	Page     int  `form:"page,default=1"`
	PageSize int  `form:"page_size,default=20"`
}

// ──────────── 评价管理 ────────────

type AdminListReviewsQuery struct {
	Status      *int     `form:"status"`
	RatingMin   *float64 `form:"rating_min"`
	RatingMax   *float64 `form:"rating_max"`
	IsAnonymous *bool    `form:"is_anonymous"`
	StartDate   string   `form:"start_date"`
	EndDate     string   `form:"end_date"`
	Page        int      `form:"page,default=1"`
	PageSize    int      `form:"page_size,default=20"`
}

type AdminUpdateReviewStatusReq struct {
	Status int `json:"status" binding:"required,oneof=1 2"`
}
