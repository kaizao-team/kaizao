package objectstore

import (
	"context"
	"fmt"
	"io"
	"net/url"
	"path"
	"strings"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
	"github.com/vibebuild/server/internal/config"
	"go.uber.org/zap"
)

// Client MinIO / S3 兼容对象存储客户端
type Client struct {
	enabled bool
	mc      *minio.Client
	bucket  string
	baseURL string
	maxMB   int
	log     *zap.Logger
}

// New 根据配置创建客户端；enabled=false 时不连接远端，上传接口会报错由上层转换
func New(cfg config.OSSConfig, log *zap.Logger) (*Client, error) {
	maxMB := cfg.MaxUploadMB
	if maxMB <= 0 {
		maxMB = 32
	}
	c := &Client{
		enabled: cfg.Enabled && cfg.Endpoint != "" && cfg.BucketName != "" &&
			cfg.AccessKeyID != "" && cfg.AccessKeySecret != "",
		bucket:  cfg.BucketName,
		baseURL: strings.TrimRight(cfg.BaseURL, "/"),
		maxMB:   maxMB,
		log:     log,
	}
	if !c.enabled {
		if cfg.Enabled {
			log.Warn("oss.enabled=true 但 endpoint/bucket/ak/sk 不完整，对象存储已禁用")
		}
		return c, nil
	}

	endpoint := stripScheme(cfg.Endpoint)
	opts := &minio.Options{
		Creds:  credentials.NewStaticV4(cfg.AccessKeyID, cfg.AccessKeySecret, ""),
		Secure: cfg.UseSSL,
	}
	if cfg.Region != "" {
		opts.Region = cfg.Region
	}

	mc, err := minio.New(endpoint, opts)
	if err != nil {
		return nil, fmt.Errorf("minio client: %w", err)
	}
	c.mc = mc

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	exists, err := mc.BucketExists(ctx, c.bucket)
	if err != nil {
		return nil, fmt.Errorf("minio bucket check: %w", err)
	}
	if !exists {
		if err := mc.MakeBucket(ctx, c.bucket, minio.MakeBucketOptions{Region: cfg.Region}); err != nil {
			return nil, fmt.Errorf("minio make bucket: %w", err)
		}
		log.Info("minio bucket created", zap.String("bucket", c.bucket))
	}

	log.Info("object storage ready", zap.String("endpoint", endpoint), zap.String("bucket", c.bucket))
	return c, nil
}

func stripScheme(raw string) string {
	s := strings.TrimSpace(raw)
	if s == "" {
		return ""
	}
	if strings.Contains(s, "://") {
		if u, err := url.Parse(s); err == nil && u.Host != "" {
			return u.Host
		}
	}
	return s
}

// Enabled 是否已连接对象存储
func (c *Client) Enabled() bool {
	return c != nil && c.enabled && c.mc != nil
}

// Bucket 当前桶名
func (c *Client) Bucket() string {
	if c == nil {
		return ""
	}
	return c.bucket
}

// MaxUploadBytes 单文件上限
func (c *Client) MaxUploadBytes() int64 {
	if c == nil || c.maxMB <= 0 {
		return 32 << 20
	}
	return int64(c.maxMB) << 20
}

// Upload 写入对象；objectKey 建议 teams/{teamUUID}/...
func (c *Client) Upload(ctx context.Context, objectKey string, r io.Reader, size int64, contentType string) error {
	if !c.Enabled() {
		return ErrDisabled
	}
	if contentType == "" {
		contentType = "application/octet-stream"
	}
	_, err := c.mc.PutObject(ctx, c.bucket, objectKey, r, size, minio.PutObjectOptions{ContentType: contentType})
	return err
}

// PresignedGetURL 短时 GET 链接（私有桶下载/预览）
func (c *Client) PresignedGetURL(ctx context.Context, objectKey string, expiry time.Duration) (string, error) {
	if !c.Enabled() {
		return "", ErrDisabled
	}
	if expiry <= 0 {
		expiry = 15 * time.Minute
	}
	key := strings.TrimLeft(objectKey, "/")
	u, err := c.mc.PresignedGetObject(ctx, c.bucket, key, expiry, nil)
	if err != nil {
		return "", err
	}
	return u.String(), nil
}

// PublicURL 对外访问 URL（依赖 base_url 配置；未配置时返回 path 形式）
func (c *Client) PublicURL(objectKey string) string {
	if c == nil {
		return objectKey
	}
	key := strings.TrimLeft(objectKey, "/")
	if c.baseURL != "" {
		return c.baseURL + "/" + key
	}
	return "/" + key
}

// SanitizeFileName 仅保留文件名段，防止路径穿越
func SanitizeFileName(name string) string {
	base := path.Base(strings.TrimSpace(name))
	if base == "." || base == "/" {
		return "file"
	}
	return base
}
