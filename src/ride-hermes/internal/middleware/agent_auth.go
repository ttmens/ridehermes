package middleware

import (
	"context"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/ridehermes/ride-hermes/internal/common"
)

// AgentCredentialInfo is the validated credential returned by the validator.
type AgentCredentialInfo struct {
	ID          int64
	UserID      int64
	AgentName   string
	Permissions []string
}

// AgentKeyValidator validates an API key and returns credential info.
type AgentKeyValidator func(ctx context.Context, apiKey string) (*AgentCredentialInfo, error)

func AgentAuthMiddleware(validate AgentKeyValidator) gin.HandlerFunc {
	return func(c *gin.Context) {
		apiKey := c.GetHeader("X-API-Key")
		userIDStr := c.GetHeader("X-User-ID")

		if apiKey == "" || userIDStr == "" {
			common.ErrorWithStatus(c, 401, common.CodeUnauthorized, "缺少 X-API-Key 或 X-User-ID 请求头")
			c.Abort()
			return
		}

		userID, err := strconv.ParseInt(userIDStr, 10, 64)
		if err != nil {
			common.ErrorWithStatus(c, 401, common.CodeUnauthorized, "X-User-ID 格式错误")
			c.Abort()
			return
		}

		cred, err := validate(c.Request.Context(), apiKey)
		if err != nil {
			common.ErrorWithStatus(c, 401, common.CodeUnauthorized, err.Error())
			c.Abort()
			return
		}

		if cred.UserID != userID {
			common.ErrorWithStatus(c, 401, common.CodeUnauthorized, "API Key 与用户不匹配")
			c.Abort()
			return
		}

		c.Set("user_id", userID)
		c.Set("credential_id", cred.ID)
		c.Set("agent_name", cred.AgentName)
		c.Set("permissions", cred.Permissions)
		c.Set("role", int64(2)) // passenger role
		c.Next()
	}
}
