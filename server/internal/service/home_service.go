package service

import (
	"sort"

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

// GetDemanderHome GET /api/v1/home/demander
func (s *HomeService) GetDemanderHome(userUUID string) (map[string]interface{}, error) {
	u, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return nil, err
	}
	myProjects, _, _ := s.repos.Project.ListByOwnerID(u.ID, 0, 20)
	teams, _, _ := s.repos.Team.ListActiveTeams(0, 10)

	catMap, _ := s.repos.Project.CountByCategory()
	categories := []map[string]interface{}{}
	for k, cnt := range catMap {
		categories = append(categories, map[string]interface{}{
			"key": k, "name": k, "icon": "category", "count": cnt,
		})
	}

	myList := make([]ProjectListItem, 0, len(myProjects))
	for _, p := range myProjects {
		myList = append(myList, NewProjectListItem(p))
	}

	leaderIDs := make([]int64, 0, len(teams))
	for _, t := range teams {
		leaderIDs = append(leaderIDs, t.LeaderID)
	}
	allSkills, _ := s.repos.User.ListUserSkillsForUsers(leaderIDs)
	skillsByUser := groupUserSkillsByUserID(allSkills)

	recExperts := make([]map[string]interface{}, 0, len(teams))
	for _, t := range teams {
		item := map[string]interface{}{
			"id":           t.UUID,
			"team_name":    t.Name,
			"rating":       t.AvgRating,
			"hourly_rate":  t.HourlyRate,
			"budget_min":   t.BudgetMin,
			"budget_max":   t.BudgetMax,
			"member_count": t.MemberCount,
			"vibe_level":   t.VibeLevel,
			"vibe_power":   t.VibePower,
		}
		if t.Leader != nil {
			item["leader_uuid"] = t.Leader.UUID
			item["nickname"] = t.Leader.Nickname
			item["avatar_url"] = t.Leader.AvatarURL
			item["completed_projects"] = t.Leader.CompletedOrders
			item["tagline"] = t.Leader.Bio

			skills := skillsByUser[t.Leader.ID]
			skillNames := make([]string, 0, len(skills))
			for _, sk := range skills {
				if sk.Skill.Name != "" {
					skillNames = append(skillNames, sk.Skill.Name)
				}
			}
			item["skills"] = skillNames
			item["skill"] = expertPrimarySkillName(skills, nil)
		}
		recExperts = append(recExperts, item)
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

	// Resolve the current user's team for direction-based matching
	team, _ := s.repos.Team.FindPrimaryTeamForUser(u.ID)

	rec := make([]ProjectListItem, 0, len(demands))
	for _, p := range demands {
		item := NewProjectListItem(p)
		if team != nil {
			ms := CalcMatchScore(p, team)
			item.MatchScore = &ms
		}
		rec = append(rec, item)
	}
	// Sort by match_score descending
	sort.Slice(rec, func(i, j int) bool {
		si, sj := 0, 0
		if rec[i].MatchScore != nil {
			si = *rec[i].MatchScore
		}
		if rec[j].MatchScore != nil {
			sj = *rec[j].MatchScore
		}
		return si > sj
	})

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
