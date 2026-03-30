package middleware

import (
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/pkg/errcode"
	jwtpkg "github.com/vibebuild/server/internal/pkg/jwt"
	"github.com/vibebuild/server/internal/pkg/response"
	"github.com/vibebuild/server/internal/service"
)

// JWTAuth JWT 认证中间件
func JWTAuth(jwtManager *jwtpkg.Manager) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			response.ErrorUnauthorized(c, errcode.ErrTokenInvalid, "缺少认证信息")
			c.Abort()
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			response.ErrorUnauthorized(c, errcode.ErrTokenInvalid, "认证格式错误")
			c.Abort()
			return
		}

		claims, err := jwtManager.ParseToken(parts[1])
		if err != nil {
			if err == jwtpkg.ErrTokenExpired {
				response.ErrorUnauthorized(c, errcode.ErrTokenExpired, "Token已过期")
			} else {
				response.ErrorUnauthorized(c, errcode.ErrTokenInvalid, "Token无效")
			}
			c.Abort()
			return
		}

		// 将用户信息写入上下文
		c.Set("user_uuid", claims.UserUUID)
		c.Set("user_role", claims.Role)
		c.Set("device", claims.Device)
		c.Set("token_id", claims.ID)

		c.Next()
	}
}

// OptionalJWTAuth 可选 JWT 认证（不强制登录，但如果携带 Token 则解析）
func OptionalJWTAuth(jwtManager *jwtpkg.Manager) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.Next()
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.Next()
			return
		}

		claims, err := jwtManager.ParseToken(parts[1])
		if err == nil {
			c.Set("user_uuid", claims.UserUUID)
			c.Set("user_role", claims.Role)
		}

		c.Next()
	}
}

// AdminAuth 管理员权限（需在 JWTAuth 之后；以数据库 users.role=9 为准，避免 JWT 内角色过期）
func AdminAuth(services *service.Services) gin.HandlerFunc {
	return func(c *gin.Context) {
		uuid := c.GetString("user_uuid")
		if uuid == "" {
			response.ErrorForbidden(c, errcode.ErrNoAdminPermission, "无管理员权限")
			c.Abort()
			return
		}
		u, err := services.User.GetByUUID(uuid)
		if err != nil || u.Role != 9 {
			response.ErrorForbidden(c, errcode.ErrNoAdminPermission, "无管理员权限")
			c.Abort()
			return
		}
		c.Next()
	}
}
