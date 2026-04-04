package service

import (
	"testing"

	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/repository"
)

func TestIsAllowedTaskAssignee_withoutTeam(t *testing.T) {
	var repos *repository.Repositories
	owner := int64(10)
	other := int64(99)
	p := &model.Project{OwnerID: owner}
	if !isAllowedTaskAssignee(p, owner, repos) {
		t.Fatal("owner should be allowed as assignee")
	}
	if isAllowedTaskAssignee(p, other, repos) {
		t.Fatal("unrelated user should not be allowed when project has no team")
	}
	prov := int64(20)
	p2 := &model.Project{OwnerID: owner, ProviderID: &prov}
	if !isAllowedTaskAssignee(p2, prov, repos) {
		t.Fatal("provider should be allowed as assignee")
	}
	if isAllowedTaskAssignee(p2, other, repos) {
		t.Fatal("stranger should not be allowed")
	}
}
