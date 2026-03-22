package middleware

import (
	"net/http"
	"runtime/debug"

	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/pkg/response"
	"go.uber.org/zap"
)

// Recovery 错误恢复中间件
func Recovery(log *zap.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				log.Error("panic recovered",
					zap.Any("error", err),
					zap.String("stack", string(debug.Stack())),
					zap.String("request_id", c.GetString("request_id")),
					zap.String("path", c.Request.URL.Path),
					zap.String("method", c.Request.Method),
				)
				response.Error(c, http.StatusInternalServerError, 500, "服务器内部错误")
				c.Abort()
			}
		}()
		c.Next()
	}
}
