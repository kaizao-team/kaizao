package handler

import (
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/response"
	"github.com/vibebuild/server/internal/service"
	"go.uber.org/zap"
)

// UploadHandler 通用上传
type UploadHandler struct {
	uploadService *service.UploadService
	log           *zap.Logger
}

// NewUploadHandler 创建上传处理器
func NewUploadHandler(uploadService *service.UploadService, log *zap.Logger) *UploadHandler {
	return &UploadHandler{uploadService: uploadService, log: log}
}

// Post POST /api/v1/upload multipart form field "file"，可选 purpose（avatar|portfolio|attachment 等，仅回显）
func (h *UploadHandler) Post(c *gin.Context) {
	fh, err := c.FormFile("file")
	if err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "请选择文件字段 file")
		return
	}
	src, err := fh.Open()
	if err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "无法读取文件")
		return
	}
	defer src.Close()

	purpose := c.PostForm("purpose")
	rec, err := h.uploadService.UploadImage(
		c.Request.Context(),
		c.GetString("user_uuid"),
		purpose,
		fh.Filename,
		fh.Size,
		src,
	)
	if err != nil {
		code, _ := strconv.Atoi(err.Error())
		if code > 0 {
			response.ErrorBadRequest(c, code, errcode.GetMessage(code))
			return
		}
		h.log.Error("upload failed", zap.Error(err))
		response.ErrorInternal(c, "上传失败")
		return
	}

	url := rec.URL
	if url != "" && !strings.HasPrefix(url, "http://") && !strings.HasPrefix(url, "https://") {
		scheme := "http"
		if c.Request.TLS != nil {
			scheme = "https"
		}
		if xf := c.GetHeader("X-Forwarded-Proto"); xf == "https" {
			scheme = "https"
		}
		if strings.HasPrefix(url, "/") {
			url = scheme + "://" + c.Request.Host + url
		}
	}

	response.Success(c, gin.H{
		"url":           url,
		"object_key":    rec.ObjectKey,
		"content_type":  rec.ContentType,
		"size_bytes":    rec.SizeBytes,
		"purpose":       rec.Purpose,
	})
}
