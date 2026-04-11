package service

import (
	"encoding/json"
	"strconv"
	"strings"

	"github.com/vibebuild/server/internal/model"
)

// CalcMatchScore computes a 0-100 match score between a project and a team.
// Weight: direction(50) + budget(30) + level(20).
func CalcMatchScore(project *model.Project, team *model.Team) int {
	score := 0

	// 1. Direction match (50 pts): any of team's directions matches project category
	directions := parseDirections(team.ServiceDirections)
	for _, d := range directions {
		if strings.EqualFold(d, project.Category) {
			score += 50
			break
		}
	}

	// 2. Budget match (30 pts)
	score += calcBudgetScore(project, team)

	// 3. Level match (20 pts)
	score += calcLevelScore(team.VibeLevel)

	if score > 100 {
		score = 100
	}
	return score
}

func parseDirections(raw model.JSON) []string {
	if len(raw) == 0 {
		return nil
	}
	var dirs []string
	if err := json.Unmarshal([]byte(raw), &dirs); err != nil {
		return nil
	}
	return dirs
}

// calcBudgetScore: full overlap → 30, partial → 15, none → 0
func calcBudgetScore(project *model.Project, team *model.Team) int {
	if project.BudgetMax == nil && project.BudgetMin == nil {
		return 30
	}
	if team.BudgetMin == nil && team.BudgetMax == nil {
		return 0
	}

	pMin := 0.0
	pMax := 0.0
	if project.BudgetMin != nil {
		pMin = *project.BudgetMin
	}
	if project.BudgetMax != nil {
		pMax = *project.BudgetMax
	}
	if pMax <= 0 && pMin > 0 {
		pMax = pMin
	}
	if pMin <= 0 && pMax > 0 {
		pMin = pMax
	}

	tMin := 0.0
	tMax := 0.0
	if team.BudgetMin != nil {
		tMin = *team.BudgetMin
	}
	if team.BudgetMax != nil {
		tMax = *team.BudgetMax
	}
	if tMax <= 0 && tMin > 0 {
		tMax = tMin
	}
	if tMin <= 0 && tMax > 0 {
		tMin = tMax
	}

	// Full containment: project budget falls within team range
	if pMin >= tMin && pMax <= tMax {
		return 30
	}
	// Partial overlap
	if pMin <= tMax && pMax >= tMin {
		return 15
	}
	return 0
}

// calcLevelScore maps vc-T1~T10 to points: T1=4, T2=8, T3=12, T4=16, T5+=20
func calcLevelScore(vibeLevel string) int {
	level := strings.TrimPrefix(vibeLevel, "vc-T")
	if level == vibeLevel {
		return 4
	}
	n, err := strconv.Atoi(level)
	if err != nil || n < 1 {
		return 4
	}
	if n >= 5 {
		return 20
	}
	return n * 4
}
