package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// AdminListNotifications 管理员查看通知记录
func (h *Handler) AdminListNotifications(c *gin.Context) {
	offsetStr := c.DefaultQuery("offset", "0")
	limitStr := c.DefaultQuery("limit", "50")
	offset, _ := strconv.Atoi(offsetStr)
	limit, _ := strconv.Atoi(limitStr)

	list, _, err := h.SubscriptionSvc.List(c.Request.Context(), nil, offset, limit)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"total": 0, "list": []interface{}{}})
		return
	}

	c.JSON(http.StatusOK, gin.H{"total": len(list), "list": list})
}
