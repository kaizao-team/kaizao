package model

import (
	"time"

	"gorm.io/gorm"
)

// Conversation 会话模型
type Conversation struct {
	ID                 int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID               string     `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	ProjectID          *int64     `gorm:"index" json:"project_id,omitempty"`
	ConversationType   int16      `gorm:"not null;default:1" json:"conversation_type"`
	UserAID            *int64     `gorm:"index" json:"user_a_id,omitempty"`
	UserBID            *int64     `gorm:"index" json:"user_b_id,omitempty"`
	LastMessageContent *string    `gorm:"type:varchar(200)" json:"last_message_content,omitempty"`
	LastMessageType    *string    `gorm:"type:varchar(20)" json:"last_message_type,omitempty"`
	LastMessageAt      *time.Time `json:"last_message_at,omitempty"`
	LastMessageUserID  *int64     `json:"last_message_user_id,omitempty"`
	Status             int16      `gorm:"not null;default:1" json:"status"`
	CreatedAt          time.Time  `gorm:"not null;autoCreateTime" json:"created_at"`
	UpdatedAt          time.Time  `gorm:"not null;autoUpdateTime" json:"updated_at"`
}

func (Conversation) TableName() string {
	return "conversations"
}

func (c *Conversation) BeforeCreate(tx *gorm.DB) error {
	if c.UUID == "" {
		c.UUID = GenerateUUID()
	}
	return nil
}

// ConversationMember 会话成员模型
type ConversationMember struct {
	ID             int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	ConversationID int64     `gorm:"not null;index;uniqueIndex:idx_conv_member" json:"conversation_id"`
	UserID         int64     `gorm:"not null;index;uniqueIndex:idx_conv_member" json:"user_id"`
	Role           int16     `gorm:"not null;default:1" json:"role"`
	UnreadCount    int       `gorm:"not null;default:0" json:"unread_count"`
	LastReadMsgID  int64     `gorm:"default:0" json:"last_read_msg_id"`
	IsMuted        bool      `gorm:"not null;default:false" json:"is_muted"`
	IsPinned       bool      `gorm:"not null;default:false" json:"is_pinned"`
	JoinedAt       time.Time `gorm:"not null;autoCreateTime" json:"joined_at"`
}

func (ConversationMember) TableName() string {
	return "conversation_members"
}

// Message 消息模型
type Message struct {
	ID             int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID           string     `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	ConversationID int64      `gorm:"not null;index" json:"conversation_id"`
	SenderID       int64      `gorm:"not null;index" json:"sender_id"`
	ContentType    string     `gorm:"type:varchar(20);not null;default:'text'" json:"content_type"`
	Content        *string    `gorm:"type:text" json:"content,omitempty"`
	MediaURL       *string    `gorm:"type:varchar(512)" json:"media_url,omitempty"`
	MediaName      *string    `gorm:"type:varchar(200)" json:"media_name,omitempty"`
	MediaSize      *int       `json:"media_size,omitempty"`
	MediaDuration  *int       `json:"media_duration,omitempty"`
	ThumbnailURL   *string    `gorm:"type:varchar(512)" json:"thumbnail_url,omitempty"`
	ReplyToMsgID   *int64     `json:"reply_to_msg_id,omitempty"`
	RelatedTaskID  *int64     `gorm:"index" json:"related_task_id,omitempty"`
	ClientSeq      *int64     `json:"client_seq,omitempty"`
	Status         int16      `gorm:"not null;default:1" json:"status"`
	RecalledAt     *time.Time `json:"recalled_at,omitempty"`
	CreatedAt      time.Time  `gorm:"not null;autoCreateTime" json:"created_at"`

	// 关联
	Sender *User `gorm:"foreignKey:SenderID" json:"sender,omitempty"`
}

func (Message) TableName() string {
	return "messages"
}

func (m *Message) BeforeCreate(tx *gorm.DB) error {
	if m.UUID == "" {
		m.UUID = GenerateUUID()
	}
	return nil
}

// Review 评价模型
type Review struct {
	ID                    int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID                  string     `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	ProjectID             int64      `gorm:"not null;index" json:"project_id"`
	ReviewerID            int64      `gorm:"not null;index" json:"reviewer_id"`
	RevieweeID            int64      `gorm:"not null;index" json:"reviewee_id"`
	ReviewerRole          int16      `gorm:"not null" json:"reviewer_role"`
	OverallRating         float64    `gorm:"type:decimal(2,1);not null" json:"overall_rating"`
	QualityRating         *float64   `gorm:"type:decimal(2,1)" json:"quality_rating,omitempty"`
	CommunicationRating   *float64   `gorm:"type:decimal(2,1)" json:"communication_rating,omitempty"`
	TimelinessRating      *float64   `gorm:"type:decimal(2,1)" json:"timeliness_rating,omitempty"`
	ProfessionalismRating *float64   `gorm:"type:decimal(2,1)" json:"professionalism_rating,omitempty"`
	RequirementClarity    *float64   `gorm:"type:decimal(2,1)" json:"requirement_clarity,omitempty"`
	PaymentRating         *float64   `gorm:"type:decimal(2,1)" json:"payment_rating,omitempty"`
	CooperationRating     *float64   `gorm:"type:decimal(2,1)" json:"cooperation_rating,omitempty"`
	Content               *string    `gorm:"type:text" json:"content,omitempty"`
	Tags                  JSON       `gorm:"type:json" json:"tags"`
	MemberRatings         JSON       `gorm:"type:json" json:"member_ratings"`
	IsAnonymous           bool       `gorm:"not null;default:false" json:"is_anonymous"`
	Status                int16      `gorm:"not null;default:1" json:"status"`
	ReplyContent          *string    `gorm:"type:text" json:"reply_content,omitempty"`
	ReplyAt               *time.Time `json:"reply_at,omitempty"`
	CreatedAt             time.Time  `gorm:"not null;autoCreateTime" json:"created_at"`
	UpdatedAt             time.Time  `gorm:"not null;autoUpdateTime" json:"updated_at"`

	// 关联
	Reviewer *User `gorm:"foreignKey:ReviewerID" json:"reviewer,omitempty"`
	Reviewee *User `gorm:"foreignKey:RevieweeID" json:"reviewee,omitempty"`
}

func (Review) TableName() string {
	return "reviews"
}

func (r *Review) BeforeCreate(tx *gorm.DB) error {
	if r.UUID == "" {
		r.UUID = GenerateUUID()
	}
	return nil
}

// Notification 通知模型
type Notification struct {
	ID               int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID             string     `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	UserID           int64      `gorm:"not null;index" json:"user_id"`
	Title            string     `gorm:"type:varchar(200);not null" json:"title"`
	Content          string     `gorm:"type:text;not null" json:"content"`
	NotificationType int16      `gorm:"not null;index" json:"notification_type"`
	TargetType       *string    `gorm:"type:varchar(50)" json:"target_type,omitempty"`
	TargetID         *int64     `json:"target_id,omitempty"`
	IsRead           bool       `gorm:"not null;default:false" json:"is_read"`
	IsPushed         bool       `gorm:"not null;default:false" json:"is_pushed"`
	PushResult       *string    `gorm:"type:varchar(200)" json:"push_result,omitempty"`
	ReadAt           *time.Time `json:"read_at,omitempty"`
	CreatedAt        time.Time  `gorm:"not null;autoCreateTime" json:"created_at"`
}

func (Notification) TableName() string {
	return "notifications"
}

func (n *Notification) BeforeCreate(tx *gorm.DB) error {
	if n.UUID == "" {
		n.UUID = GenerateUUID()
	}
	return nil
}

// Report 举报模型
type Report struct {
	ID           int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID         string     `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	ReporterID   int64      `gorm:"not null;index" json:"reporter_id"`
	TargetType   string     `gorm:"type:varchar(50);not null" json:"target_type"`
	TargetID     int64      `gorm:"not null" json:"target_id"`
	ReasonType   int16      `gorm:"not null" json:"reason_type"`
	ReasonDetail *string    `gorm:"type:text" json:"reason_detail,omitempty"`
	Evidence     JSON       `gorm:"type:json" json:"evidence"`
	Status       int16      `gorm:"not null;default:1;index" json:"status"`
	HandlerID    *int64     `json:"handler_id,omitempty"`
	HandleResult *string    `gorm:"type:text" json:"handle_result,omitempty"`
	HandledAt    *time.Time `json:"handled_at,omitempty"`
	CreatedAt    time.Time  `gorm:"not null;autoCreateTime" json:"created_at"`
}

func (Report) TableName() string {
	return "reports"
}

func (r *Report) BeforeCreate(tx *gorm.DB) error {
	if r.UUID == "" {
		r.UUID = GenerateUUID()
	}
	return nil
}

// Arbitration 仲裁模型
type Arbitration struct {
	ID           int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID         string     `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	ProjectID    int64      `gorm:"not null;index" json:"project_id"`
	OrderID      *int64     `json:"order_id,omitempty"`
	ApplicantID  int64      `gorm:"not null;index" json:"applicant_id"`
	RespondentID int64      `gorm:"not null" json:"respondent_id"`
	Reason       string     `gorm:"type:text;not null" json:"reason"`
	Evidence     JSON       `gorm:"type:json" json:"evidence"`
	Status       int16      `gorm:"not null;default:1;index" json:"status"`
	ArbiterID    *int64     `json:"arbiter_id,omitempty"`
	Verdict      *string    `gorm:"type:text" json:"verdict,omitempty"`
	VerdictType  *int16     `json:"verdict_type,omitempty"`
	RefundAmount *float64   `gorm:"type:decimal(10,2)" json:"refund_amount,omitempty"`
	ArbitratedAt *time.Time `json:"arbitrated_at,omitempty"`
	CreatedAt    time.Time  `gorm:"not null;autoCreateTime" json:"created_at"`
	UpdatedAt    time.Time  `gorm:"not null;autoUpdateTime" json:"updated_at"`
}

func (Arbitration) TableName() string {
	return "arbitrations"
}

func (a *Arbitration) BeforeCreate(tx *gorm.DB) error {
	if a.UUID == "" {
		a.UUID = GenerateUUID()
	}
	return nil
}

// AgentSession AI Agent 会话模型
type AgentSession struct {
	ID                  int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID                string     `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	UserID              int64      `gorm:"not null;index" json:"user_id"`
	ProjectID           *int64     `gorm:"index" json:"project_id,omitempty"`
	AgentType           string     `gorm:"type:varchar(50);not null;index" json:"agent_type"`
	Status              int16      `gorm:"not null;default:1;index" json:"status"`
	CompletenessScore   float64    `gorm:"type:decimal(5,2);default:0.00" json:"completeness_score"`
	ConversationHistory JSON       `gorm:"type:json" json:"conversation_history"`
	GeneratedPRD        JSONMap    `gorm:"type:json" json:"generated_prd,omitempty"`
	GeneratedTasks      JSONMap    `gorm:"type:json" json:"generated_tasks,omitempty"`
	GeneratedEstimate   JSONMap    `gorm:"type:json" json:"generated_estimate,omitempty"`
	ModelUsed           *string    `gorm:"type:varchar(50)" json:"model_used,omitempty"`
	TotalTokens         int        `gorm:"default:0" json:"total_tokens"`
	TotalCost           float64    `gorm:"type:decimal(8,4);default:0.0000" json:"total_cost"`
	CompletedAt         *time.Time `json:"completed_at,omitempty"`
	CreatedAt           time.Time  `gorm:"not null;autoCreateTime" json:"created_at"`
	UpdatedAt           time.Time  `gorm:"not null;autoUpdateTime" json:"updated_at"`
}

func (AgentSession) TableName() string {
	return "agent_sessions"
}

func (as *AgentSession) BeforeCreate(tx *gorm.DB) error {
	if as.UUID == "" {
		as.UUID = GenerateUUID()
	}
	return nil
}

// Team 团队模型
type Team struct {
	ID             int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID           string     `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	Name           string     `gorm:"type:varchar(100);not null" json:"name"`
	LeaderID       int64      `gorm:"not null;index" json:"leader_id"`
	AvatarURL      *string    `gorm:"type:varchar(512)" json:"avatar_url,omitempty"`
	Description    *string    `gorm:"type:text" json:"description,omitempty"`
	TeamType       int16      `gorm:"not null;default:1;index" json:"team_type"`
	ProjectID      *int64     `gorm:"index" json:"project_id,omitempty"`
	SkillsCoverage JSON       `gorm:"type:json" json:"skills_coverage"`
	MemberCount    int        `gorm:"not null;default:1" json:"member_count"`
	AvgRating      float64    `gorm:"type:decimal(3,2);not null;default:0.00" json:"avg_rating"`
	TotalProjects  int        `gorm:"not null;default:0" json:"total_projects"`
	TotalEarnings  float64    `gorm:"type:decimal(12,2);not null;default:0.00" json:"total_earnings"`
	Status         int16      `gorm:"not null;default:1;index" json:"status"`
	DisbandedAt    *time.Time `json:"disbanded_at,omitempty"`
	CreatedAt      time.Time  `gorm:"not null;autoCreateTime" json:"created_at"`
	UpdatedAt      time.Time  `gorm:"not null;autoUpdateTime" json:"updated_at"`

	// 关联
	Leader  *User        `gorm:"foreignKey:LeaderID" json:"leader,omitempty"`
	Members []TeamMember `gorm:"foreignKey:TeamID" json:"members,omitempty"`
}

func (Team) TableName() string {
	return "teams"
}

func (t *Team) BeforeCreate(tx *gorm.DB) error {
	if t.UUID == "" {
		t.UUID = GenerateUUID()
	}
	return nil
}

// TeamMember 团队成员模型
type TeamMember struct {
	ID         int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	TeamID     int64      `gorm:"not null;index;uniqueIndex:idx_team_user" json:"team_id"`
	UserID     int64      `gorm:"not null;index;uniqueIndex:idx_team_user" json:"user_id"`
	RoleInTeam string     `gorm:"type:varchar(50);not null" json:"role_in_team"`
	SplitRatio float64    `gorm:"type:decimal(5,2);not null" json:"split_ratio"`
	Status     int16      `gorm:"not null;default:1" json:"status"`
	JoinedAt   time.Time  `gorm:"not null;autoCreateTime" json:"joined_at"`
	LeftAt     *time.Time `json:"left_at,omitempty"`

	// 关联
	User *User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

func (TeamMember) TableName() string {
	return "team_members"
}

// TeamInvite 团队邀请模型
type TeamInvite struct {
	ID          int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID        string     `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	TeamID      int64      `gorm:"not null;index" json:"team_id"`
	InviterID   int64      `gorm:"not null" json:"inviter_id"`
	InviteeID   int64      `gorm:"not null;index" json:"invitee_id"`
	RoleInTeam  string     `gorm:"type:varchar(50);not null" json:"role_in_team"`
	SplitRatio  float64    `gorm:"type:decimal(5,2);not null" json:"split_ratio"`
	Message     *string    `gorm:"type:text" json:"message,omitempty"`
	Status      int16      `gorm:"not null;default:1" json:"status"`
	ExpireAt    time.Time  `gorm:"not null" json:"expire_at"`
	RespondedAt *time.Time `json:"responded_at,omitempty"`
	CreatedAt   time.Time  `gorm:"not null;autoCreateTime" json:"created_at"`
}

func (TeamInvite) TableName() string {
	return "team_invites"
}

func (ti *TeamInvite) BeforeCreate(tx *gorm.DB) error {
	if ti.UUID == "" {
		ti.UUID = GenerateUUID()
	}
	return nil
}

// TeamPost 组队大厅帖子模型
type TeamPost struct {
	ID             int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID           string    `gorm:"type:varchar(36);not null;uniqueIndex" json:"uuid"`
	AuthorID       int64     `gorm:"not null;index" json:"author_id"`
	ProjectID      *int64    `gorm:"index" json:"project_id,omitempty"`
	Title          string    `gorm:"type:varchar(200);not null" json:"title"`
	Description    string    `gorm:"type:text;not null" json:"description"`
	NeededRoles    JSON      `gorm:"type:json" json:"needed_roles"`
	RequiredSkills JSON      `gorm:"type:json" json:"required_skills"`
	Status         int16     `gorm:"not null;default:1;index" json:"status"`
	ViewCount      int       `gorm:"not null;default:0" json:"view_count"`
	ApplyCount     int       `gorm:"not null;default:0" json:"apply_count"`
	CreatedAt      time.Time `gorm:"not null;autoCreateTime" json:"created_at"`
	UpdatedAt      time.Time `gorm:"not null;autoUpdateTime" json:"updated_at"`

	// 关联
	Author *User `gorm:"foreignKey:AuthorID" json:"author,omitempty"`
}

func (TeamPost) TableName() string {
	return "team_posts"
}

func (tp *TeamPost) BeforeCreate(tx *gorm.DB) error {
	if tp.UUID == "" {
		tp.UUID = GenerateUUID()
	}
	return nil
}
