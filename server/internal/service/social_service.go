package service

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/repository"
	"go.uber.org/zap"
)

type ReviewService struct {
	repos *repository.Repositories
	log   *zap.Logger
}

func NewReviewService(repos *repository.Repositories, log *zap.Logger) *ReviewService {
	return &ReviewService{repos: repos, log: log}
}

type CreateReviewReq struct {
	ProjectUUID  string
	ReviewerUUID string
	RevieweeUUID string
	OverallRating float64
	Dimensions    []map[string]interface{}
	Comment       string
}

func (s *ReviewService) Create(req CreateReviewReq) (*model.Review, error) {
	reviewer, err := s.repos.User.FindByUUID(req.ReviewerUUID)
	if err != nil {
		return nil, err
	}
	reviewee, err := s.repos.User.FindByUUID(req.RevieweeUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrUserNotFound)
	}
	project, err := s.repos.Project.FindByUUID(req.ProjectUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrProjectNotFound)
	}

	existing, _ := s.repos.Review.FindByProjectAndReviewer(project.ID, reviewer.ID)
	if existing != nil {
		return nil, fmt.Errorf("%d", errcode.ErrReviewDuplicate)
	}

	review := &model.Review{
		ProjectID:     project.ID,
		ReviewerID:    reviewer.ID,
		RevieweeID:    reviewee.ID,
		ReviewerRole:  reviewer.Role,
		OverallRating: req.OverallRating,
		Status:        1,
	}
	if req.Comment != "" {
		review.Content = &req.Comment
	}
	if len(req.Dimensions) > 0 {
		for _, d := range req.Dimensions {
			name, _ := d["name"].(string)
			rating, _ := d["rating"].(float64)
			switch name {
			case "代码质量":
				review.QualityRating = &rating
			case "沟通效率":
				review.CommunicationRating = &rating
			case "交付时效":
				review.TimelinessRating = &rating
			}
		}
	}

	if err := s.repos.Review.Create(review); err != nil {
		return nil, err
	}
	return review, nil
}

func (s *ReviewService) ListByProject(projectUUID string) ([]*model.Review, error) {
	project, err := s.repos.Project.FindByUUID(projectUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrProjectNotFound)
	}
	reviews, _, err := s.repos.Review.ListByProjectID(project.ID, 0, 50)
	return reviews, err
}

type TeamService struct {
	repos *repository.Repositories
	log   *zap.Logger
}

func NewTeamService(repos *repository.Repositories, log *zap.Logger) *TeamService {
	return &TeamService{repos: repos, log: log}
}

type TeamPostItem struct {
	ID             string                   `json:"id"`
	ProjectName    string                   `json:"project_name"`
	ProjectID      string                   `json:"project_id"`
	Creator        map[string]interface{}   `json:"creator"`
	NeededRoles    []map[string]interface{} `json:"needed_roles"`
	Description    string                   `json:"description"`
	FilledCount    int                      `json:"filled_count"`
	TotalCount     int                      `json:"total_count"`
	IsAIRecommended bool                   `json:"is_ai_recommended"`
	MatchScore     int                      `json:"match_score"`
	Status         string                   `json:"status"`
	CreatedAt      time.Time                `json:"created_at"`
}

func (s *TeamService) ListTeamPosts(role string) (map[string]interface{}, error) {
	conditions := map[string]interface{}{"status": int16(1)}
	posts, _, err := s.repos.Team.ListPosts(0, 50, conditions)
	if err != nil {
		return nil, err
	}
	items := make([]TeamPostItem, 0, len(posts))
	for _, p := range posts {
		creator := map[string]interface{}{
			"id":       "",
			"nickname": "",
			"avatar":   nil,
		}
		if p.Author != nil {
			creator["id"] = p.Author.UUID
			creator["nickname"] = p.Author.Nickname
			creator["avatar"] = p.Author.AvatarURL
		}
		var neededRoles []map[string]interface{}
		if len(p.NeededRoles) > 0 {
			json.Unmarshal([]byte(p.NeededRoles), &neededRoles)
		}
		if neededRoles == nil {
			neededRoles = []map[string]interface{}{}
		}
		items = append(items, TeamPostItem{
			ID:          p.UUID,
			ProjectName: p.Title,
			Creator:     creator,
			NeededRoles: neededRoles,
			Description: p.Description,
			TotalCount:  len(neededRoles),
			Status:      "recruiting",
			CreatedAt:   p.CreatedAt,
		})
	}
	return map[string]interface{}{
		"ai_recommended": []interface{}{},
		"posts":          items,
	}, nil
}

func (s *TeamService) CreatePost(authorUUID, projectName, description string, neededRoles []map[string]interface{}) (*model.TeamPost, error) {
	author, err := s.repos.User.FindByUUID(authorUUID)
	if err != nil {
		return nil, err
	}
	rolesJSON, _ := json.Marshal(neededRoles)
	post := &model.TeamPost{
		AuthorID:    author.ID,
		Title:       projectName,
		Description: description,
		NeededRoles: model.JSON(rolesJSON),
		Status:      1,
	}
	if err := s.repos.Team.CreatePost(post); err != nil {
		return nil, err
	}
	return post, nil
}

func (s *TeamService) GetDetail(teamUUID string) (*model.Team, error) {
	return s.repos.Team.FindByUUID(teamUUID)
}

func (s *TeamService) UpdateSplitRatio(teamUUID string, ratios []map[string]interface{}) error {
	team, err := s.repos.Team.FindByUUID(teamUUID)
	if err != nil {
		return err
	}
	for _, r := range ratios {
		memberID, _ := r["member_id"].(string)
		ratio, _ := r["ratio"].(float64)
		if memberID == "" {
			continue
		}
		user, err := s.repos.User.FindByUUID(memberID)
		if err != nil {
			continue
		}
		s.repos.Team.UpdateMemberRatio(team.ID, user.ID, ratio)
	}
	return nil
}

func (s *TeamService) Invite(teamUUID, inviterUUID string) error {
	_, err := s.repos.Team.FindByUUID(teamUUID)
	return err
}

func (s *TeamService) RespondInvite(inviteUUID string, accept bool) error {
	invite, err := s.repos.Team.FindInviteByUUID(inviteUUID)
	if err != nil {
		return err
	}
	now := time.Now()
	invite.RespondedAt = &now
	if accept {
		invite.Status = 2
	} else {
		invite.Status = 3
	}
	return s.repos.Team.UpdateInvite(invite)
}
