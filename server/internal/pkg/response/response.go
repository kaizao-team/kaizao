package response

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Response 统一响应结构
type Response struct {
	Code      int         `json:"code"`
	Message   string      `json:"message"`
	Data      interface{} `json:"data,omitempty"`
	Meta      *Meta       `json:"meta,omitempty"`
	RequestID string      `json:"request_id"`
}

// Meta 分页信息
type Meta struct {
	Page       int   `json:"page"`
	PageSize   int   `json:"page_size"`
	Total      int64 `json:"total"`
	TotalPages int   `json:"total_pages"`
}

// getRequestID 从 Gin 上下文获取请求 ID
func getRequestID(c *gin.Context) string {
	if id := c.GetString("request_id"); id != "" {
		return id
	}
	return c.GetHeader("X-Request-ID")
}

// Success 成功响应（无分页）
func Success(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Code:      0,
		Message:   "success",
		Data:      data,
		RequestID: getRequestID(c),
	})
}

// SuccessMsg 成功响应（自定义消息）
func SuccessMsg(c *gin.Context, message string, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Code:      0,
		Message:   message,
		Data:      data,
		RequestID: getRequestID(c),
	})
}

// SuccessWithMeta 成功响应（带分页）
func SuccessWithMeta(c *gin.Context, data interface{}, meta *Meta) {
	c.JSON(http.StatusOK, Response{
		Code:      0,
		Message:   "success",
		Data:      data,
		Meta:      meta,
		RequestID: getRequestID(c),
	})
}

// Error 错误响应
func Error(c *gin.Context, httpStatus int, code int, message string) {
	c.JSON(httpStatus, Response{
		Code:      code,
		Message:   message,
		Data:      nil,
		RequestID: getRequestID(c),
	})
}

// ErrorBadRequest 400 错误
func ErrorBadRequest(c *gin.Context, code int, message string) {
	Error(c, http.StatusBadRequest, code, message)
}

// ErrorUnauthorized 401 错误
func ErrorUnauthorized(c *gin.Context, code int, message string) {
	Error(c, http.StatusUnauthorized, code, message)
}

// ErrorForbidden 403 错误
func ErrorForbidden(c *gin.Context, code int, message string) {
	Error(c, http.StatusForbidden, code, message)
}

// ErrorNotFound 404 错误
func ErrorNotFound(c *gin.Context, code int, message string) {
	Error(c, http.StatusNotFound, code, message)
}

// ErrorTooManyRequests 429 错误
func ErrorTooManyRequests(c *gin.Context, retryAfter int) {
	c.JSON(http.StatusTooManyRequests, Response{
		Code:      429,
		Message:   "请求过于频繁，请稍后重试",
		Data:      map[string]int{"retry_after": retryAfter},
		RequestID: getRequestID(c),
	})
}

// ErrorInternal 500 错误
func ErrorInternal(c *gin.Context, message string) {
	Error(c, http.StatusInternalServerError, 500, message)
}

// BuildMeta 构造分页 Meta
func BuildMeta(page, pageSize int, total int64) *Meta {
	totalPages := int(total) / pageSize
	if int(total)%pageSize > 0 {
		totalPages++
	}
	return &Meta{
		Page:       page,
		PageSize:   pageSize,
		Total:      total,
		TotalPages: totalPages,
	}
}
