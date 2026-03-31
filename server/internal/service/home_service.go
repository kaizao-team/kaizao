package service

import (
	"encoding/json"

	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/repository"
	"go.uber.org/zap"
)

// HomeService 首页聚合
type HomeService struct {
	repos *repository.Repositories
	log   *zap.Logger
}

// NewHomeService 创建首页服务
func NewHomeService(repos *repository.Repositories, log *zap.Logger) *HomeService {
	return &HomeService{repos: repos, log: log}
}

func parseTechStack(raw model.JSON) []string {
	var result []string
	if len(raw) > 0 {
		_ = json.Unmarshal([]byte(raw), &result)
	}
	if result == nil {
		return []string{}
	}
	return result
}

// GetDemanderHome GET /api/v1/home/demander
func (s *HomeService) GetDemanderHome(userUUID string) (map[string]interface{}, error) {
	u, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return nil, err
	}
	myProjects, _, _ := s.repos.Project.ListByOwnerID(u.ID, 0, 20)
	experts, _, _ := s.repos.User.ListExperts(0, 10)

	catMap, _ := s.repos.Project.CountByCategory()
	categories := []map[string]interface{}{}
	for k, cnt := range catMap {
		categories = append(categories, map[string]interface{}{
			"key": k, "name": k, "icon": "category", "count": cnt,
		})
	}

	myList := make([]map[string]interface{}, 0, len(myProjects))
	for _, p := range myProjects {
		ownerID := ""
		if p.Owner != nil {
			ownerID = p.Owner.UUID
		}
		myList = append(myList, map[string]interface{}{
			"id": p.UUID, "uuid": p.UUID, "owner_id": ownerID,
			"title": p.Title, "description": p.Description, "category": p.Category,
			"budget_min": p.BudgetMin, "budget_max": p.BudgetMax,
			"progress": p.Progress, "status": p.Status,
			"tech_requirements": parseTechStack(p.TechRequirements),
			"view_count": p.ViewCount, "bid_count": p.BidCount,
			"created_at": p.CreatedAt,
		})
	}

	recExperts := make([]map[string]interface{}, 0, len(experts))
	for _, e := range experts {
		skills, _ := s.repos.User.ListUserSkills(e.ID)
		skillStr := expertPrimarySkillName(skills, nil)
		recExperts = append(recExperts, map[string]interface{}{
			"id":                e.UUID,
			"nickname":          e.Nickname,
			"avatar_url":        e.AvatarURL,
			"rating":            e.AvgRating,
			"skill":             skillStr,
			"hourly_rate":       e.HourlyRate,
			"completed_orders":  e.CompletedOrders,
		})
	}

	return map[string]interface{}{
		"ai_prompt":           "描述你的需求，开造帮你匹配造物者",
		"categories":          categories,
		"my_projects":         myList,
		"recommended_experts": recExperts,
	}, nil
}

// GetExpertHome GET /api/v1/home/expert
func (s *HomeService) GetExpertHome(userUUID string) (map[string]interface{}, error) {
	u, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return nil, err
	}
	demands, _, _ := s.repos.Project.ListMarket(0, 10, repository.ProjectFilter{Sort: "latest"})

	rec := make([]map[string]interface{}, 0, len(demands))
	for _, p := range demands {
		ownerID := ""
		if p.Owner != nil {
			ownerID = p.Owner.UUID
		}
		item := map[string]interface{}{
			"id": p.UUID, "uuid": p.UUID, "owner_id": ownerID,
			"title": p.Title, "description": p.Description, "category": p.Category,
			"budget_min": p.BudgetMin, "budget_max": p.BudgetMax,
			"status": p.Status,
			"tech_requirements": parseTechStack(p.TechRequirements),
			"view_count": p.ViewCount, "bid_count": p.BidCount,
			"created_at": p.CreatedAt,
		}
		skills, _ := s.repos.User.ListUserSkills(u.ID)
		if len(skills) > 0 && len(p.TechRequirements) > 0 {
			item["match_score"] = 75
		}
		rec = append(rec, item)
	}

	return map[string]interface{}{
		"revenue": map[string]interface{}{
			"total_income": u.TotalEarnings, "month_income": 0.0,
			"pending_income": 0.0, "trend": 0.0,
		},
		"recommended_demands": rec,
		"skill_heat":          []map[string]interface{}{},
		"team_opportunities":  []map[string]interface{}{},
	}, nil
}
