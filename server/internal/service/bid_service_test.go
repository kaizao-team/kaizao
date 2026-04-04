package service

import (
	"testing"

	"github.com/vibebuild/server/internal/model"
)

func TestNotificationTypeNewBidValue(t *testing.T) {
	t.Parallel()
	if model.NotificationTypeNewBid != 23 {
		t.Fatalf("NotificationTypeNewBid=%d, want 23 (API 与集成测试 type=23 一致)", model.NotificationTypeNewBid)
	}
}

func TestFormatNewBidNotificationContent(t *testing.T) {
	t.Parallel()
	t.Run("整数金额", func(t *testing.T) {
		t.Parallel()
		got := formatNewBidNotificationContent("专家甲", "某项目", 8000)
		want := "「专家甲」对您的项目「某项目」提交了投标，报价 \u00a58000.00"
		if got != want {
			t.Fatalf("got %q want %q", got, want)
		}
	})
	t.Run("小数金额", func(t *testing.T) {
		t.Parallel()
		got := formatNewBidNotificationContent("U", "P", 123.4)
		want := "「U」对您的项目「P」提交了投标，报价 \u00a5123.40"
		if got != want {
			t.Fatalf("got %q want %q", got, want)
		}
	})
}
