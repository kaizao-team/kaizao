package service

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/vibebuild/server/internal/config"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/objectstore"
	"go.uber.org/zap"
)

var allowedImageContentTypes = map[string]struct{}{
	"image/jpeg": {},
	"image/png":  {},
	"image/gif":  {},
	"image/webp": {},
}

// UploadService 通用文件上传（图片），OSS 优先，未启用时可落本地目录
type UploadService struct {
	store *objectstore.Client
	cfg   *config.OSSConfig
	log   *zap.Logger
}

// NewUploadService 创建上传服务
func NewUploadService(store *objectstore.Client, cfg *config.Config, log *zap.Logger) *UploadService {
	return &UploadService{store: store, cfg: &cfg.OSS, log: log}
}

func (s *UploadService) maxBytes() int64 {
	if s.store != nil && s.store.Enabled() {
		return s.store.MaxUploadBytes()
	}
	mb := s.cfg.MaxUploadMB
	if mb <= 0 {
		mb = 32
	}
	return int64(mb) << 20
}

// UploadImageResult 上传结果
type UploadImageResult struct {
	ObjectKey   string
	URL         string
	ContentType string
	SizeBytes   int64
	Purpose     string
}

// UploadImage multipart 图片：校验类型与大小，写入 OSS 或本地
func (s *UploadService) UploadImage(ctx context.Context, userUUID, purpose, filename string, declaredSize int64, src io.Reader) (*UploadImageResult, error) {
	userUUID = strings.TrimSpace(userUUID)
	if userUUID == "" {
		return nil, fmt.Errorf("%d", errcode.ErrUserNotFound)
	}
	maxB := s.maxBytes()
	if declaredSize > maxB {
		return nil, fmt.Errorf("%d", errcode.ErrUploadFileTooLarge)
	}

	full, err := io.ReadAll(io.LimitReader(src, maxB+1))
	if err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrObjectUploadFailed)
	}
	if len(full) == 0 {
		return nil, fmt.Errorf("%d", errcode.ErrUploadEmptyFile)
	}
	if int64(len(full)) > maxB {
		return nil, fmt.Errorf("%d", errcode.ErrUploadFileTooLarge)
	}
	sniff := full
	if len(sniff) > 512 {
		sniff = sniff[:512]
	}
	ct := normalizeImageContentType(http.DetectContentType(sniff))
	if _, ok := allowedImageContentTypes[ct]; !ok {
		return nil, fmt.Errorf("%d", errcode.ErrUploadInvalidFileType)
	}

	safe := objectstore.SanitizeFileName(filename)
	if safe == "" || safe == "file" {
		safe = "image"
	}
	var rnd [8]byte
	if _, err := rand.Read(rnd[:]); err != nil {
		return nil, fmt.Errorf("%d", errcode.ErrObjectUploadFailed)
	}
	objectKey := fmt.Sprintf("uploads/%s/%d_%s_%s", userUUID, time.Now().UnixNano(), hex.EncodeToString(rnd[:]), safe)

	sz := int64(len(full))

	if s.store != nil && s.store.Enabled() {
		if err := s.store.Upload(ctx, objectKey, bytes.NewReader(full), sz, ct); err != nil {
			s.log.Error("upload oss", zap.Error(err), zap.String("key", objectKey))
			return nil, fmt.Errorf("%d", errcode.ErrObjectUploadFailed)
		}
		return &UploadImageResult{
			ObjectKey: objectKey, URL: s.store.PublicURL(objectKey), ContentType: ct, SizeBytes: sz, Purpose: strings.TrimSpace(purpose),
		}, nil
	}

	root := strings.TrimSpace(s.cfg.LocalUploadDir)
	if root == "" {
		return nil, fmt.Errorf("%d", errcode.ErrObjectStorageDisabled)
	}

	written, err := s.saveLocal(objectKey, root, bytes.NewReader(full))
	if err != nil {
		return nil, err
	}
	if written != sz {
		return nil, fmt.Errorf("%d", errcode.ErrObjectUploadFailed)
	}
	prefix := strings.TrimSpace(s.cfg.LocalURLPath)
	if prefix == "" {
		prefix = "/api/v1/upload-files"
	}
	prefix = strings.TrimRight(prefix, "/")
	publicPath := prefix + "/" + strings.TrimLeft(objectKey, "/")
	return &UploadImageResult{
		ObjectKey: objectKey, URL: publicPath, ContentType: ct, SizeBytes: written, Purpose: strings.TrimSpace(purpose),
	}, nil
}

func normalizeImageContentType(ct string) string {
	ct = strings.TrimSpace(strings.Split(ct, ";")[0])
	if ct == "image/jpg" {
		return "image/jpeg"
	}
	return ct
}

func (s *UploadService) saveLocal(objectKey, root string, r io.Reader) (int64, error) {
	rootAbs, err := filepath.Abs(filepath.Clean(root))
	if err != nil {
		return 0, fmt.Errorf("%d", errcode.ErrObjectUploadFailed)
	}
	full := filepath.Join(rootAbs, filepath.FromSlash(objectKey))
	fullAbs, err := filepath.Abs(filepath.Clean(full))
	if err != nil {
		return 0, fmt.Errorf("%d", errcode.ErrObjectUploadFailed)
	}
	sep := string(os.PathSeparator)
	if fullAbs != rootAbs && !strings.HasPrefix(fullAbs, rootAbs+sep) {
		return 0, fmt.Errorf("%d", errcode.ErrObjectUploadFailed)
	}
	if err := os.MkdirAll(filepath.Dir(fullAbs), 0o755); err != nil {
		s.log.Error("upload local mkdir", zap.Error(err))
		return 0, fmt.Errorf("%d", errcode.ErrObjectUploadFailed)
	}
	f, err := os.Create(fullAbs)
	if err != nil {
		s.log.Error("upload local create", zap.Error(err))
		return 0, fmt.Errorf("%d", errcode.ErrObjectUploadFailed)
	}
	defer f.Close()
	written, err := io.Copy(f, r)
	if err != nil {
		_ = os.Remove(fullAbs)
		s.log.Error("upload local write", zap.Error(err))
		return 0, fmt.Errorf("%d", errcode.ErrObjectUploadFailed)
	}
	return written, nil
}
