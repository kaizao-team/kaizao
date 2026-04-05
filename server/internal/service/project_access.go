package service

import (
	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/repository"
)

func isProjectParticipant(p *model.Project, userID int64) bool {
	if p.OwnerID == userID {
		return true
	}
	if p.ProviderID != nil && *p.ProviderID == userID {
		return true
	}
	return false
}

// CanAccessProjectWorkspace 需求方、已选服务方，或项目绑定团队下的成员（与任务可指派范围一致）
func CanAccessProjectWorkspace(p *model.Project, userID int64, repos *repository.Repositories) bool {
	if isProjectParticipant(p, userID) {
		return true
	}
	if p.TeamID != nil {
		_, err := repos.Team.FindMember(*p.TeamID, userID)
		return err == nil
	}
	return false
}
