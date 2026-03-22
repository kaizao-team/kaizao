package middleware

import (
	"github.com/gin-gonic/gin"
	"github.com/juju/ratelimit"
	"github.com/vibebuild/server/internal/pkg/response"
)

// RateLimit 令牌桶限流中间件
func RateLimit(fillRate float64, capacity int64) gin.HandlerFunc {
	bucket := ratelimit.NewBucketWithRate(fillRate, capacity)
	return func(c *gin.Context) {
		if bucket.TakeAvailable(1) < 1 {
			response.ErrorTooManyRequests(c, 30)
			c.Abort()
			return
		}
		c.Next()
	}
}
