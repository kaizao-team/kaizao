package service

import (
	"strconv"
	"strings"
	"testing"
	"unicode/utf8"

	"github.com/vibebuild/server/internal/pkg/errcode"
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

// PublishDraft 主流程中的状态门（与 handler Publish 的 strconv.Atoi 解析一致）
func TestErrPublishDraftForStatus(t *testing.T) {
	t.Parallel()
	if err := errPublishDraftForStatus(1); err != nil {
		t.Fatalf("status=1: %v", err)
	}
	err4 := errPublishDraftForStatus(4)
	if err4 == nil {
		t.Fatal("status=4 want error")
	}
	code4, _ := strconv.Atoi(err4.Error())
	if code4 != errcode.ErrProjectAlreadyClosed {
		t.Fatalf("status=4 code=%d want %d", code4, errcode.ErrProjectAlreadyClosed)
	}
	err3 := errPublishDraftForStatus(3)
	if err3 == nil {
		t.Fatal("status=3 want error")
	}
	code3, _ := strconv.Atoi(err3.Error())
	if code3 != errcode.ErrProjectStatusInvalid {
		t.Fatalf("status=3 code=%d want %d", code3, errcode.ErrProjectStatusInvalid)
	}
}
