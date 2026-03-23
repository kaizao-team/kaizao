package router

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"github.com/vibebuild/server/internal/config"
	"github.com/vibebuild/server/internal/handler"
	"github.com/vibebuild/server/internal/middleware"
	"github.com/vibebuild/server/internal/service"
	"go.uber.org/zap"
)

// placeholder 为尚未实现完整逻辑的端点提供统一占位响应
func placeholder(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":       0,
		"message":    "success",
		"data":       gin.H{"status": "endpoint ready"},
		"request_id": c.GetString("request_id"),
	})
}

// Setup 初始化路由
func Setup(cfg *config.Config, handlers *handler.Handlers, services *service.Services, log *zap.Logger, rdb *redis.Client) *gin.Engine {
	gin.SetMode(cfg.Server.Mode)

	r := gin.New()

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
		users.GET("/:uuid/profile", middleware.OptionalJWTAuth(services.JWT), placeholder)
		users.PUT("/me/skills", middleware.JWTAuth(services.JWT), placeholder)
		users.POST("/me/portfolios", middleware.JWTAuth(services.JWT), placeholder)
		users.GET("/:uuid/portfolios", placeholder)
		users.PUT("/me/portfolios/:uuid", middleware.JWTAuth(services.JWT), placeholder)
		users.DELETE("/me/portfolios/:uuid", middleware.JWTAuth(services.JWT), placeholder)
		users.POST("/me/verification", middleware.JWTAuth(services.JWT), placeholder)
		users.POST("/me/certifications", middleware.JWTAuth(services.JWT), placeholder)
		users.GET("/me/projects", middleware.JWTAuth(services.JWT), placeholder)
		users.GET("/me/recommended-projects", middleware.JWTAuth(services.JWT), placeholder)
		users.GET("/me/favorites", middleware.JWTAuth(services.JWT), placeholder)
		users.GET("/:uuid/reviews", placeholder)
		users.GET("/:uuid/credit", placeholder)
	}

	// 技能标签字典
	v1.GET("/skills", placeholder)

	// 文件上传
	v1.POST("/upload", middleware.JWTAuth(services.JWT), placeholder)

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
	}

	// ==================== 项目模块 ====================
	projects := v1.Group("/projects")
	{
		projects.POST("", middleware.JWTAuth(services.JWT), handlers.Project.Create)
		projects.GET("", middleware.OptionalJWTAuth(services.JWT), handlers.Project.List)
		projects.GET("/search", placeholder)
		projects.POST("/ai-chat", middleware.JWTAuth(services.JWT), placeholder)
		projects.POST("/generate-prd", middleware.JWTAuth(services.JWT), placeholder)
		projects.POST("/draft", middleware.JWTAuth(services.JWT), placeholder)
		projects.GET("/:id", middleware.OptionalJWTAuth(services.JWT), handlers.Project.Get)
		projects.PUT("/:id", middleware.JWTAuth(services.JWT), handlers.Project.Update)
		projects.PUT("/:id/close", middleware.JWTAuth(services.JWT), handlers.Project.Close)
		projects.GET("/:id/overview", middleware.JWTAuth(services.JWT), placeholder)
		projects.GET("/:id/tasks", middleware.JWTAuth(services.JWT), placeholder)
		projects.POST("/:id/tasks", middleware.JWTAuth(services.JWT), placeholder)
		projects.GET("/:id/milestones", middleware.JWTAuth(services.JWT), placeholder)
		projects.POST("/:id/milestones", middleware.JWTAuth(services.JWT), placeholder)
		projects.GET("/:id/daily-reports", middleware.JWTAuth(services.JWT), placeholder)
		projects.POST("/:id/bids", middleware.JWTAuth(services.JWT), placeholder)
		projects.GET("/:id/bids", middleware.JWTAuth(services.JWT), placeholder)
		projects.GET("/:id/ai-suggestion", middleware.JWTAuth(services.JWT), placeholder)
		projects.GET("/:id/recommendations", middleware.JWTAuth(services.JWT), placeholder)
		projects.POST("/:id/quick-match", middleware.JWTAuth(services.JWT), placeholder)
		projects.POST("/:id/reviews", middleware.JWTAuth(services.JWT), placeholder)
		projects.POST("/:id/ai-assist", middleware.JWTAuth(services.JWT), placeholder)
		projects.GET("/:id/prd", middleware.JWTAuth(services.JWT), placeholder)
		projects.PUT("/:id/prd/cards/:cardId", middleware.JWTAuth(services.JWT), placeholder)
	}

	// ==================== 任务卡片 ====================
	tasks := v1.Group("/tasks")
	{
		tasks.PUT("/:taskId/status", middleware.JWTAuth(services.JWT), placeholder)
		tasks.PUT("/:taskId", middleware.JWTAuth(services.JWT), placeholder)
	}

	// ==================== 里程碑 ====================
	milestones := v1.Group("/milestones")
	{
		milestones.PUT("/:uuid", middleware.JWTAuth(services.JWT), placeholder)
		milestones.POST("/:uuid/deliver", middleware.JWTAuth(services.JWT), placeholder)
		milestones.PUT("/:uuid/accept", middleware.JWTAuth(services.JWT), placeholder)
	}

	// ==================== 投标模块 ====================
	bids := v1.Group("/bids")
	{
		bids.POST("/:bidId/accept", middleware.JWTAuth(services.JWT), placeholder)
		bids.PUT("/:bidId/withdraw", middleware.JWTAuth(services.JWT), placeholder)
	}

	// ==================== 收藏模块 ====================
	favorites := v1.Group("/favorites")
	{
		favorites.POST("", middleware.JWTAuth(services.JWT), placeholder)
		favorites.DELETE("", middleware.JWTAuth(services.JWT), placeholder)
	}

	// ==================== 沟通模块 ====================
	conversations := v1.Group("/conversations")
	{
		conversations.POST("", middleware.JWTAuth(services.JWT), placeholder)
		conversations.GET("", middleware.JWTAuth(services.JWT), placeholder)
		conversations.GET("/:uuid/messages", middleware.JWTAuth(services.JWT), placeholder)
		conversations.POST("/:uuid/messages", middleware.JWTAuth(services.JWT), placeholder)
		conversations.PUT("/:uuid/read", middleware.JWTAuth(services.JWT), placeholder)
	}

	// ==================== 评价模块 ====================
	reviews := v1.Group("/reviews")
	{
		reviews.POST("/:uuid/reply", middleware.JWTAuth(services.JWT), placeholder)
	}

	// ==================== 支付模块 ====================
	orders := v1.Group("/orders")
	{
		orders.POST("", middleware.JWTAuth(services.JWT), placeholder)
		orders.POST("/callback/wechat", placeholder)
		orders.POST("/callback/alipay", placeholder)
		orders.POST("/:uuid/release", middleware.JWTAuth(services.JWT), placeholder)
		orders.POST("/:uuid/refund", middleware.JWTAuth(services.JWT), placeholder)
		orders.POST("/:uuid/split", middleware.JWTAuth(services.JWT), placeholder)
	}

	// 钱包
	wallet := v1.Group("/wallet", middleware.JWTAuth(services.JWT))
	{
		wallet.GET("/balance", placeholder)
		wallet.POST("/withdraw", placeholder)
		wallet.GET("/transactions", placeholder)
	}

	// ==================== 收入 ====================
	v1.GET("/income/summary", middleware.JWTAuth(services.JWT), placeholder)

	// ==================== 通知模块 ====================
	notifications := v1.Group("/notifications", middleware.JWTAuth(services.JWT))
	{
		notifications.GET("", placeholder)
		notifications.PUT("/:uuid/read", placeholder)
		notifications.PUT("/read-all", placeholder)
		notifications.GET("/unread-count", placeholder)
	}

	// 设备注册
	v1.POST("/devices", middleware.JWTAuth(services.JWT), placeholder)

	// ==================== 管理后台模块 ====================
	admin := v1.Group("/admin", middleware.JWTAuth(services.JWT), middleware.AdminAuth())
	{
		admin.GET("/users", placeholder)
		admin.PUT("/users/:uuid/status", placeholder)
		admin.GET("/reports", placeholder)
		admin.PUT("/reports/:uuid", placeholder)
		admin.GET("/arbitrations", placeholder)
		admin.PUT("/arbitrations/:uuid", placeholder)
		admin.GET("/projects", placeholder)
		admin.PUT("/projects/:uuid/review", placeholder)
		admin.GET("/dashboard", placeholder)
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
		teams.POST("", middleware.JWTAuth(services.JWT), placeholder)
		teams.GET("/:uuid", placeholder)
		teams.POST("/:uuid/invite", middleware.JWTAuth(services.JWT), placeholder)
		teams.PUT("/:uuid/split-ratio", middleware.JWTAuth(services.JWT), placeholder)
		teams.GET("/ai-recommend", middleware.JWTAuth(services.JWT), placeholder)
	}

	v1.PUT("/team-invites/:uuid", middleware.JWTAuth(services.JWT), placeholder)

	teamPosts := v1.Group("/team-posts")
	{
		teamPosts.POST("", middleware.JWTAuth(services.JWT), placeholder)
		teamPosts.GET("", placeholder)
	}

	// ==================== 举报/仲裁 ====================
	v1.POST("/reports", middleware.JWTAuth(services.JWT), placeholder)
	v1.POST("/arbitrations", middleware.JWTAuth(services.JWT), placeholder)

	return r
}
