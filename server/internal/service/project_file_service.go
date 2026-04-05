package service

import (
	"context"
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

const projectFilePresignExpiry = 15 * time.Minute

var allowedProjectFileKinds = map[string]struct{}{
	"reference":   {},
	"process":     {},
	"deliverable": {},
}

// ProjectFileService 项目共享文件
type ProjectFileService struct {
	repos *repository.Repositories
	store *objectstore.Client
	log   *zap.Logger
}

// NewProjectFileService 创建服务
func NewProjectFileService(repos *repository.Repositories, store *objectstore.Client, log *zap.Logger) *ProjectFileService {
	return &ProjectFileService{repos: repos, store: store, log: log}
}

// ProjectFileItem 列表/详情返回项
type ProjectFileItem struct {
	UUID               string    `json:"uuid"`
	FileKind           string    `json:"file_kind"`
	OriginalName       string    `json:"original_name"`
	ContentType        string    `json:"content_type"`
	SizeBytes          int64     `json:"size_bytes"`
	MilestoneID        *string   `json:"milestone_id,omitempty"`
	UploadedByUserID   string    `json:"uploaded_by_user_id"`
	UploadedByNickname string    `json:"uploaded_by_nickname"`
	CreatedAt          time.Time `json:"created_at"`
	DownloadURL        string    `json:"download_url,omitempty"`
}

// ProjectFileListQuery 列表筛选
type ProjectFileListQuery struct {
	FileKind          string
	MilestoneUUID     string
	Page              int
	PageSize          int
	IncludePresignURL bool
}

func (s *ProjectFileService) ensureFileAccess(projectUUID, userUUID string) (*model.Project, *model.User, error) {
	u, err := s.repos.User.FindByUUID(userUUID)
	if err != nil {
		return nil, nil, fmt.Errorf("%d", errcode.ErrUserNotFound)
	}
	p, err := s.repos.Project.FindByUUID(projectUUID)
	if err != nil {
		return nil, nil, fmt.Errorf("%d", errcode.ErrProjectNotFound)
	}
	if !CanAccessProjectWorkspace(p, u.ID, s.repos) {
		return nil, nil, fmt.Errorf("%d", errcode.ErrProjectParticipantOnly)
	}
	return p, u, nil
}

func normalizeFileKind(kind string) string {
	k := strings.TrimSpace(strings.ToLower(kind))
	if k == "" {
		return "process"
	}
	return k
}

func validateFileKind(kind string) error {
	if _, ok := allowedProjectFileKinds[kind]; !ok {
		return fmt.Errorf("%d", errcode.ErrProjectFileKindInvalid)
	}
	return nil
}

func (s *ProjectFileService) toItem(ctx context.Context, f *model.ProjectFile, withURL bool) (ProjectFileItem, error) {
	item := ProjectFileItem{
		UUID:         f.UUID,
		FileKind:     f.FileKind,
		OriginalName: f.OriginalName,
		ContentType:  f.ContentType,
		SizeBytes:    f.SizeBytes,
		CreatedAt:    f.CreatedAt,
	}
	if f.MilestoneID != nil {
		ms, err := s.repos.Milestone.FindByID(*f.MilestoneID)
		if err == nil && ms != nil {
			id := ms.UUID
			item.MilestoneID = &id
		}
	}
	if f.Uploader != nil {
		item.UploadedByUserID = f.Uploader.UUID
		item.UploadedByNickname = f.Uploader.Nickname
	} else {
		u, err := s.repos.User.FindByID(f.UploadedByUserID)
		if err == nil && u != nil {
			item.UploadedByUserID = u.UUID
			item.UploadedByNickname = u.Nickname
		}
	}
	if withURL && s.store != nil && s.store.Enabled() {
		u, err := s.store.PresignedGetURL(ctx, f.ObjectKey, projectFilePresignExpiry)
		if err != nil {
			s.log.Warn("presign project file", zap.Error(err), zap.String("key", f.ObjectKey))
		} else {
			item.DownloadURL = u
		}
	}
	return item, nil
}

// List 分页列表
func (s *ProjectFileService) List(ctx context.Context, projectUUID, userUUID string, q ProjectFileListQuery) ([]ProjectFileItem, int64, error) {
	p, _, err := s.ensureFileAccess(projectUUID, userUUID)
	if err != nil {
		return nil, 0, err
	}
	fileKind := ""
	if strings.TrimSpace(q.FileKind) != "" {
		fileKind = normalizeFileKind(q.FileKind)
		if err := validateFileKind(fileKind); err != nil {
			return nil, 0, err
		}
	}
	var milestoneIDPtr *int64
	if strings.TrimSpace(q.MilestoneUUID) != "" {
		ms, err := s.repos.Milestone.FindByUUID(strings.TrimSpace(q.MilestoneUUID))
		if err != nil || ms.ProjectID != p.ID {
			return nil, 0, fmt.Errorf("%d", errcode.ErrMilestoneNotFound)
		}
		milestoneIDPtr = &ms.ID
	}
	page := q.Page
	if page < 1 {
		page = 1
	}
	ps := q.PageSize
	if ps < 1 || ps > 100 {
		ps = 20
	}
	off := (page - 1) * ps
	list, total, err := s.repos.ProjectFile.ListByProjectID(p.ID, fileKind, milestoneIDPtr, off, ps)
	if err != nil {
		return nil, 0, err
	}
	out := make([]ProjectFileItem, 0, len(list))
	for _, f := range list {
		item, err := s.toItem(ctx, f, q.IncludePresignURL)
		if err != nil {
			return nil, 0, err
		}
		out = append(out, item)
	}
	return out, total, nil
}

// Get 单条元数据 + 预签名
func (s *ProjectFileService) Get(ctx context.Context, projectUUID, userUUID, fileUUID string) (ProjectFileItem, error) {
	p, _, err := s.ensureFileAccess(projectUUID, userUUID)
	if err != nil {
		return ProjectFileItem{}, err
	}
	f, err := s.repos.ProjectFile.FindByUUIDAndProjectID(p.ID, fileUUID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ProjectFileItem{}, fmt.Errorf("%d", errcode.ErrProjectFileNotFound)
		}
		return ProjectFileItem{}, err
	}
	item, err := s.toItem(ctx, f, true)
	return item, err
}

// Upload 写入对象存储并落库
func (s *ProjectFileService) Upload(ctx context.Context, projectUUID, userUUID string, fileKind string, milestoneUUID *string, filename string, size int64, contentType string, src io.Reader) (*model.ProjectFile, error) {
	if s.store == nil || !s.store.Enabled() {
		return nil, fmt.Errorf("%d", errcode.ErrObjectStorageDisabled)
	}
	p, u, err := s.ensureFileAccess(projectUUID, userUUID)
	if err != nil {
		return nil, err
	}
	kind := normalizeFileKind(fileKind)
	if err := validateFileKind(kind); err != nil {
		return nil, err
	}
	if size <= 0 {
		return nil, fmt.Errorf("%d", errcode.ErrUploadEmptyFile)
	}
	if size > s.store.MaxUploadBytes() {
		return nil, fmt.Errorf("%d", errcode.ErrUploadFileTooLarge)
	}
	var milestoneID *int64
	if milestoneUUID != nil && strings.TrimSpace(*milestoneUUID) != "" {
		ms, err := s.repos.Milestone.FindByUUID(strings.TrimSpace(*milestoneUUID))
		if err != nil || ms.ProjectID != p.ID {
			return nil, fmt.Errorf("%d", errcode.ErrMilestoneNotFound)
		}
		milestoneID = &ms.ID
	}
	safeName := objectstore.SanitizeFileName(filename)
	objectUUID := uuid.New().String()
	objectKey := fmt.Sprintf("projects/%s/%s-%s", p.UUID, objectUUID, safeName)
	ct := contentType
	if ct == "" {
		ct = mime.TypeByExtension(path.Ext(safeName))
	}
	if ct == "" {
		ct = "application/octet-stream"
	}
	if err := s.store.Upload(ctx, objectKey, src, size, ct); err != nil {
		s.log.Error("project file upload failed", zap.Error(err), zap.String("key", objectKey))
		return nil, fmt.Errorf("%d", errcode.ErrObjectUploadFailed)
	}
	rec := &model.ProjectFile{
		ProjectID:        p.ID,
		UploadedByUserID: u.ID,
		MilestoneID:      milestoneID,
		Bucket:           s.store.Bucket(),
		ObjectKey:        objectKey,
		OriginalName:     safeName,
		ContentType:      ct,
		SizeBytes:        size,
		FileKind:         kind,
		Storage:          "minio",
	}
	if err := s.repos.ProjectFile.Create(rec); err != nil {
		return nil, err
	}
	return s.repos.ProjectFile.FindByUUIDAndProjectID(p.ID, rec.UUID)
}
