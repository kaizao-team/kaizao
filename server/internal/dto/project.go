package dto

import "time"

// CreateProjectReq 创建项目请求
type CreateProjectReq struct {
	Title            string           `json:"title" binding:"required,min=5,max=200"`
	Description      string           `json:"description" binding:"required,min=20"`
	Category         string           `json:"category" binding:"required,oneof=data dev visual solution"`
	TemplateType     string           `json:"template_type" binding:"omitempty"`
	BudgetMin        *float64         `json:"budget_min" binding:"omitempty,min=0"`
	BudgetMax        *float64         `json:"budget_max" binding:"omitempty,min=0"`
	Deadline         *string          `json:"deadline" binding:"omitempty"`
	TechRequirements []string         `json:"tech_requirements" binding:"omitempty"`
	Attachments      []AttachmentItem `json:"attachments" binding:"omitempty,max=10"`
	MatchMode        int              `json:"match_mode" binding:"omitempty,oneof=1 2 3"`
	IsDraft          bool             `json:"is_draft"`
}

// AttachmentItem 附件项
type AttachmentItem struct {
	Name string `json:"name"`
	URL  string `json:"url"`
	Size int    `json:"size"`
	Type string `json:"type"`
}

// UpdateProjectReq 更新项目请求
type UpdateProjectReq struct {
	Title            *string  `json:"title" binding:"omitempty,min=5,max=200"`
	Description      *string  `json:"description" binding:"omitempty,min=20"`
	Category         *string  `json:"category" binding:"omitempty,oneof=data dev visual solution"`
	BudgetMin        *float64 `json:"budget_min" binding:"omitempty,min=0"`
	BudgetMax        *float64 `json:"budget_max" binding:"omitempty,min=0"`
	Deadline         *string  `json:"deadline" binding:"omitempty"`
	TechRequirements []string `json:"tech_requirements" binding:"omitempty"`
	MatchMode        *int     `json:"match_mode" binding:"omitempty,oneof=1 2 3"`
}

// CloseProjectReq 关闭项目请求
type CloseProjectReq struct {
	Reason string `json:"reason" binding:"omitempty,max=200"`
}

// ProjectListQuery 项目列表查询
type ProjectListQuery struct {
	PaginationQuery
	Category   string  `form:"category" binding:"omitempty"`
	Complexity string  `form:"complexity" binding:"omitempty,oneof=S M L XL"`
	BudgetMin  float64 `form:"budget_min" binding:"omitempty,min=0"`
	BudgetMax  float64 `form:"budget_max" binding:"omitempty,min=0"`
	Status     int     `form:"status" binding:"omitempty"`
	MatchMode  int     `form:"match_mode" binding:"omitempty"`
	Keyword    string  `form:"keyword" binding:"omitempty"`
}

// MarketProjectQuery 需求广场查询
type MarketProjectQuery struct {
	Page      int     `form:"page,default=1"`
	PageSize  int     `form:"page_size,default=10"`
	Category  string  `form:"category"`
	Sort      string  `form:"sort,default=latest"`
	BudgetMin float64 `form:"budget_min"`
	BudgetMax float64 `form:"budget_max"`
}

// ProjectSearchQuery 项目搜索查询
type ProjectSearchQuery struct {
	PaginationQuery
	Q          string  `form:"q" binding:"required"`
	Category   string  `form:"category" binding:"omitempty"`
	BudgetMin  float64 `form:"budget_min" binding:"omitempty,min=0"`
	BudgetMax  float64 `form:"budget_max" binding:"omitempty,min=0"`
	Complexity string  `form:"complexity" binding:"omitempty"`
}

// ProjectResp 项目响应
type ProjectResp struct {
	UUID             string                 `json:"uuid"`
	Title            string                 `json:"title"`
	Description      string                 `json:"description"`
	Category         string                 `json:"category"`
	Complexity       *string                `json:"complexity"`
	BudgetMin        *float64               `json:"budget_min"`
	BudgetMax        *float64               `json:"budget_max"`
	AgreedPrice      *float64               `json:"agreed_price"`
	Deadline         *time.Time             `json:"deadline"`
	TechRequirements []string               `json:"tech_requirements"`
	Attachments      []AttachmentItem       `json:"attachments"`
	Status           int16                  `json:"status"`
	StatusText       string                 `json:"status_text"`
	MatchMode        int16                  `json:"match_mode"`
	Progress         int16                  `json:"progress"`
	ViewCount        int                    `json:"view_count"`
	BidCount         int                    `json:"bid_count"`
	FavoriteCount    int                    `json:"favorite_count"`
	AiEstimate       map[string]interface{} `json:"ai_estimate,omitempty"`
	Owner            *UserBriefResp         `json:"owner,omitempty"`
	Provider         *UserBriefResp         `json:"provider,omitempty"`
	PublishedAt      *time.Time             `json:"published_at"`
	CreatedAt        time.Time              `json:"created_at"`
}
