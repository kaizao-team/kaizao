package service

import (
	"testing"

	"github.com/vibebuild/server/internal/pkg/errcode"
)

// TestErrBudgetExpertOnlyMatchesAPI PUT /users/me 预算非专家时业务码与 02-users 规格一致。
func TestErrBudgetExpertOnlyMatchesAPI(t *testing.T) {
	t.Parallel()
	if errcode.ErrBudgetExpertOnly != 11019 {
		t.Fatalf("ErrBudgetExpertOnly=%d, want 11019", errcode.ErrBudgetExpertOnly)
	}
	if errcode.ErrBudgetNoPrimaryTeam != 11020 {
		t.Fatalf("ErrBudgetNoPrimaryTeam=%d, want 11020", errcode.ErrBudgetNoPrimaryTeam)
	}
}
