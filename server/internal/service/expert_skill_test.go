package service

import (
	"testing"

	"github.com/vibebuild/server/internal/model"
)

func TestExpertPrimarySkillName(t *testing.T) {
	t.Parallel()
	primaryGo := &model.UserSkill{UserID: 1, SkillID: 10, IsPrimary: true, Skill: model.Skill{Name: "Go"}}
	secondaryPy := &model.UserSkill{UserID: 1, SkillID: 11, IsPrimary: false, Skill: model.Skill{Name: "Python"}}

	t.Run("主技能优先", func(t *testing.T) {
		t.Parallel()
		got := expertPrimarySkillName([]*model.UserSkill{secondaryPy, primaryGo}, nil)
		if got != "Go" {
			t.Fatalf("got %q want Go", got)
		}
	})

	t.Run("无主技能时取首条有效", func(t *testing.T) {
		t.Parallel()
		got := expertPrimarySkillName([]*model.UserSkill{secondaryPy}, nil)
		if got != "Python" {
			t.Fatalf("got %q want Python", got)
		}
	})

	t.Run("预加载名为空时用 namesBySkillID 兜底", func(t *testing.T) {
		t.Parallel()
		us := &model.UserSkill{UserID: 1, SkillID: 99, IsPrimary: true, Skill: model.Skill{}}
		got := expertPrimarySkillName([]*model.UserSkill{us}, map[int64]string{99: "Rust"})
		if got != "Rust" {
			t.Fatalf("got %q want Rust", got)
		}
	})

	t.Run("主技能预加载空但兜底有值优先于次技能预加载名", func(t *testing.T) {
		t.Parallel()
		primaryNoName := &model.UserSkill{UserID: 1, SkillID: 1, IsPrimary: true, Skill: model.Skill{}}
		secondaryNamed := &model.UserSkill{UserID: 1, SkillID: 2, IsPrimary: false, Skill: model.Skill{Name: "Vue"}}
		got := expertPrimarySkillName([]*model.UserSkill{primaryNoName, secondaryNamed}, map[int64]string{1: "主技能兜底"})
		if got != "主技能兜底" {
			t.Fatalf("got %q want 主技能兜底", got)
		}
	})

	t.Run("空列表", func(t *testing.T) {
		t.Parallel()
		if expertPrimarySkillName(nil, nil) != "" {
			t.Fatal("want empty")
		}
	})
}

func TestGroupUserSkillsByUserID(t *testing.T) {
	t.Parallel()
	a := &model.UserSkill{UserID: 1, SkillID: 1}
	b := &model.UserSkill{UserID: 2, SkillID: 2}
	c := &model.UserSkill{UserID: 1, SkillID: 3}
	m := groupUserSkillsByUserID([]*model.UserSkill{a, b, c, nil})
	if len(m[1]) != 2 || len(m[2]) != 1 {
		t.Fatalf("unexpected grouping: %#v", m)
	}
}

func TestSkillIDsMissingPreloadedName(t *testing.T) {
	t.Parallel()
	skills := []*model.UserSkill{
		{SkillID: 1, Skill: model.Skill{Name: "A"}},
		{SkillID: 2, Skill: model.Skill{}},
		{SkillID: 2, Skill: model.Skill{}},
		nil,
	}
	ids := skillIDsMissingPreloadedName(skills)
	if len(ids) != 1 || ids[0] != 2 {
		t.Fatalf("got %v want [2]", ids)
	}
}
