package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/ridehermes/ride-hermes/internal/common"
)

// PassengerGenerateAgentKey — POST /api/v1/passenger/agent/keys
func (h *Handler) PassengerGenerateAgentKey(c *gin.Context) {
	userID := c.GetInt64("user_id")

	var req struct {
		AgentName string `json:"agent_name" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, common.CodeParamError, "参数错误: agent_name 必填")
		return
	}

	cred, apiKey, err := h.AgentSvc.GenerateAPIKey(c.Request.Context(), uint64(userID), req.AgentName)
	if err != nil {
		common.Error(c, common.CodeInternalError, err.Error())
		return
	}

	common.Success(c, gin.H{
		"api_key":     apiKey,
		"user_id":     cred.UserID,
		"agent_name":  cred.AgentName,
		"permissions": cred.Permissions,
		"created_at":  cred.CreatedAt,
	})
}

// PassengerListAgentKeys — GET /api/v1/passenger/agent/keys
func (h *Handler) PassengerListAgentKeys(c *gin.Context) {
	userID := c.GetInt64("user_id")

	creds, err := h.AgentSvc.ListKeys(c.Request.Context(), uint64(userID))
	if err != nil {
		common.Error(c, common.CodeInternalError, err.Error())
		return
	}

	type item struct {
		ID          int64    `json:"id"`
		AgentName   string   `json:"agent_name"`
		Prefix      string   `json:"prefix"`
		Permissions []string `json:"permissions"`
		RateLimit   int      `json:"rate_limit"`
		Status      int8     `json:"status"`
		LastUsedAt  string   `json:"last_used_at"`
		CreatedAt   string   `json:"created_at"`
	}

	var list []item
	for _, v := range creds {
		lastUsed := ""
		if v.LastUsedAt != nil {
			lastUsed = v.LastUsedAt.Format("2006-01-02 15:04:05")
		}
		// prefix: show first 10 chars of the hash for identification
		prefix := ""
		if len(v.APIKeyHash) >= 10 {
			prefix = "rh_" + v.APIKeyHash[:7] + "..."
		}
		list = append(list, item{
			ID:          v.ID,
			AgentName:   v.AgentName,
			Prefix:      prefix,
			Permissions: []string(v.Permissions),
			RateLimit:   v.RateLimit,
			Status:      v.Status,
			LastUsedAt:  lastUsed,
			CreatedAt:   v.CreatedAt.Format("2006-01-02 15:04:05"),
		})
	}

	common.Success(c, gin.H{"list": list, "total": len(list)})
}

// PassengerRevokeAgentKey — DELETE /api/v1/passenger/agent/keys/:id
func (h *Handler) PassengerRevokeAgentKey(c *gin.Context) {
	userID := c.GetInt64("user_id")
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	// Verify the key belongs to this user before revoking
	creds, err := h.AgentSvc.ListKeys(c.Request.Context(), uint64(userID))
	if err != nil {
		common.Error(c, common.CodeInternalError, err.Error())
		return
	}
	found := false
	for _, v := range creds {
		if uint64(v.ID) == id {
			found = true
			break
		}
	}
	if !found {
		common.Error(c, common.CodeParamError, "该 API Key 不存在或不属于当前用户")
		return
	}

	if err := h.AgentSvc.RevokeKey(c.Request.Context(), id, uint64(userID)); err != nil {
		common.Error(c, common.CodeInternalError, err.Error())
		return
	}
	common.Success(c, nil)
}
