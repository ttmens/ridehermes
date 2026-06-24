package handler

import (
	"encoding/json"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/ridehermes/ride-hermes/internal/common"
	"github.com/ridehermes/ride-hermes/internal/model"
	"github.com/ridehermes/ride-hermes/internal/service"
	ws "github.com/ridehermes/ride-hermes/internal/ws"
)

func hasPermission(permissions []string, required string) bool {
	for _, p := range permissions {
		if p == required {
			return true
		}
	}
	return false
}

func (h *Handler) AgentEstimateOrder(c *gin.Context) {
	start := time.Now()
	userID := c.GetInt64("user_id")
	credID := c.GetInt64("credential_id")
	agentName := c.GetString("agent_name")

	permissions := c.GetStringSlice("permissions")
	if !hasPermission(permissions, "ride:estimate") {
		common.Error(c, common.CodeAgentNoPermission, "缺少 ride:estimate 权限")
		return
	}

	var req service.CreateOrderReq
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	// Geocode addresses if coordinates not provided
	if (req.PickupLat == 0 && req.PickupLng == 0) && req.PickupAddr != "" {
		result, err := h.AmapSvc.Geocode(req.PickupAddr)
		if err == nil && result.Resolved {
			req.PickupLat = result.Lat
			req.PickupLng = result.Lng
		}
	}
	if (req.DropoffLat == 0 && req.DropoffLng == 0) && req.DropoffAddr != "" {
		result, err := h.AmapSvc.Geocode(req.DropoffAddr)
		if err == nil && result.Resolved {
			req.DropoffLat = result.Lat
			req.DropoffLng = result.Lng
		}
	}

	if req.PickupLat == 0 && req.PickupLng == 0 {
		common.Error(c, common.CodeParamError, "上车点坐标缺失，请提供 pickup_lat/pickup_lng 或有效的地址")
		return
	}
	if req.DropoffLat == 0 && req.DropoffLng == 0 {
		common.Error(c, common.CodeParamError, "下车点坐标缺失，请提供 dropoff_lat/dropoff_lng 或有效的地址")
		return
	}

	price, distance, duration := service.EstimatePrice(req.PickupLat, req.PickupLng, req.DropoffLat, req.DropoffLng, req.CarType)

	reqBody, _ := json.Marshal(req)
	h.AgentSvc.LogCall(c.Request.Context(), credID, userID, agentName,
		"/api/v1/agent/orders/estimate", string(reqBody), c.ClientIP(), 200, nil, int(time.Since(start).Milliseconds()))

	common.Success(c, gin.H{
		"est_price":    price,
		"est_distance": distance,
		"est_duration": duration,
	})
}

func (h *Handler) AgentCreateOrder(c *gin.Context) {
	start := time.Now()
	userID := c.GetInt64("user_id")
	credID := c.GetInt64("credential_id")
	agentName := c.GetString("agent_name")

	permissions := c.GetStringSlice("permissions")
	if !hasPermission(permissions, "ride:book") {
		common.Error(c, common.CodeAgentNoPermission, "缺少 ride:book 权限")
		return
	}

	hasActive, err := h.OrderSvc.HasActiveOrder(c.Request.Context(), userID)
	if err == nil && hasActive {
		common.Error(c, common.CodeHasActiveOrder, "已有进行中订单，请先取消或等待完成后再叫车")
		return
	}

	var req service.CreateOrderReq
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		reqBody, _ := json.Marshal(req)
		h.AgentSvc.LogCall(c.Request.Context(), credID, userID, agentName,
			"/api/v1/agent/orders", string(reqBody), c.ClientIP(), 400, nil, int(time.Since(start).Milliseconds()))
		return
	}

	// Geocode addresses if coordinates not provided
	if (req.PickupLat == 0 && req.PickupLng == 0) && req.PickupAddr != "" {
		result, err := h.AmapSvc.Geocode(req.PickupAddr)
		if err == nil && result.Resolved {
			req.PickupLat = result.Lat
			req.PickupLng = result.Lng
		}
	}
	if (req.DropoffLat == 0 && req.DropoffLng == 0) && req.DropoffAddr != "" {
		result, err := h.AmapSvc.Geocode(req.DropoffAddr)
		if err == nil && result.Resolved {
			req.DropoffLat = result.Lat
			req.DropoffLng = result.Lng
		}
	}

	// Validate we have coordinates
	if req.PickupLat == 0 && req.PickupLng == 0 {
		common.Error(c, common.CodeParamError, "上车点坐标缺失，请提供 pickup_lat/pickup_lng 或有效的地址")
		return
	}
	if req.DropoffLat == 0 && req.DropoffLng == 0 {
		common.Error(c, common.CodeParamError, "下车点坐标缺失，请提供 dropoff_lat/dropoff_lng 或有效的地址")
		return
	}

	order, err := h.OrderSvc.Create(c.Request.Context(), userID, &req)
	if err != nil {
		common.Error(c, common.CodeInternalError, err.Error())
		reqBody, _ := json.Marshal(req)
		h.AgentSvc.LogCall(c.Request.Context(), credID, userID, agentName,
			"/api/v1/agent/orders", string(reqBody), c.ClientIP(), 500, nil, int(time.Since(start).Milliseconds()))
		return
	}

	driver, err := h.DispatchSvc.AssignDriver(c.Request.Context(), order)
	if err != nil {
		common.Success(c, gin.H{"order": order, "driver": nil, "message": err.Error()})
		return
	}

	order, _ = h.OrderSvc.GetByID(c.Request.Context(), order.ID)

	// Notify driver via WebSocket
	if driver != nil {
		h.hub.SendToUser(driver.UserID, ws.Message{
			Type: "order_assigned",
			Data: gin.H{"order": order},
		})
	}

	// Log success
	reqBody, _ := json.Marshal(req)
	h.AgentSvc.LogCall(c.Request.Context(), credID, userID, agentName,
		"/api/v1/agent/orders", string(reqBody), c.ClientIP(), 200, &order.ID, int(time.Since(start).Milliseconds()))

	common.Success(c, order)
}

func (h *Handler) AgentGetOrder(c *gin.Context) {
	userID := c.GetInt64("user_id")

	permissions := c.GetStringSlice("permissions")
	if !hasPermission(permissions, "ride:status") {
		common.Error(c, common.CodeAgentNoPermission, "缺少 ride:status 权限")
		return
	}

	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	order, err := h.OrderSvc.GetByID(c.Request.Context(), id)
	if err != nil {
		common.Error(c, common.CodeOrderNotFound, "订单不存在")
		return
	}
	if order.PassengerID != userID {
		common.Error(c, common.CodeForbidden, "无权查看此订单")
		return
	}
	common.Success(c, order)
}

func (h *Handler) AgentListOrders(c *gin.Context) {
	userID := c.GetInt64("user_id")

	permissions := c.GetStringSlice("permissions")
	if !hasPermission(permissions, "ride:history") {
		common.Error(c, common.CodeAgentNoPermission, "缺少 ride:history 权限")
		return
	}

	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	orders, total, err := h.OrderSvc.ListByPassenger(c.Request.Context(), userID, offset, limit)
	if err != nil {
		common.Error(c, common.CodeInternalError, err.Error())
		return
	}
	common.Success(c, gin.H{
		"list":  orders,
		"total": total,
	})
}

func (h *Handler) AgentCancelOrder(c *gin.Context) {
	userID := c.GetInt64("user_id")

	permissions := c.GetStringSlice("permissions")
	if !hasPermission(permissions, "ride:cancel") {
		common.Error(c, common.CodeAgentNoPermission, "缺少 ride:cancel 权限")
		return
	}

	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	var req struct {
		Reason string `json:"reason"`
	}
	c.ShouldBindJSON(&req)

	if err := h.OrderSvc.Cancel(c.Request.Context(), id, userID, model.RolePassenger, req.Reason); err != nil {
		common.Error(c, common.CodeInvalidStatus, err.Error())
		return
	}
	common.Success(c, nil)
}
