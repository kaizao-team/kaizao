package dto

// CreateMilestoneReq 创建里程碑请求
type CreateMilestoneReq struct {
	Title        string   `json:"title" binding:"required,min=1,max=200"`
	Description  *string  `json:"description" binding:"omitempty"`
	SortOrder    *int     `json:"sort_order" binding:"omitempty,min=0"`
	DueDate      *string  `json:"due_date" binding:"omitempty"` // YYYY-MM-DD
	PaymentRatio *float64 `json:"payment_ratio" binding:"omitempty,gte=0,lte=100"`
}
