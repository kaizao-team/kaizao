package router

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"github.com/vibebuild/server/internal/config"
	"github.com/vibebuild/server/internal/handler"
	"github.com/vibebuild/server/internal/middleware"
	"github.com/vibebuild/server/internal/service"
	"go.uber.org/zap"
)

func placeholder(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":       0,
		"message":    "success",
		"data":       gin.H{"status": "endpoint ready"},
		"request_id": c.GetString("request_id"),
	})
}

func Setup(cfg *config.Config, handlers *handler.Handlers, services *service.Services, log *zap.Logger, rdb *redis.Client) *gin.Engine {
	gin.SetMode(cfg.Server.Mode)

	r := gin.New()
	maxMB := cfg.OSS.MaxUploadMB
	if maxMB <= 0 {
		maxMB = 32
	}
	r.MaxMultipartMemory = int64(maxMB) << 20

	if dir := strings.TrimSpace(cfg.OSS.LocalUploadDir); dir != "" {
		urlPath := strings.TrimSpace(cfg.OSS.LocalURLPath)
		if urlPath == "" {
			urlPath = "/api/v1/upload-files"
		}
		r.Static(urlPath, dir)
	}

	r.Use(middleware.Recovery(log))
	r.Use(middleware.RequestLogger(log))
	r.Use(middleware.CORS())
	r.Use(middleware.RateLimit(1000, 1000))

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	v1 := r.Group("/api/v1")

	// ==================== 认证模块 ====================
	auth := v1.Group("/auth")
	{
		auth.GET("/password-key", handlers.Auth.PasswordKey)
		auth.GET("/captcha", handlers.Auth.Captcha)
		auth.POST("/register-password", handlers.Auth.RegisterByPassword)
		auth.POST("/login-password", handlers.Auth.LoginByPassword)
		auth.POST("/sms-code", handlers.Auth.SendSMSCode)
		auth.POST("/login", handlers.Auth.Login)
		auth.POST("/register", handlers.Auth.Register)
		auth.POST("/wechat", handlers.Auth.WechatLogin)
		auth.POST("/refresh", handlers.Auth.RefreshToken)
		auth.POST("/logout", middleware.JWTAuth(services.JWT), handlers.Auth.Logout)
	}

	// ==================== 用户模块 ====================
	users := v1.Group("/users")
	{
		users.GET("/me", middleware.JWTAuth(services.JWT), handlers.User.GetMe)
		users.PUT("/me", middleware.JWTAuth(services.JWT), handlers.User.UpdateMe)
		users.POST("/me/onboarding/application", middleware.JWTAuth(services.JWT), handlers.User.SubmitOnboardingApplication)
		// v6.0 PROF 模块
		users.GET("/:id", middleware.OptionalJWTAuth(services.JWT), handlers.User.GetProfile)
		users.PUT("/:id", middleware.JWTAuth(services.JWT), handlers.User.UpdateProfile)
		users.GET("/:id/skills", middleware.OptionalJWTAuth(services.JWT), handlers.User.GetSkills)
		users.PUT("/me/skills", middleware.JWTAuth(services.JWT), handlers.User.UpdateSkills)
		users.PUT("/:id/skills", middleware.JWTAuth(services.JWT), handlers.User.UpdateSkills)
		users.GET("/me/portfolios", middleware.JWTAuth(services.JWT), handlers.User.GetMyPortfolios)
		users.GET("/:id/portfolios", middleware.OptionalJWTAuth(services.JWT), handlers.User.GetPortfolios)
		users.POST("/me/portfolios", middleware.JWTAuth(services.JWT), handlers.User.CreatePortfolio)
		users.PUT("/me/portfolios/:uuid", middleware.JWTAuth(services.JWT), handlers.User.UpdatePortfolio)
		users.DELETE("/me/portfolios/:uuid", middleware.JWTAuth(services.JWT), handlers.User.DeletePortfolio)
		users.POST("/me/verification", middleware.JWTAuth(services.JWT), placeholder)
		users.POST("/me/certifications", middleware.JWTAuth(services.JWT), placeholder)
		users.GET("/me/projects", middleware.JWTAuth(services.JWT), placeholder)
		users.GET("/me/recommended-projects", middleware.JWTAuth(services.JWT), placeholder)
		users.GET("/me/favorites", middleware.JWTAuth(services.JWT), handlers.User.ListMyFavorites)
		users.GET("/:id/reviews", placeholder)
		users.GET("/:id/credit", placeholder)
	}

	v1.GET("/skills", placeholder)
	v1.POST("/upload", middleware.JWTAuth(services.JWT), handlers.Upload.Post)

	// ==================== 首页模块 ====================
	home := v1.Group("/home", middleware.JWTAuth(services.JWT))
	{
		home.GET("/demander", handlers.Home.DemanderHome)
		home.GET("/expert", handlers.Home.ExpertHome)
	}

	// ==================== 需求广场模块 ====================
	market := v1.Group("/market")
	{
		market.GET("/projects", middleware.JWTAuth(services.JWT), handlers.Project.ListMarket)
		market.GET("/experts", middleware.OptionalJWTAuth(services.JWT), handlers.User.ListExperts)
	}

	// ==================== 项目模块 ====================
	projects := v1.Group("/projects")
	{
		projects.POST("", middleware.JWTAuth(services.JWT), handlers.Project.Create)
		projects.GET("", middleware.JWTAuth(services.JWT), handlers.Project.List)
		projects.GET("/search", placeholder)
		// Phase 3 需求发布
		projects.POST("/ai-chat", middleware.JWTAuth(services.JWT), handlers.PRD.AIChat)
		projects.POST("/generate-prd", middleware.JWTAuth(services.JWT), handlers.PRD.GeneratePRD)
		projects.POST("/draft", middleware.JWTAuth(services.JWT), handlers.PRD.SaveDraft)
		projects.POST("/:id/publish", middleware.JWTAuth(services.JWT), handlers.Project.Publish)
		projects.POST("/:id/confirm-alignment", middleware.JWTAuth(services.JWT), handlers.Project.ConfirmAlignment)
		projects.POST("/:id/start", middleware.JWTAuth(services.JWT), handlers.Project.Start)
		projects.GET("/:id", middleware.OptionalJWTAuth(services.JWT), handlers.Project.Get)
		projects.PUT("/:id", middleware.JWTAuth(services.JWT), handlers.Project.Update)
		projects.PUT("/:id/close", middleware.JWTAuth(services.JWT), handlers.Project.Close)
		projects.GET("/:id/overview", middleware.JWTAuth(services.JWT), placeholder)
		// Phase 4 项目管理
		projects.GET("/:id/tasks", middleware.JWTAuth(services.JWT), handlers.Task.ListTasks)
		projects.POST("/:id/tasks", middleware.JWTAuth(services.JWT), handlers.Task.CreateTask)
		projects.GET("/:id/milestones", middleware.JWTAuth(services.JWT), handlers.Task.ListMilestones)
		projects.POST("/:id/milestones", middleware.JWTAuth(services.JWT), handlers.Task.CreateMilestone)
		projects.GET("/:id/daily-reports", middleware.JWTAuth(services.JWT), handlers.Task.GetDailyReports)
		projects.GET("/:id/files", middleware.JWTAuth(services.JWT), handlers.Project.ListProjectFiles)
		projects.POST("/:id/files", middleware.JWTAuth(services.JWT), handlers.Project.UploadProjectFile)
		projects.GET("/:id/files/:fileUuid", middleware.JWTAuth(services.JWT), handlers.Project.GetProjectFile)
		// Phase 4 投标
		projects.POST("/:id/bids", middleware.JWTAuth(services.JWT), handlers.Bid.CreateBid)
		projects.GET("/:id/bids", middleware.JWTAuth(services.JWT), handlers.Bid.ListBids)
		projects.GET("/:id/ai-suggestion", middleware.JWTAuth(services.JWT), handlers.Bid.AISuggestion)
		projects.GET("/:id/recommendations", middleware.JWTAuth(services.JWT), handlers.Bid.Recommendations)
		projects.POST("/:id/quick-match", middleware.JWTAuth(services.JWT), handlers.Bid.QuickMatch)
		// v7.0 评价 (GET)
		projects.GET("/:id/reviews", middleware.OptionalJWTAuth(services.JWT), handlers.Review.ListByProject)
		projects.POST("/:id/deliver", middleware.JWTAuth(services.JWT), handlers.Task.DeliverProject)
		projects.POST("/:id/accept", middleware.JWTAuth(services.JWT), handlers.Task.AcceptProject)
		projects.POST("/:id/ai-assist", middleware.JWTAuth(services.JWT), placeholder)
		// Phase 3 PRD
		projects.GET("/:id/prd", middleware.JWTAuth(services.JWT), handlers.PRD.GetPRD)
		projects.PUT("/:id/prd/cards/:cardId", middleware.JWTAuth(services.JWT), handlers.PRD.UpdateCard)
	}

	// ==================== 任务卡片 ====================
	tasks := v1.Group("/tasks")
	{
		tasks.PUT("/:taskId/status", middleware.JWTAuth(services.JWT), handlers.Task.UpdateTaskStatus)
		tasks.PUT("/:taskId", middleware.JWTAuth(services.JWT), placeholder)
	}

	// ==================== 里程碑 ====================
	milestones := v1.Group("/milestones")
	{
		milestones.PUT("/:id", middleware.JWTAuth(services.JWT), placeholder)
		milestones.POST("/:id/deliver", middleware.JWTAuth(services.JWT), handlers.Task.DeliverMilestone)
		milestones.POST("/:id/complete", middleware.JWTAuth(services.JWT), handlers.Task.CompleteMilestone)
		// Phase 5 验收
		milestones.GET("/:id/acceptance", middleware.JWTAuth(services.JWT), handlers.Task.GetAcceptance)
		milestones.POST("/:id/accept", middleware.JWTAuth(services.JWT), handlers.Task.AcceptMilestone)
		milestones.POST("/:id/revision", middleware.JWTAuth(services.JWT), handlers.Task.RequestRevision)
	}

	// ==================== 投标模块 ====================
	bids := v1.Group("/bids")
	{
		bids.POST("/:bidId/accept", middleware.JWTAuth(services.JWT), handlers.Bid.AcceptBid)
		bids.POST("/:bidId/confirm", middleware.JWTAuth(services.JWT), handlers.Bid.ConfirmBid)
		bids.POST("/:bidId/reject", middleware.JWTAuth(services.JWT), handlers.Bid.RejectBid)
		bids.PUT("/:bidId/withdraw", middleware.JWTAuth(services.JWT), handlers.Bid.WithdrawBid)
	}

	// ==================== 收藏模块 ====================
	favorites := v1.Group("/favorites")
	{
		favorites.POST("", middleware.JWTAuth(services.JWT), handlers.User.AddFavorite)
		favorites.DELETE("", middleware.JWTAuth(services.JWT), handlers.User.RemoveFavorite)
	}

	// ==================== 沟通模块 ====================
	conversations := v1.Group("/conversations", middleware.JWTAuth(services.JWT))
	{
		conversations.POST("", placeholder)
		conversations.GET("", handlers.Conversation.List)
		conversations.GET("/:uuid/messages", handlers.Conversation.ListMessages)
		conversations.POST("/:uuid/messages", handlers.Conversation.SendMessage)
		conversations.POST("/:uuid/read", handlers.Conversation.MarkRead)
		conversations.DELETE("/:uuid", handlers.Conversation.Delete)
	}

	// ==================== 评价模块 ====================
	reviews := v1.Group("/reviews", middleware.JWTAuth(services.JWT))
	{
		reviews.POST("", handlers.Review.Create)
		reviews.POST("/:uuid/reply", placeholder)
	}

	// ==================== 支付模块 ====================
	orders := v1.Group("/orders")
	{
		orders.POST("", middleware.JWTAuth(services.JWT), handlers.Order.Create)
		orders.GET("/:id", middleware.JWTAuth(services.JWT), handlers.Order.GetDetail)
		orders.POST("/:id/prepay", middleware.JWTAuth(services.JWT), handlers.Order.Prepay)
		orders.GET("/:id/status", middleware.JWTAuth(services.JWT), handlers.Order.GetStatus)
		orders.POST("/callback/wechat", placeholder)
		orders.POST("/callback/alipay", placeholder)
		orders.POST("/:id/release", middleware.JWTAuth(services.JWT), placeholder)
		orders.POST("/:id/refund", middleware.JWTAuth(services.JWT), placeholder)
		orders.POST("/:id/split", middleware.JWTAuth(services.JWT), placeholder)
	}

	// 优惠券
	v1.GET("/coupons", middleware.JWTAuth(services.JWT), handlers.Order.GetCoupons)

	// 钱包
	wallet := v1.Group("/wallet", middleware.JWTAuth(services.JWT))
	{
		wallet.GET("/balance", handlers.Wallet.GetBalance)
		wallet.POST("/withdraw", handlers.Wallet.Withdraw)
		wallet.GET("/transactions", handlers.Wallet.ListTransactions)
	}

	// ==================== 收入 ====================
	v1.GET("/income/summary", middleware.JWTAuth(services.JWT), placeholder)

	// ==================== 通知模块 ====================
	notifications := v1.Group("/notifications", middleware.JWTAuth(services.JWT))
	{
		notifications.GET("", handlers.Notification.List)
		notifications.GET("/unread-count", handlers.Notification.UnreadCount)
		notifications.PUT("/read-all", handlers.Notification.MarkAllRead)
		notifications.PUT("/:uuid/read", handlers.Notification.MarkRead)
	}

	v1.POST("/devices", middleware.JWTAuth(services.JWT), placeholder)

	// ==================== 管理后台模块 ====================
	admin := v1.Group("/admin", middleware.JWTAuth(services.JWT), middleware.AdminAuth(services))
	{
		// 邀请码
		admin.POST("/invite-codes", handlers.Admin.CreateInviteCode)
		admin.GET("/invite-codes", handlers.Admin.ListInviteCodes)
		// 团队审核
		admin.PUT("/teams/:uuid/approval", handlers.Admin.ReviewTeamApproval)
		admin.PUT("/teams/:uuid", handlers.Admin.UpdateTeam)
		// 用户管理
		admin.PUT("/users/:uuid/onboarding", handlers.Admin.UpdateUserOnboarding)
		admin.GET("/users", handlers.Admin.ListUsers)
		admin.GET("/users/:uuid", handlers.Admin.GetUserDetail)
		admin.GET("/users/:uuid/skills", handlers.Admin.GetUserSkills)
		admin.GET("/users/:uuid/portfolios", handlers.Admin.GetUserPortfolios)
		admin.PUT("/users/:uuid/status", handlers.Admin.UpdateUserStatus)
		// 项目管理
		admin.GET("/projects", handlers.Admin.ListProjects)
		admin.PUT("/projects/:uuid/review", handlers.Admin.ReviewProject)
		admin.PUT("/projects/:uuid", handlers.Admin.UpdateProject)
		// Dashboard
		admin.GET("/dashboard", handlers.Admin.GetDashboard)
		// 举报
		admin.GET("/reports", handlers.Admin.ListReports)
		admin.PUT("/reports/:uuid", handlers.Admin.HandleReport)
		// 仲裁
		admin.GET("/arbitrations", handlers.Admin.ListArbitrations)
		admin.PUT("/arbitrations/:uuid", handlers.Admin.HandleArbitration)
		// 订单/财务
		admin.GET("/orders", handlers.Admin.ListOrders)
		admin.GET("/orders/:id", handlers.Admin.GetOrderDetail)
		admin.GET("/finance/summary", handlers.Admin.GetFinanceSummary)
		admin.GET("/withdrawals", handlers.Admin.ListWithdrawals)
		// 评价管理
		admin.GET("/reviews", handlers.Admin.ListReviews)
		admin.PUT("/reviews/:uuid/status", handlers.Admin.UpdateReviewStatus)
		// AI 模型配置
		admin.GET("/ai-models", handlers.Admin.GetAIModelConfig)
		admin.PUT("/ai-models", handlers.Admin.UpdateAIModelConfig)
		// AI 文档下载
		admin.GET("/projects/:uuid/ai-documents", handlers.Admin.ListAIDocuments)
		admin.GET("/projects/:uuid/ai-documents/:docId/download", handlers.Admin.DownloadAIDocument)
		admin.PUT("/projects/:uuid/prd/document", handlers.Admin.UploadProjectPRDDocument)
		admin.POST("/projects/:uuid/prd/reanalyze", handlers.Admin.ReanalyzePRD)
		admin.POST("/projects/:uuid/ears/decompose", handlers.Admin.DecomposePRD)
		admin.GET("/projects/:uuid/ears/tasks", handlers.Admin.GetEarsTasks)
		admin.GET("/projects/:uuid/tasks", handlers.Task.AdminListTasks)
		admin.GET("/projects/:uuid/milestones", handlers.Task.AdminListMilestones)
	}

	// ==================== AI服务模块 ====================
	ai := v1.Group("/ai", middleware.JWTAuth(services.JWT))
	{
		ai.POST("/requirement-analysis", placeholder)
		ai.POST("/generate-tasks", placeholder)
		ai.POST("/agent-sessions", placeholder)
	}

	// ==================== 团队模块 ====================
	teams := v1.Group("/teams")
	{
		teams.GET("", middleware.OptionalJWTAuth(services.JWT), handlers.Team.ListTeams)
		teams.POST("", middleware.JWTAuth(services.JWT), handlers.Team.CreateTeam)
		teams.GET("/:uuid", middleware.OptionalJWTAuth(services.JWT), handlers.Team.GetDetail)
		teams.POST("/:uuid/static-assets", middleware.JWTAuth(services.JWT), handlers.Team.UploadStaticAsset)
		teams.GET("/:uuid/static-assets", middleware.JWTAuth(services.JWT), handlers.Team.ListStaticAssets)
		teams.POST("/:uuid/invite", middleware.JWTAuth(services.JWT), handlers.Team.Invite)
		teams.PUT("/:uuid/split-ratio", middleware.JWTAuth(services.JWT), handlers.Team.UpdateSplitRatio)
		teams.GET("/ai-recommend", middleware.JWTAuth(services.JWT), placeholder)
	}

	// v7.0 组队邀请响应 (POST)
	v1.POST("/team-invites/:id", middleware.JWTAuth(services.JWT), handlers.Team.RespondInvite)

	teamPosts := v1.Group("/team-posts")
	{
		teamPosts.POST("", middleware.JWTAuth(services.JWT), handlers.Team.CreatePost)
		teamPosts.GET("", handlers.Team.ListTeams)
	}

	v1.POST("/reports", middleware.JWTAuth(services.JWT), placeholder)
	v1.POST("/arbitrations", middleware.JWTAuth(services.JWT), placeholder)

	return r
}
