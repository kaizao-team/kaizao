package service

import (
	"fmt"
	"strconv"

	"github.com/vibebuild/server/internal/model"
)

// ReplaceUserSkillsItem 更新技能的一条载荷（支持 skill_id、id 或 name+category）
type ReplaceUserSkillsItem struct {
	SkillID           *int64
	ID                interface{}
	Name              string
	Category          string
	Proficiency       int16
	YearsOfExperience int16
	IsPrimary         bool
}

func jsonIDToInt64(v interface{}) (int64, bool) {
	if v == nil {
		return 0, false
	}
	switch x := v.(type) {
	case float64:
		if x < 1 {
			return 0, false
		}
		return int64(x), true
	case int:
		if x < 1 {
			return 0, false
		}
		return int64(x), true
	case int64:
		if x < 1 {
			return 0, false
		}
		return x, true
	case string:
		if x == "" {
			return 0, false
		}
		n, err := strconv.ParseInt(x, 10, 64)
		return n, err == nil && n > 0
	default:
		return 0, false
	}
}

// ReplaceUserSkills 全量替换用户技能关联
func (s *UserService) ReplaceUserSkills(userUUID string, items []ReplaceUserSkillsItem) error {
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return err
	}
	var rows []*model.UserSkill
	seenSkill := make(map[int64]struct{})
	for _, it := range items {
		var sk *model.Skill
		var err error
		switch {
		case it.SkillID != nil && *it.SkillID > 0:
			sk, err = s.repos.User.FindSkillByID(*it.SkillID)
		default:
			if sid, ok := jsonIDToInt64(it.ID); ok {
				sk, err = s.repos.User.FindSkillByID(sid)
			} else if it.Name != "" {
				sk, err = s.repos.User.EnsureSkill(it.Name, it.Category)
			}
		}
		if err != nil || sk == nil {
			continue
		}
		if _, dup := seenSkill[sk.ID]; dup {
			continue
		}
		seenSkill[sk.ID] = struct{}{}
		p := it.Proficiency
		if p == 0 {
			p = 3
		}
		rows = append(rows, &model.UserSkill{
			UserID:            user.ID,
			SkillID:           sk.ID,
			Proficiency:       p,
			YearsOfExperience: it.YearsOfExperience,
			IsPrimary:         it.IsPrimary,
		})
	}
	if len(items) > 0 && len(rows) == 0 {
		return fmt.Errorf("no valid skills")
	}
	return s.repos.User.ReplaceUserSkills(user.ID, rows)
}

// expertPrimarySkillName 选取展示用主技能名（单测与首页专家列表共用）
func expertPrimarySkillName(skills []*model.UserSkill, namesBySkillID map[int64]string) string {
	if len(skills) == 0 {
		return ""
	}
	pick := func(us *model.UserSkill) string {
		if us == nil {
			return ""
		}
		if us.Skill.Name != "" {
			return us.Skill.Name
		}
		if namesBySkillID != nil {
			if n, ok := namesBySkillID[us.SkillID]; ok && n != "" {
				return n
			}
		}
		return ""
	}
	for _, us := range skills {
		if us != nil && us.IsPrimary {
			if s := pick(us); s != "" {
				return s
			}
		}
	}
	for _, us := range skills {
		if s := pick(us); s != "" {
			return s
		}
	}
	return ""
}

func groupUserSkillsByUserID(rows []*model.UserSkill) map[int64][]*model.UserSkill {
	m := make(map[int64][]*model.UserSkill)
	for _, r := range rows {
		if r == nil {
			continue
		}
		m[r.UserID] = append(m[r.UserID], r)
	}
	return m
}

func skillIDsMissingPreloadedName(skills []*model.UserSkill) []int64 {
	seen := make(map[int64]struct{})
	var out []int64
	for _, us := range skills {
		if us == nil {
			continue
		}
		if us.Skill.Name != "" {
			continue
		}
		if _, ok := seen[us.SkillID]; ok {
			continue
		}
		seen[us.SkillID] = struct{}{}
		out = append(out, us.SkillID)
	}
	return out
}
