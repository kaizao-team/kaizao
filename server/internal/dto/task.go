package dto

// CreateTaskReq 手动创建 EARS 任务卡片
type CreateTaskReq struct {
	Title          string   `json:"title" binding:"required,min=1,max=200"`
	EarsType       string   `json:"ears_type" binding:"required,oneof=event story rule task context behavior"`
	EarsBehavior   string   `json:"ears_behavior" binding:"required"`
	EarsFullText   *string  `json:"ears_full_text"`
	EarsTrigger    *string  `json:"ears_trigger"`
	Module         *string  `json:"module" binding:"omitempty,max=100"`
	RoleTag        *string  `json:"role_tag" binding:"omitempty,max=50"`
	Priority       *int16   `json:"priority" binding:"omitempty,min=0,max=3"`
	MilestoneID    *string  `json:"milestone_id"` // 里程碑 UUID，可选
	AssigneeID     *string  `json:"assignee_id"`  // 用户 UUID，可选
	EstimatedHours *float64 `json:"estimated_hours" binding:"omitempty,min=0"`
	SortOrder      *int     `json:"sort_order" binding:"omitempty,min=0"`
}
