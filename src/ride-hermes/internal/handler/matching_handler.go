package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/ridehermes/ride-hermes/internal/service"
	"go.uber.org/zap"
)

// CreateDemand 乘客发布出行需求（创建订单并启动撮合）
func (h *Handler) CreateDemand(c *gin.Context) {
	passengerID := c.GetInt64("user_id")
	if passengerID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	var req service.CreateOrderReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 创建订单
	order, err := h.OrderSvc.Create(c.Request.Context(), passengerID, &req)
	if err != nil {
		h.logger.Error("failed to create order", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "创建订单失败"})
		return
	}

	// 设置A2A匹配模式
	order.MatchingMode = 2

	// 发布到撮合引擎
	if err := h.MatchingEngine.PublishDemand(c.Request.Context(), order); err != nil {
		h.logger.Error("failed to publish demand", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "发布需求失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"order_id": order.ID,
		"order_no": order.OrderNo,
		"status":   "matching",
	})
}

// GetDemandMatches 查询匹配结果
func (h *Handler) GetDemandMatches(c *gin.Context) {
	orderID, err := strconv.ParseInt(c.Param("order_id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid order_id"})
		return
	}

	matches, err := h.MatchingEngine.GetMatches(c.Request.Context(), orderID)
	if err != nil {
		h.logger.Error("failed to get matches", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询匹配失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"order_id": orderID,
		"matches":  matches,
	})
}

// ConfirmMatch 乘客确认选择司机
func (h *Handler) ConfirmMatch(c *gin.Context) {
	orderID, err := strconv.ParseInt(c.Param("order_id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid order_id"})
		return
	}

	var req struct {
		DriverID int64 `json:"driver_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.MatchingEngine.ConfirmMatch(c.Request.Context(), orderID, req.DriverID); err != nil {
		h.logger.Error("failed to confirm match", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "确认匹配失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"order_id": orderID,
		"status":   "confirmed",
	})
}

// SubmitOffer 司机提交报价
func (h *Handler) SubmitOffer(c *gin.Context) {
	driverID := c.GetInt64("user_id")
	if driverID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	orderID, err := strconv.ParseInt(c.Param("order_id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid order_id"})
		return
	}

	var req struct {
		Price float64 `json:"price" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	offer, err := h.MatchingEngine.SubmitOffer(c.Request.Context(), orderID, driverID, req.Price)
	if err != nil {
		h.logger.Error("failed to submit offer", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "提交报价失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"offer": offer,
	})
}
