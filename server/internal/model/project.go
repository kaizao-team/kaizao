package model

import (
	"time"

	"gorm.io/gorm"
)

// ── 项目状态 (Project.Status) ──────────────────────────────────
//
//	1  草稿          — 未发布，仅项目方可见
//	2  已发布        — 等待投标 / 匹配团队
//	3  已撮合        — 团队确认后进入，等待平台对齐需求
//	4  需求对齐中    — 项目方确认需求已对齐，等待启动
//	5  进行中        — 项目正式开工
//	6  验收中        — 里程碑验收阶段
//	7  已完成        — 全部里程碑验收通过
//	8  已关闭        — 用户主动关闭（草稿 / 已发布 / 已完成均可关闭）
//	9  争议中        — 仲裁流程中
//
// 状态流转:
//   1 → 2（发布）
//   2 → 3（团队方确认 bid）
//   2 → 8（项目方主动关闭）
//   3 → 4（项目方确认需求对齐）
//   4 → 5（项目方启动项目）
//   5 → 6 → 7（里程碑验收）
//   3-6 不可关闭
//
// 团队方拒绝 bid 时：3 → 2（回退，可重新匹配）
const (
	ProjectStatusDraft          int16 = 1
	ProjectStatusPublished      int16 = 2
	ProjectStatusMatched        int16 = 3
	ProjectStatusAligning       int16 = 4
	ProjectStatusInProgress     int16 = 5
	ProjectStatusAccepting      int16 = 6
	ProjectStatusCompleted      int16 = 7
	ProjectStatusClosed         int16 = 8
	ProjectStatusDisputed       int16 = 9
)

// Project 项目/需求模型
type Project struct {
	ID                 int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID               string     `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	OwnerID            int64      `gorm:"not null;index" json:"owner_id"`
	ProviderID         *int64     `gorm:"index" json:"provider_id,omitempty"`
	TeamID             *int64     `gorm:"index" json:"team_id,omitempty"`
	BidID              *int64     `json:"bid_id,omitempty"`
	Title              string     `gorm:"type:varchar(200);not null" json:"title"`
	Description        string     `gorm:"type:text;not null" json:"description"`
	Category           string     `gorm:"type:varchar(50);not null;index" json:"category"`
	TemplateType       *string    `gorm:"type:varchar(50)" json:"template_type,omitempty"`
	AiPRD              JSONMap    `gorm:"type:json" json:"ai_prd,omitempty"`
	AiEstimate         JSONMap    `gorm:"type:json" json:"ai_estimate,omitempty"`
	ConfirmedPRD       JSONMap    `gorm:"type:json" json:"confirmed_prd,omitempty"`
	BudgetMin          *float64   `gorm:"type:decimal(10,2)" json:"budget_min"`
	BudgetMax          *float64   `gorm:"type:decimal(10,2)" json:"budget_max"`
	AgreedPrice        *float64   `gorm:"type:decimal(10,2)" json:"agreed_price,omitempty"`
	Deadline           *time.Time `gorm:"type:date" json:"deadline,omitempty"`
	AgreedDays         *int       `json:"agreed_days,omitempty"`
	StartDate          *time.Time `gorm:"type:date" json:"start_date,omitempty"`
	ActualEndDate      *time.Time `gorm:"type:date" json:"actual_end_date,omitempty"`
	Complexity         *string    `gorm:"type:varchar(10)" json:"complexity,omitempty"`
	TechRequirements   JSON       `gorm:"type:json" json:"tech_requirements"`
	Attachments        JSON       `gorm:"type:json" json:"attachments"`
	MatchMode          int16      `gorm:"not null;default:1;index" json:"match_mode"`
	Progress           int16      `gorm:"not null;default:0" json:"progress"`
	CurrentMilestoneID *int64     `json:"current_milestone_id,omitempty"`
	Status             int16      `gorm:"not null;default:1;index" json:"status"`
	CloseReason        *string    `gorm:"type:varchar(200)" json:"close_reason,omitempty"`
	ViewCount          int        `gorm:"not null;default:0" json:"view_count"`
	BidCount           int        `gorm:"not null;default:0" json:"bid_count"`
	FavoriteCount      int        `gorm:"not null;default:0" json:"favorite_count"`
	PublishedAt        *time.Time `json:"published_at,omitempty"`
	MatchedAt          *time.Time `json:"matched_at,omitempty"`
	StartedAt          *time.Time `json:"started_at,omitempty"`
	CompletedAt        *time.Time `json:"completed_at,omitempty"`
	CreatedAt          time.Time  `gorm:"not null;autoCreateTime" json:"created_at"`
	UpdatedAt          time.Time  `gorm:"not null;autoUpdateTime" json:"updated_at"`

	// 关联
	Owner    *User `gorm:"foreignKey:OwnerID" json:"owner,omitempty"`
	Provider *User `gorm:"foreignKey:ProviderID" json:"provider,omitempty"`
	Team     *Team `gorm:"foreignKey:TeamID" json:"team,omitempty"`
}

func (Project) TableName() string {
	return "projects"
}

func (p *Project) BeforeCreate(tx *gorm.DB) error {
	if p.UUID == "" {
		p.UUID = GenerateUUID()
	}
	return nil
}

// Milestone 里程碑模型
type Milestone struct {
	ID              int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID            string     `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	ProjectID       int64      `gorm:"not null;index" json:"project_id"`
	Title           string     `gorm:"type:varchar(200);not null" json:"title"`
	Description     *string    `gorm:"type:text" json:"description,omitempty"`
	SortOrder       int        `gorm:"not null" json:"sort_order"`
	PaymentRatio    *float64   `gorm:"type:decimal(5,2)" json:"payment_ratio,omitempty"`
	PaymentAmount   *float64   `gorm:"type:decimal(10,2)" json:"payment_amount,omitempty"`
	DueDate         *time.Time `gorm:"type:date" json:"due_date,omitempty"`
	Status          int16      `gorm:"not null;default:1;index" json:"status"`
	DeliveryNote    *string    `gorm:"type:text" json:"delivery_note,omitempty"`
	PreviewURL      *string    `gorm:"type:varchar(512)" json:"preview_url,omitempty"`
	RejectionReason *string    `gorm:"type:text" json:"rejection_reason,omitempty"`
	FeatureItemIDs  JSON       `gorm:"type:json" json:"feature_item_ids,omitempty"`
	Phases          JSON       `gorm:"type:json" json:"phases,omitempty"`
	EstimatedDays   *float64   `gorm:"type:decimal(5,1)" json:"estimated_days,omitempty"`
	DeliveredAt     *time.Time `json:"delivered_at,omitempty"`
	AcceptedAt      *time.Time `json:"accepted_at,omitempty"`
	CreatedAt       time.Time  `gorm:"not null;autoCreateTime" json:"created_at"`
	UpdatedAt       time.Time  `gorm:"not null;autoUpdateTime" json:"updated_at"`
}

func (Milestone) TableName() string {
	return "milestones"
}

func (m *Milestone) BeforeCreate(tx *gorm.DB) error {
	if m.UUID == "" {
		m.UUID = GenerateUUID()
	}
	return nil
}

// Task EARS任务卡片模型
type Task struct {
	ID                 int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID               string     `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	ProjectID          int64      `gorm:"not null;index" json:"project_id"`
	MilestoneID        *int64     `gorm:"index" json:"milestone_id,omitempty"`
	ParentTaskID       *int64     `gorm:"index" json:"parent_task_id,omitempty"`
	TaskCode           string     `gorm:"type:varchar(20);not null" json:"task_code"`
	Title              string     `gorm:"type:varchar(200);not null" json:"title"`
	EarsType           string     `gorm:"type:varchar(20);not null;index" json:"ears_type"`
	EarsTrigger        *string    `gorm:"type:text" json:"ears_trigger,omitempty"`
	EarsBehavior       string     `gorm:"type:text;not null" json:"ears_behavior"`
	EarsFullText       string     `gorm:"type:text;not null" json:"ears_full_text"`
	Module             *string    `gorm:"type:varchar(100);index" json:"module,omitempty"`
	RoleTag            *string    `gorm:"type:varchar(50)" json:"role_tag,omitempty"`
	AssigneeID         *int64     `gorm:"index" json:"assignee_id,omitempty"`
	Priority           int16      `gorm:"not null;default:2;index" json:"priority"`
	EstimatedHours     *float64   `gorm:"type:decimal(5,1)" json:"estimated_hours,omitempty"`
	ActualHours        *float64   `gorm:"type:decimal(5,1)" json:"actual_hours,omitempty"`
	AcceptanceCriteria JSON       `gorm:"type:json" json:"acceptance_criteria"`
	Dependencies       JSON       `gorm:"type:json" json:"dependencies"`
	Blockers           JSON       `gorm:"type:json" json:"blockers"`
	Status             int16      `gorm:"not null;default:1;index" json:"status"`
	SortOrder          int        `gorm:"not null;default:0" json:"sort_order"`
	IsAIGenerated      bool       `gorm:"not null;default:false" json:"is_ai_generated"`
	AIConfidence       *float64   `gorm:"type:decimal(3,2)" json:"ai_confidence,omitempty"`
	Extra              JSONMap    `gorm:"type:json" json:"extra,omitempty"`
	StartedAt          *time.Time `json:"started_at,omitempty"`
	CompletedAt        *time.Time `json:"completed_at,omitempty"`
	CreatedAt          time.Time  `gorm:"not null;autoCreateTime" json:"created_at"`
	UpdatedAt          time.Time  `gorm:"not null;autoUpdateTime" json:"updated_at"`

	// 关联
	Assignee *User `gorm:"foreignKey:AssigneeID" json:"assignee,omitempty"`
}

func (Task) TableName() string {
	return "tasks"
}

func (t *Task) BeforeCreate(tx *gorm.DB) error {
	if t.UUID == "" {
		t.UUID = GenerateUUID()
	}
	return nil
}
