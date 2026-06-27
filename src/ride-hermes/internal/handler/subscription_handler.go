package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/ridehermes/ride-hermes/internal/service"
	"go.uber.org/zap"
)

// CreateSubscription 创建订阅
func (h *Handler) CreateSubscription(c *gin.Context) {
	driverID := c.GetInt64("user_id")
	if driverID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	var req struct {
		PlanType int8 `json:"plan_type" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	createReq := &service.CreateRequest{
		DriverID: driverID,
		PlanType: req.PlanType,
	}
	resp, err := h.SubscriptionSvc.Create(c.Request.Context(), createReq)
	if err != nil {
		h.logger.Error("failed to create subscription", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "创建订阅失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": resp,
	})
}

// GetDriverSubscription 查询司机订阅
func (h *Handler) GetDriverSubscription(c *gin.Context) {
	driverID := c.GetInt64("user_id")
	if driverID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	sub, err := h.SubscriptionSvc.GetByDriverID(c.Request.Context(), driverID)
	if err != nil {
		// 如果没有订阅，返回空数据而不是错误
		if err.Error() == "record not found" || err.Error() == "未找到有效订阅" {
			c.JSON(http.StatusOK, gin.H{
				"code": 0,
				"data": nil,
				"message": "暂无订阅",
			})
			return
		}
		h.logger.Error("failed to get subscription", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询订阅失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": sub,
	})
}

// ListSubscriptions 管理员查询所有订阅
func (h *Handler) ListSubscriptions(c *gin.Context) {
	statusStr := c.Query("status")
	var status *int8
	if statusStr != "" {
		s, _ := strconv.ParseInt(statusStr, 10, 8)
		v := int8(s)
		status = &v
	}

	subs, total, err := h.SubscriptionSvc.List(c.Request.Context(), status, 0, 50)
	if err != nil {
		h.logger.Error("failed to list subscriptions", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询订阅列表失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"total":         total,
			"subscriptions": subs,
		},
	})
}
