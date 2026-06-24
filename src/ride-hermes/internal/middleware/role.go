package middleware

import (
	"github.com/gin-gonic/gin"
	"github.com/ridehermes/ride-hermes/internal/common"
)

func RoleMiddleware(allowedRoles ...int8) gin.HandlerFunc {
	return func(c *gin.Context) {
		role, exists := c.Get("role")
		if !exists {
			common.ErrorWithStatus(c, 401, common.CodeUnauthorized, "未登录")
			c.Abort()
			return
		}

		currentRole, ok := role.(int8)
		if !ok {
			common.ErrorWithStatus(c, 403, common.CodeForbidden, "无权限")
			c.Abort()
			return
		}

		for _, r := range allowedRoles {
			if currentRole == r {
				c.Next()
				return
			}
		}

		common.ErrorWithStatus(c, 403, common.CodeForbidden, "无权限")
		c.Abort()
	}
}
