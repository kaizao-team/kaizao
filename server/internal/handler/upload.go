package handler

import (
	"net/http"
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
	uploadService  *service.UploadService
	publicBaseURL  string // 配置项，用于拼接相对资源 URL，禁止用请求 Host
	log            *zap.Logger
}

// NewUploadHandler 创建上传处理器；publicBaseURL 为 server.public_base_url（无尾斜杠）
func NewUploadHandler(uploadService *service.UploadService, publicBaseURL string, log *zap.Logger) *UploadHandler {
	return &UploadHandler{uploadService: uploadService, publicBaseURL: strings.TrimRight(strings.TrimSpace(publicBaseURL), "/"), log: log}
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
		if code == errcode.ErrObjectUploadFailed {
			response.Error(c, http.StatusInternalServerError, code, errcode.GetMessage(code))
			return
		}
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
		if h.publicBaseURL != "" && strings.HasPrefix(url, "/") {
			url = h.publicBaseURL + url
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
