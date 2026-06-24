package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/ridehermes/ride-hermes/internal/common"
)

func (h *Handler) AdminGenerateAgentKey(c *gin.Context) {
	var req struct {
		UserID    uint64 `json:"user_id" binding:"required"`
		AgentName string `json:"agent_name" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, common.CodeParamError, "参数错误: user_id 和 agent_name 必填")
		return
	}

	cred, apiKey, err := h.AgentSvc.GenerateAPIKey(c.Request.Context(), req.UserID, req.AgentName)
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

func (h *Handler) AdminListAgentCredentials(c *gin.Context) {
	userIDStr := c.Query("user_id")
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "100"))

	type item struct {
		ID         int64    `json:"id"`
		UserID     int64    `json:"user_id"`
		AgentName  string   `json:"agent_name"`
		Status     int8     `json:"status"`
		RateLimit  int      `json:"rate_limit"`
		Permissions []string `json:"permissions"`
		LastUsedAt string   `json:"last_used_at"`
		CreatedAt  string   `json:"created_at"`
	}

	var creds []item
	var total int64

	if userIDStr != "" {
		userID, err := strconv.ParseUint(userIDStr, 10, 64)
		if err != nil {
			common.Error(c, common.CodeParamError, "user_id 格式错误")
			return
		}
		list, err := h.AgentSvc.ListKeys(c.Request.Context(), userID)
		if err != nil {
			common.Error(c, common.CodeInternalError, err.Error())
			return
		}
		for _, v := range list {
			lastUsed := ""
			if v.LastUsedAt != nil {
				lastUsed = v.LastUsedAt.Format("2006-01-02 15:04:05")
			}
			creds = append(creds, item{
				ID: v.ID, UserID: v.UserID, AgentName: v.AgentName,
				Status: v.Status, RateLimit: v.RateLimit,
				Permissions: []string(v.Permissions),
				LastUsedAt:  lastUsed,
				CreatedAt:   v.CreatedAt.Format("2006-01-02 15:04:05"),
			})
		}
		total = int64(len(creds))
	} else {
		list, t, err := h.AgentSvc.ListAllCredentials(c.Request.Context(), offset, limit)
		if err != nil {
			common.Error(c, common.CodeInternalError, err.Error())
			return
		}
		for _, v := range list {
			lastUsed := ""
			if v.LastUsedAt != nil {
				lastUsed = v.LastUsedAt.Format("2006-01-02 15:04:05")
			}
			creds = append(creds, item{
				ID: v.ID, UserID: v.UserID, AgentName: v.AgentName,
				Status: v.Status, RateLimit: v.RateLimit,
				Permissions: []string(v.Permissions),
				LastUsedAt:  lastUsed,
				CreatedAt:   v.CreatedAt.Format("2006-01-02 15:04:05"),
			})
		}
		total = t
	}

	common.Success(c, gin.H{"list": creds, "total": total})
}

func (h *Handler) AdminRevokeAgentKey(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	if err := h.AgentSvc.RevokeKey(c.Request.Context(), id, 0); err != nil {
		common.Error(c, common.CodeInternalError, err.Error())
		return
	}
	common.Success(c, nil)
}

func (h *Handler) AdminListAgentLogs(c *gin.Context) {
	userIDStr := c.Query("user_id")
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))

	if limit > 200 {
		limit = 200
	}

	type logItem struct {
		ID           int64  `json:"id"`
		CredentialID int64  `json:"credential_id"`
		UserID       int64  `json:"user_id"`
		AgentName    string `json:"agent_name"`
		Endpoint     string `json:"endpoint"`
		ResponseCode int    `json:"response_code"`
		OrderID      *int64 `json:"order_id"`
		IPAddress    string `json:"ip_address"`
		LatencyMs    int    `json:"latency_ms"`
		CreatedAt    string `json:"created_at"`
	}

	var items []logItem
	var total int64

	if userIDStr != "" {
		userID, err := strconv.ParseUint(userIDStr, 10, 64)
		if err != nil {
			common.Error(c, common.CodeParamError, "user_id 格式错误")
			return
		}
		logs, t, err := h.AgentSvc.GetCallLogs(c.Request.Context(), userID, offset, limit)
		if err != nil {
			common.Error(c, common.CodeInternalError, err.Error())
			return
		}
		for _, v := range logs {
			items = append(items, logItem{
				ID: v.ID, CredentialID: v.CredentialID, UserID: v.UserID,
				AgentName: v.AgentName, Endpoint: v.Endpoint,
				ResponseCode: v.ResponseCode, OrderID: v.OrderID,
				IPAddress: v.IPAddress, LatencyMs: v.LatencyMs,
				CreatedAt: v.CreatedAt.Format("2006-01-02 15:04:05"),
			})
		}
		total = t
	} else {
		common.Error(c, common.CodeParamError, "请提供 user_id 筛选参数")
		return
	}

	common.Success(c, gin.H{"list": items, "total": total})
}
