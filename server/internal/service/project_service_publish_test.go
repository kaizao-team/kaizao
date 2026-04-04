package service

import (
	"strings"
	"testing"
	"unicode/utf8"
)

func TestNormalizePublishCategory(t *testing.T) {
	t.Parallel()
	cases := []struct {
		in   string
		want string
	}{
		{"", "dev"},
		{"  DEV  ", "dev"},
		{"design", "visual"},
		{"Visual", "visual"},
		{"data", "data"},
		{"solution", "solution"},
		{"web", "dev"},
		{"unknown", "dev"},
	}
	for _, tc := range cases {
		t.Run(tc.in, func(t *testing.T) {
			t.Parallel()
			if got := normalizePublishCategory(tc.in); got != tc.want {
				t.Fatalf("normalizePublishCategory(%q)=%q want %q", tc.in, got, tc.want)
			}
		})
	}
}

func TestEnsurePublishTitle(t *testing.T) {
	t.Parallel()
	t.Run("长标题截断到200字符", func(t *testing.T) {
		t.Parallel()
		long := strings.Repeat("测", 300)
		got := ensurePublishTitle(long, "dev")
		if utf8.RuneCountInString(got) != 200 {
			t.Fatalf("rune count=%d want 200", utf8.RuneCountInString(got))
		}
	})
	t.Run("短标题用分类补全", func(t *testing.T) {
		t.Parallel()
		got := ensurePublishTitle("短", "design")
		if utf8.RuneCountInString(got) < 5 {
			t.Fatalf("got %q len=%d", got, utf8.RuneCountInString(got))
		}
		if !strings.Contains(got, "visual") {
			t.Fatalf("got %q want substring visual", got)
		}
	})
	t.Run("合法标题原样保留", func(t *testing.T) {
		t.Parallel()
		want := "这是五个字标题"
		if got := ensurePublishTitle(want, "dev"); got != want {
			t.Fatalf("got %q want %q", got, want)
		}
	})
}

func TestEnsurePublishDescription(t *testing.T) {
	t.Parallel()
	t.Run("空描述用模板", func(t *testing.T) {
		t.Parallel()
		got := ensurePublishDescription("")
		if utf8.RuneCountInString(got) < 20 {
			t.Fatalf("len=%d", utf8.RuneCountInString(got))
		}
	})
	t.Run("短描述补齐", func(t *testing.T) {
		t.Parallel()
		got := ensurePublishDescription("短")
		if utf8.RuneCountInString(got) < 20 {
			t.Fatalf("len=%d", utf8.RuneCountInString(got))
		}
	})
	t.Run("长描述不变", func(t *testing.T) {
		t.Parallel()
		want := strings.Repeat("描", 25)
		if got := ensurePublishDescription(want); got != want {
			t.Fatalf("got %q want %q", got, want)
		}
	})
}

func TestTruncateRunes(t *testing.T) {
	t.Parallel()
	s := "你好世界"
	got := truncateRunes(s, 2)
	if got != "你好" {
		t.Fatalf("got %q", got)
	}
}
