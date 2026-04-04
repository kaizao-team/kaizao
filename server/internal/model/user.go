package model

import (
	"time"

	"gorm.io/gorm"
)

// User 用户模型
type User struct {
	ID              int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID            string     `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	Username        *string    `gorm:"type:varchar(50);uniqueIndex" json:"-"`
	Phone           *string    `gorm:"type:varchar(20);uniqueIndex" json:"-"`
	PhoneHash       *string    `gorm:"type:varchar(64);index" json:"-"`
	PasswordHash    *string    `gorm:"type:varchar(255)" json:"-"`
	WechatOpenID    *string    `gorm:"column:wechat_openid;type:varchar(128);uniqueIndex" json:"-"`
	WechatUnionID   *string    `gorm:"column:wechat_unionid;type:varchar(128)" json:"-"`
	Nickname        string     `gorm:"type:varchar(50);not null" json:"nickname"`
	AvatarURL       *string    `gorm:"type:varchar(512)" json:"avatar_url"`
	Role            int16      `gorm:"not null;default:0;index" json:"role"`
	Gender          int16      `gorm:"default:0" json:"gender"`
	Bio             *string    `gorm:"type:text" json:"bio"`
	City            *string    `gorm:"type:varchar(50)" json:"city"`
	ContactPhone    *string    `gorm:"column:contact_phone;type:varchar(20)" json:"contact_phone"`
	RealName        *string    `gorm:"type:varchar(50)" json:"-"`
	IDCardNo        *string    `gorm:"type:varchar(255)" json:"-"`
	IsVerified      bool       `gorm:"not null;default:false" json:"is_verified"`
	VerifiedAt      *time.Time `json:"verified_at,omitempty"`
	HourlyRate      *float64   `gorm:"type:decimal(10,2)" json:"hourly_rate"`
	AvailableStatus int16      `gorm:"default:1" json:"available_status"`
	ResponseTimeAvg int        `gorm:"default:0" json:"response_time_avg"`
	CreditScore     int        `gorm:"not null;default:500" json:"credit_score"`
	Level           int16      `gorm:"not null;default:1" json:"level"`
	TotalOrders     int        `gorm:"not null;default:0" json:"total_orders"`
	CompletedOrders int        `gorm:"not null;default:0" json:"completed_orders"`
	CompletionRate  float64    `gorm:"type:decimal(5,2);not null;default:0.00" json:"completion_rate"`
	AvgRating       float64    `gorm:"type:decimal(3,2);not null;default:0.00" json:"avg_rating"`
	TotalEarnings   float64    `gorm:"type:decimal(12,2);not null;default:0.00" json:"total_earnings"`
	Status               int16      `gorm:"not null;default:1;index" json:"status"`
	OnboardingStatus     int16      `gorm:"not null;default:2;index" json:"onboarding_status"`
	InviteCodeID         *int64     `gorm:"index" json:"invite_code_id,omitempty"`
	OnboardingRejectReason *string `gorm:"type:varchar(500)" json:"onboarding_reject_reason,omitempty"`
	OnboardingReviewedAt   *time.Time `json:"onboarding_reviewed_at,omitempty"`
	OnboardingReviewerID   *int64   `json:"onboarding_reviewer_id,omitempty"`
	ResumeURL                *string    `gorm:"column:resume_url;type:varchar(512)" json:"resume_url,omitempty"`
	OnboardingApplicationNote *string   `gorm:"type:text" json:"onboarding_application_note,omitempty"`
	OnboardingSubmittedAt    *time.Time `json:"onboarding_submitted_at,omitempty"`
	FreezeReason    *string    `gorm:"type:varchar(200)" json:"freeze_reason,omitempty"`
	LastLoginAt     *time.Time `json:"last_login_at,omitempty"`
	LastLoginIP     *string    `gorm:"type:varchar(45)" json:"-"`
	CreatedAt       time.Time  `gorm:"not null;autoCreateTime" json:"created_at"`
	UpdatedAt       time.Time  `gorm:"not null;autoUpdateTime" json:"updated_at"`
}

func (User) TableName() string {
	return "users"
}

func (u *User) BeforeCreate(tx *gorm.DB) error {
	if u.UUID == "" {
		u.UUID = GenerateUUID()
	}
	return nil
}

// Skill 技能标签模型
type Skill struct {
	ID         int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	Name       string    `gorm:"type:varchar(50);not null;uniqueIndex" json:"name"`
	Category   string    `gorm:"type:varchar(50);not null;index" json:"category"`
	IconURL    *string   `gorm:"type:varchar(512)" json:"icon_url"`
	SortOrder  int       `gorm:"not null;default:0" json:"sort_order"`
	IsHot      bool      `gorm:"not null;default:false" json:"is_hot"`
	UsageCount int       `gorm:"not null;default:0" json:"usage_count"`
	Status     int16     `gorm:"not null;default:1" json:"status"`
	CreatedAt  time.Time `gorm:"not null;autoCreateTime" json:"created_at"`
	UpdatedAt  time.Time `gorm:"not null;autoUpdateTime" json:"updated_at"`
}

func (Skill) TableName() string {
	return "skills"
}

// UserSkill 用户技能关联模型
type UserSkill struct {
	ID                int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UserID            int64      `gorm:"not null;index;uniqueIndex:idx_user_skill" json:"user_id"`
	SkillID           int64      `gorm:"not null;index;uniqueIndex:idx_user_skill" json:"skill_id"`
	Proficiency       int16      `gorm:"default:3" json:"proficiency"`
	YearsOfExperience int16      `gorm:"default:0" json:"years_of_experience"`
	IsPrimary         bool       `gorm:"not null;default:false" json:"is_primary"`
	IsCertified       bool       `gorm:"not null;default:false" json:"is_certified"`
	CertifiedAt       *time.Time `json:"certified_at,omitempty"`
	CreatedAt         time.Time  `gorm:"not null;autoCreateTime" json:"created_at"`
	Skill             Skill      `gorm:"foreignKey:SkillID" json:"skill,omitempty"`
}

func (UserSkill) TableName() string {
	return "user_skills"
}

// RoleTag 角色标签模型
type RoleTag struct {
	ID          int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	Name        string    `gorm:"type:varchar(50);not null;uniqueIndex" json:"name"`
	Description *string   `gorm:"type:varchar(200)" json:"description"`
	IconURL     *string   `gorm:"type:varchar(512)" json:"icon_url"`
	SortOrder   int       `gorm:"not null;default:0" json:"sort_order"`
	CreatedAt   time.Time `gorm:"not null;autoCreateTime" json:"created_at"`
}

func (RoleTag) TableName() string {
	return "role_tags"
}

// UserRoleTag 用户角色标签关联模型
type UserRoleTag struct {
	ID        int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	UserID    int64     `gorm:"not null;index;uniqueIndex:idx_user_role_tag" json:"user_id"`
	RoleTagID int64     `gorm:"not null;index;uniqueIndex:idx_user_role_tag" json:"role_tag_id"`
	IsPrimary bool      `gorm:"not null;default:false" json:"is_primary"`
	CreatedAt time.Time `gorm:"not null;autoCreateTime" json:"created_at"`
	RoleTag   RoleTag   `gorm:"foreignKey:RoleTagID" json:"role_tag,omitempty"`
}

func (UserRoleTag) TableName() string {
	return "user_role_tags"
}

// Portfolio 作品集模型
type Portfolio struct {
	ID                  int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID                string     `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	UserID              int64      `gorm:"not null;index" json:"user_id"`
	ProjectID           *int64     `json:"project_id,omitempty"`
	Title               string     `gorm:"type:varchar(200);not null" json:"title"`
	Description         *string    `gorm:"type:text" json:"description"`
	Category            string     `gorm:"type:varchar(50);not null;index" json:"category"`
	CoverURL            *string    `gorm:"type:varchar(512)" json:"cover_url"`
	PreviewURL          *string    `gorm:"type:varchar(512)" json:"preview_url"`
	TechStack           JSON       `gorm:"type:json" json:"tech_stack"`
	Images              JSON       `gorm:"type:json" json:"images"`
	DemoVideoURL        *string    `gorm:"type:varchar(512)" json:"demo_video_url"`
	IsPlatformCertified bool       `gorm:"not null;default:false" json:"is_platform_certified"`
	CertifiedAt         *time.Time `json:"certified_at,omitempty"`
	ViewCount           int        `gorm:"not null;default:0" json:"view_count"`
	LikeCount           int        `gorm:"not null;default:0" json:"like_count"`
	SortOrder           int        `gorm:"not null;default:0" json:"sort_order"`
	Status              int16      `gorm:"not null;default:1;index" json:"status"`
	CreatedAt           time.Time  `gorm:"not null;autoCreateTime" json:"created_at"`
	UpdatedAt           time.Time  `gorm:"not null;autoUpdateTime" json:"updated_at"`
}

func (Portfolio) TableName() string {
	return "portfolios"
}

func (p *Portfolio) BeforeCreate(tx *gorm.DB) error {
	if p.UUID == "" {
		p.UUID = GenerateUUID()
	}
	return nil
}

// SmsCode 短信验证码模型
type SmsCode struct {
	ID        int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	PhoneHash string    `gorm:"type:varchar(64);not null" json:"-"`
	Code      string    `gorm:"type:varchar(6);not null" json:"-"`
	Purpose   int16     `gorm:"not null" json:"purpose"`
	IsUsed    bool      `gorm:"not null;default:false" json:"is_used"`
	ExpireAt  time.Time `gorm:"not null" json:"expire_at"`
	IPAddress *string   `gorm:"type:varchar(45)" json:"-"`
	CreatedAt time.Time `gorm:"not null;autoCreateTime" json:"created_at"`
}

func (SmsCode) TableName() string {
	return "sms_codes"
}

// UserDevice 用户设备模型
type UserDevice struct {
	ID           int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	UserID       int64     `gorm:"not null;index;uniqueIndex:idx_user_device" json:"user_id"`
	DeviceID     string    `gorm:"type:varchar(128);not null;uniqueIndex:idx_user_device" json:"device_id"`
	DeviceType   string    `gorm:"type:varchar(20);not null" json:"device_type"`
	DeviceName   *string   `gorm:"type:varchar(100)" json:"device_name"`
	PushToken    *string   `gorm:"type:varchar(512)" json:"push_token"`
	AppVersion   *string   `gorm:"type:varchar(20)" json:"app_version"`
	OSVersion    *string   `gorm:"type:varchar(20)" json:"os_version"`
	IsActive     bool      `gorm:"not null;default:true" json:"is_active"`
	LastActiveAt time.Time `gorm:"not null;autoCreateTime" json:"last_active_at"`
	CreatedAt    time.Time `gorm:"not null;autoCreateTime" json:"created_at"`
}

func (UserDevice) TableName() string {
	return "user_devices"
}
