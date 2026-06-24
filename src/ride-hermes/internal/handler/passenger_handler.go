package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/ridehermes/ride-hermes/internal/common"
	"github.com/ridehermes/ride-hermes/internal/service"
	ws "github.com/ridehermes/ride-hermes/internal/ws"
)

func (h *Handler) PassengerCreateOrder(c *gin.Context) {
	userID := c.GetInt64("user_id")

	var req service.CreateOrderReq
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	order, err := h.OrderSvc.Create(c.Request.Context(), userID, &req)
	if err != nil {
		common.Error(c, common.CodeInternalError, err.Error())
		return
	}

	// Clean up AI conversation session after order creation
	h.AISvc.CleanupSession(c.Request.Context(), req.SessionID)

	driver, err := h.DispatchSvc.AssignDriver(c.Request.Context(), order)
	if err != nil {
		common.Success(c, gin.H{"order": order, "driver": nil, "message": err.Error()})
		return
	}

	order, _ = h.OrderSvc.GetByID(c.Request.Context(), order.ID)

	if driver != nil {
		h.hub.SendToUser(driver.UserID, ws.Message{
			Type: "order_assigned",
			Data: gin.H{"order": order},
		})
	}

	common.Success(c, order)
}

func (h *Handler) PassengerListOrders(c *gin.Context) {
	userID := c.GetInt64("user_id")
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

func (h *Handler) PassengerGetOrder(c *gin.Context) {
	userID := c.GetInt64("user_id")
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

func (h *Handler) PassengerCancelOrder(c *gin.Context) {
	userID := c.GetInt64("user_id")
	role := c.GetInt("role") // used as int8
	_ = role

	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	var req struct {
		Reason string `json:"reason"`
	}
	c.ShouldBindJSON(&req)

	if err := h.OrderSvc.Cancel(c.Request.Context(), id, userID, 2, req.Reason); err != nil {
		common.Error(c, common.CodeInvalidStatus, err.Error())
		return
	}
	common.Success(c, nil)
}

func (h *Handler) PassengerGetDriverLocation(c *gin.Context) {
	orderIDStr := c.Param("order_id")
	orderID, err := strconv.ParseInt(orderIDStr, 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	order, err := h.OrderSvc.GetByID(c.Request.Context(), orderID)
	if err != nil || order.DriverID == nil {
		common.Error(c, common.CodeOrderNotFound, "订单不存在或暂无司机")
		return
	}

	loc, err := h.LocationSvc.GetDriverLocation(c.Request.Context(), *order.DriverID)
	if err != nil {
		common.Error(c, common.CodeInternalError, err.Error())
		return
	}
	common.Success(c, loc)
}

func (h *Handler) PassengerAIChat(c *gin.Context) {
	userID := c.GetInt64("user_id")

	var req service.AIChatRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	if req.SessionID == "" {
		req.SessionID = uuid.New().String()
	}

	resp, err := h.AISvc.Chat(c.Request.Context(), userID, &req)
	if err != nil {
		common.Error(c, common.CodeAIServiceUnavailable, err.Error())
		return
	}
	common.Success(c, resp)
}

func (h *Handler) PassengerAISessions(c *gin.Context) {
	userID := c.GetInt64("user_id")
	sessions, err := h.AISvc.GetSessions(c.Request.Context(), userID)
	if err != nil {
		common.Error(c, common.CodeInternalError, err.Error())
		return
	}
	common.Success(c, sessions)
}

func (h *Handler) GetProfile(c *gin.Context) {
	userID := c.GetInt64("user_id")
	user, err := h.UserSvc.GetProfile(c.Request.Context(), userID)
	if err != nil {
		common.Error(c, common.CodeUserNotFound, "用户不存在")
		return
	}
	common.Success(c, user)
}

func (h *Handler) UpdateProfile(c *gin.Context) {
	userID := c.GetInt64("user_id")
	var req struct {
		Nickname  string `json:"nickname"`
		AvatarURL string `json:"avatar_url"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	if err := h.UserSvc.UpdateProfile(c.Request.Context(), userID, req.Nickname, req.AvatarURL); err != nil {
		common.Error(c, common.CodeInternalError, err.Error())
		return
	}
	common.Success(c, nil)
}
