package dto

// UpdateUserReq 更新用户信息请求
type UpdateUserReq struct {
	Nickname        *string  `json:"nickname" binding:"omitempty,min=2,max=20"`
	AvatarURL       *string  `json:"avatar_url" binding:"omitempty"`
	Gender          *int     `json:"gender" binding:"omitempty,oneof=0 1 2"`
	Bio             *string  `json:"bio" binding:"omitempty,max=500"`
	City            *string  `json:"city" binding:"omitempty"`
	ContactPhone    *string  `json:"contact_phone" binding:"omitempty,max=20"`
	Role            *int     `json:"role" binding:"omitempty,oneof=1 2 3"`
	HourlyRate      *float64 `json:"hourly_rate" binding:"omitempty,min=0"`
	AvailableStatus *int     `json:"available_status" binding:"omitempty,oneof=1 2 3"`
}

// CreateTeamReq 创建团队请求（当前登录用户为队长）
type CreateTeamReq struct {
	Name            *string  `json:"name" binding:"omitempty,max=100"`
	HourlyRate      *float64 `json:"hourly_rate" binding:"omitempty,min=0"`
	AvailableStatus *int     `json:"available_status" binding:"omitempty,oneof=1 2 3"`
	BudgetMin       *float64 `json:"budget_min" binding:"omitempty,min=0"`
	BudgetMax       *float64 `json:"budget_max" binding:"omitempty,min=0"`
	Description      *string  `json:"description" binding:"omitempty"`
	InviteCode       *string  `json:"invite_code" binding:"omitempty"`
	ServiceDirections []string `json:"service_directions" binding:"omitempty"`
}

// UpdateSkillsReq 更新技能列表请求
type UpdateSkillsReq struct {
	Skills []SkillItem `json:"skills" binding:"required,min=1,max=20"`
}

// SkillItem 技能项
type SkillItem struct {
	SkillID           int64 `json:"skill_id" binding:"required"`
	Proficiency       int   `json:"proficiency" binding:"omitempty,oneof=1 2 3 4"`
	YearsOfExperience int   `json:"years_of_experience" binding:"omitempty,min=0"`
	IsPrimary         bool  `json:"is_primary"`
}

// VerificationReq 实名认证请求
type VerificationReq struct {
	RealName string `json:"real_name" binding:"required"`
	IDCardNo string `json:"id_card_no" binding:"required,len=18"`
}

// CertificationReq 技能认证请求
type CertificationReq struct {
	SkillID           int64  `json:"skill_id" binding:"required"`
	CertificationType string `json:"certification_type" binding:"required,oneof=test portfolio_review"`
}

// CreatePortfolioReq 创建作品请求（category 省略时服务端默认为 other）
type CreatePortfolioReq struct {
	Title        string      `json:"title" binding:"required,max=200"`
	Description  string      `json:"description" binding:"omitempty"`
	Category     string      `json:"category" binding:"omitempty,oneof=app web miniprogram design data other"`
	CoverURL     string      `json:"cover_url" binding:"omitempty"`
	PreviewURL   string      `json:"preview_url" binding:"omitempty"`
	TechStack    []string    `json:"tech_stack" binding:"omitempty"`
	Images       []ImageItem `json:"images" binding:"omitempty"`
	DemoVideoURL string      `json:"demo_video_url" binding:"omitempty"`
}

// UpdatePortfolioReq 更新作品请求（仅非空字段写入；tech_stack/images 传 null 表示不更新）
type UpdatePortfolioReq struct {
	Title       *string `json:"title" binding:"omitempty,max=200"`
	Description *string `json:"description"`
	// 若传 category 则不可为空字符串，且须为 Handler 中枚举之一
	Category     *string      `json:"category" binding:"omitempty"`
	CoverURL     *string      `json:"cover_url"`
	PreviewURL   *string      `json:"preview_url"`
	TechStack    *[]string    `json:"tech_stack"`
	Images       *[]ImageItem `json:"images"`
	DemoVideoURL *string      `json:"demo_video_url"`
}

// ImageItem 图片项
type ImageItem struct {
	URL     string `json:"url"`
	Caption string `json:"caption"`
}

// SkillListQuery 技能标签查询
type SkillListQuery struct {
	Category string `form:"category" binding:"omitempty"`
	Keyword  string `form:"keyword" binding:"omitempty"`
	IsHot    *bool  `form:"is_hot" binding:"omitempty"`
}

// PaginationQuery 通用分页查询参数
type PaginationQuery struct {
	Page      int    `form:"page,default=1" binding:"min=1"`
	PageSize  int    `form:"page_size,default=20" binding:"min=1,max=100"`
	SortBy    string `form:"sort_by,default=created_at"`
	SortOrder string `form:"sort_order,default=desc" binding:"oneof=asc desc"`
}

// ListData 通用列表响应包装
type ListData struct {
	List interface{} `json:"list"`
}
