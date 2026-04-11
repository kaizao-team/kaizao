package service

import (
	"encoding/json"
	"time"

	"github.com/vibebuild/server/internal/model"
)

// ProjectListItem 项目列表 / 首页「我的项目」等与 Flutter ProjectModel 对齐的统一 JSON 结构
type ProjectListItem struct {
	ID                string     `json:"id"`
	UUID              string     `json:"uuid"`
	OwnerID           string     `json:"owner_id"`
	OwnerName         string     `json:"owner_name,omitempty"`
	Title             string     `json:"title"`
	Description       string     `json:"description"`
	Category          string     `json:"category"`
	BudgetMin         *float64   `json:"budget_min"`
	BudgetMax         *float64   `json:"budget_max"`
	AgreedPrice       *float64   `json:"agreed_price,omitempty"`
	DeadlineAt        *time.Time `json:"deadline_at,omitempty"`
	PublishedAt       *time.Time `json:"published_at,omitempty"`
	MatchMode         int16      `json:"match_mode"`
	Progress          int16      `json:"progress"`
	Status            int16      `json:"status"`
	TechRequirements  []string   `json:"tech_requirements"`
	ViewCount         int        `json:"view_count"`
	BidCount          int        `json:"bid_count"`
	FavoriteCount     int        `json:"favorite_count"`
	CreatedAt         time.Time  `json:"created_at"`
	ProviderID        *string    `json:"provider_id,omitempty"`
	ProviderName      *string    `json:"provider_name,omitempty"`
	ProviderAvatarURL *string    `json:"provider_avatar_url,omitempty"`
	MatchScore        *int       `json:"match_score,omitempty"`
	OwnerAligned      bool       `json:"owner_aligned"`
	ProviderAligned   bool       `json:"provider_aligned"`
}

func parseProjectTechRequirements(raw model.JSON) []string {
	var result []string
	if len(raw) > 0 {
		_ = json.Unmarshal([]byte(raw), &result)
	}
	if result == nil {
		return []string{}
	}
	return result
}

// NewProjectListItem 从领域模型填充列表项（需 Owner / Provider 按需 Preload）
func NewProjectListItem(p *model.Project) ProjectListItem {
	ownerID := ""
	ownerName := ""
	if p.Owner != nil {
		ownerID = p.Owner.UUID
		ownerName = p.Owner.Nickname
	}

	var providerID, providerName *string
	var providerAvatar *string
	if p.Provider != nil {
		pid := p.Provider.UUID
		providerID = &pid
		pn := p.Provider.Nickname
		providerName = &pn
		providerAvatar = p.Provider.AvatarURL
	}

	return ProjectListItem{
		ID:                p.UUID,
		UUID:              p.UUID,
		OwnerID:           ownerID,
		OwnerName:         ownerName,
		Title:             p.Title,
		Description:       p.Description,
		Category:          p.Category,
		BudgetMin:         p.BudgetMin,
		BudgetMax:         p.BudgetMax,
		AgreedPrice:       p.AgreedPrice,
		DeadlineAt:        p.Deadline,
		PublishedAt:       p.PublishedAt,
		MatchMode:         p.MatchMode,
		Progress:          p.Progress,
		Status:            p.Status,
		TechRequirements:  parseProjectTechRequirements(p.TechRequirements),
		ViewCount:         p.ViewCount,
		BidCount:          p.BidCount,
		FavoriteCount:     p.FavoriteCount,
		CreatedAt:         p.CreatedAt,
		ProviderID:        providerID,
		ProviderName:      providerName,
		ProviderAvatarURL: providerAvatar,
		OwnerAligned:      p.OwnerAligned,
		ProviderAligned:   p.ProviderAligned,
	}
}
