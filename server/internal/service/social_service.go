package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"mime"
	"path"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/vibebuild/server/internal/model"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/objectstore"
	"github.com/vibebuild/server/internal/repository"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

type ReviewService struct {
	repos *repository.Repositories
	log   *zap.Logger
}

func NewReviewService(repos *repository.Repositories, log *zap.Logger) *ReviewService {
	return &ReviewService{repos: repos, log: log}
}

type CreateReviewReq struct {
	ProjectUUID   string
	ReviewerUUID  string
	RevieweeUUID  string
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
	store *objectstore.Client
	log   *zap.Logger
}

func NewTeamService(repos *repository.Repositories, store *objectstore.Client, log *zap.Logger) *TeamService {
	return &TeamService{repos: repos, store: store, log: log}
}

type TeamPostItem struct {
	ID              string                   `json:"id"`
	ProjectName     string                   `json:"project_name"`
	ProjectID       string                   `json:"project_id"`
	Creator         map[string]interface{}   `json:"creator"`
	NeededRoles     []map[string]interface{} `json:"needed_roles"`
	Description     string                   `json:"description"`
	FilledCount     int                      `json:"filled_count"`
	TotalCount      int                      `json:"total_count"`
	IsAIRecommended bool                     `json:"is_ai_recommended"`
	MatchScore      int                      `json:"match_score"`
	Status          string                   `json:"status"`
	CreatedAt       time.Time                `json:"created_at"`
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

// CreateTeam 创建团队，当前用户为队长。
// role 非 2/3 时自动提升为专家（role=2）；已有主团队则拒绝。
// 唯一性检查在事务内执行，避免并发重复创建。
func (s *TeamService) CreateTeam(userUUID string, name *string, hourlyRate *float64, availableStatus *int, budgetMin, budgetMax *float64, description *string, inviteCode *string, serviceDirections []string, selfRating *int) (*model.Team, error) {
	u, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrUserNotFound)
	}
	if budgetMin != nil && budgetMax != nil && *budgetMax < *budgetMin {
		return nil, fmt.Errorf("%d", errcode.ErrBudgetRangeInvalid)
	}

	needRoleUpgrade := u.Role != 2 && u.Role != 3 && u.Role < 9

	teamName := ""
	if name != nil && strings.TrimSpace(*name) != "" {
		teamName = truncateRunes(strings.TrimSpace(*name), 100)
	} else {
		base := strings.TrimSpace(u.Nickname)
		if base == "" {
			base = "用户"
		}
		teamName = truncateRunes(base+"的团队", 100)
	}

	avail := int16(1)
	if availableStatus != nil {
		avail = int16(*availableStatus)
	}

	hasInviteCode := inviteCode != nil && strings.TrimSpace(*inviteCode) != ""

	t := &model.Team{
		Name:            teamName,
		LeaderID:        u.ID,
		AvatarURL:       u.AvatarURL,
		TeamType:        1,
		SkillsCoverage:  model.JSON([]byte("[]")),
		MemberCount:     1,
		Status:          1,
		ApprovalStatus:  model.TeamApprovalPending,
		HourlyRate:      hourlyRate,
		AvailableStatus: avail,
		BudgetMin:       budgetMin,
		BudgetMax:       budgetMax,
	}
	if description != nil {
		t.Description = description
	}
	if len(serviceDirections) > 0 {
		raw, _ := json.Marshal(serviceDirections)
		t.ServiceDirections = model.JSON(raw)
	}
	if selfRating != nil && *selfRating >= 1 && *selfRating <= 5 {
		level, power := mapSelfRatingToVibe(*selfRating)
		t.VibeLevel = level
		t.VibePower = power
	}

	if err := s.repos.DB().Transaction(func(tx *gorm.DB) error {
		txRepos := repository.NewRepositories(tx)
		existing, _ := txRepos.Team.FindPrimaryTeamForUser(u.ID)
		if existing != nil {
			return fmt.Errorf("%d", errcode.ErrTeamAlreadyExists)
		}
		if needRoleUpgrade {
			if err := txRepos.User.UpdateFields(u.ID, map[string]interface{}{"role": 2}); err != nil {
				return err
			}
		}
		if hasInviteCode {
			consumed, cerr := txRepos.InviteCode.ConsumeWithTx(tx, strings.TrimSpace(*inviteCode))
			if cerr != nil {
				return cerr
			}
			t.ApprovalStatus = model.TeamApprovalApproved
			// 创建团队后回填 team_id 到邀请码记录，便于追溯
			defer func() {
				if t.ID > 0 {
					tx.Model(&model.InviteCode{}).Where("id = ?", consumed.ID).Update("team_id", t.ID)
				}
			}()
		}
		if err := txRepos.Team.Create(t); err != nil {
			return err
		}
		member := &model.TeamMember{
			TeamID:     t.ID,
			UserID:     u.ID,
			RoleInTeam: "队长",
			SplitRatio: 100,
			Status:     1,
		}
		return txRepos.Team.CreateMember(member)
	}); err != nil {
		return nil, err
	}

	return t, nil
}

// LeaderSkillNames returns the skill display names for the given leader user ID.
func (s *TeamService) LeaderSkillNames(leaderID int64) []string {
	skills, err := s.repos.User.ListUserSkills(leaderID)
	if err != nil || len(skills) == 0 {
		return []string{}
	}
	names := make([]string, 0, len(skills))
	for _, sk := range skills {
		if sk.Skill.Name != "" {
			names = append(names, sk.Skill.Name)
		}
	}
	return names
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

// UploadTeamStaticAsset 团队成员上传静态文件：二进制写入 MinIO，元数据写入 team_static_assets
func (s *TeamService) UploadTeamStaticAsset(ctx context.Context, teamUUID, userUUID, purpose, filename string, size int64, contentType string, src io.Reader) (*model.TeamStaticAsset, error) {
	if s.store == nil || !s.store.Enabled() {
		return nil, fmt.Errorf("%d", errcode.ErrObjectStorageDisabled)
	}
	if size <= 0 || size > s.store.MaxUploadBytes() {
		return nil, fmt.Errorf("%d", errcode.ErrUploadFileTooLarge)
	}
	team, err := s.repos.Team.FindByUUID(teamUUID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("%d", errcode.ErrTeamNotFound)
		}
		return nil, err
	}
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return nil, err
	}
	if !s.isTeamUploader(team, user.ID) {
		return nil, fmt.Errorf("%d", errcode.ErrTeamFileForbidden)
	}
	if size <= 0 {
		return nil, fmt.Errorf("%d", errcode.ErrUploadEmptyFile)
	}
	safeName := objectstore.SanitizeFileName(filename)
	objectUUID := uuid.New().String()
	objectKey := fmt.Sprintf("teams/%s/%s-%s", teamUUID, objectUUID, safeName)
	ct := contentType
	if ct == "" {
		ct = mime.TypeByExtension(path.Ext(safeName))
	}
	if ct == "" {
		ct = "application/octet-stream"
	}
	if err := s.store.Upload(ctx, objectKey, src, size, ct); err != nil {
		s.log.Error("object upload failed", zap.Error(err), zap.String("key", objectKey))
		return nil, fmt.Errorf("%d", errcode.ErrObjectUploadFailed)
	}
	if purpose == "" {
		purpose = "content"
	}
	rec := &model.TeamStaticAsset{
		TeamID:           team.ID,
		UploadedByUserID: user.ID,
		Bucket:           s.store.Bucket(),
		ObjectKey:        objectKey,
		OriginalName:     safeName,
		ContentType:      ct,
		SizeBytes:        size,
		Purpose:          purpose,
		Storage:          "minio",
	}
	if err := s.repos.TeamStaticAsset.Create(rec); err != nil {
		return nil, err
	}
	return rec, nil
}

// ListTeamStaticAssets 团队成员分页查看本团队已登记静态文件元数据
func (s *TeamService) ListTeamStaticAssets(teamUUID, userUUID string, page, pageSize int) ([]*model.TeamStaticAsset, int64, error) {
	team, err := s.repos.Team.FindByUUID(teamUUID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, 0, fmt.Errorf("%d", errcode.ErrTeamNotFound)
		}
		return nil, 0, err
	}
	user, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return nil, 0, err
	}
	if !s.isTeamUploader(team, user.ID) {
		return nil, 0, fmt.Errorf("%d", errcode.ErrTeamFileForbidden)
	}
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	off := (page - 1) * pageSize
	return s.repos.TeamStaticAsset.ListByTeamID(team.ID, off, pageSize)
}

func (s *TeamService) isTeamUploader(team *model.Team, userID int64) bool {
	if team.LeaderID == userID {
		return true
	}
	_, err := s.repos.Team.FindMember(team.ID, userID)
	return err == nil
}

// StaticAssetPublicURL 根据 object_key 拼接对外访问地址（依赖 oss.base_url）
func (s *TeamService) StaticAssetPublicURL(objectKey string) string {
	if s.store == nil {
		return ""
	}
	return s.store.PublicURL(objectKey)
}

// mapSelfRatingToVibe maps user self-rating (1-5) to vibe_level and vibe_power.
// Power is set to the midpoint of each level's range.
func mapSelfRatingToVibe(selfRating int) (string, int) {
	switch selfRating {
	case 1:
		return "vc-T1", 50
	case 2:
		return "vc-T2", 150
	case 3:
		return "vc-T3", 275
	case 4:
		return "vc-T4", 450
	case 5:
		return "vc-T5", 650
	default:
		return "vc-T1", 0
	}
}
