package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/ridehermes/ride-hermes/internal/common"
	"github.com/ridehermes/ride-hermes/internal/model"
	ws "github.com/ridehermes/ride-hermes/internal/ws"
)

func (h *Handler) DriverOnline(c *gin.Context) {
	userID := c.GetInt64("user_id")

	driver, err := h.DriverSvc.VerifyDriverActive(c.Request.Context(), userID)
	if err != nil {
		common.Error(c, common.CodeDriverOffline, err.Error())
		return
	}

	var req struct {
		Latitude  float64 `json:"latitude"`
		Longitude float64 `json:"longitude"`
		CarType   int8    `json:"car_type"`
	}
	c.ShouldBindJSON(&req)
	if req.CarType == 0 {
		req.CarType = model.CarTypeEconomy
	}

	h.DispatchSvc.DriverOnline(c.Request.Context(), driver.ID, req.CarType)
	h.hub.DriverOnline(driver.ID, req.CarType)

	if req.Latitude != 0 && req.Longitude != 0 {
		h.hub.UpdateDriverLocation(driver.ID, req.Latitude, req.Longitude, 0, 0, 0)
	}

	common.Success(c, gin.H{"status": "online"})
}

func (h *Handler) DriverOffline(c *gin.Context) {
	userID := c.GetInt64("user_id")

	driver, err := h.DriverSvc.VerifyDriverActive(c.Request.Context(), userID)
	if err != nil {
		common.Error(c, common.CodeDriverOffline, err.Error())
		return
	}

	h.DispatchSvc.DriverOffline(c.Request.Context(), driver.ID, 1)
	h.hub.DriverOffline(driver.ID, 1)
	common.Success(c, gin.H{"status": "offline"})
}

func (h *Handler) DriverAcceptOrder(c *gin.Context) {
	userID := c.GetInt64("user_id")
	orderID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	driver, err := h.DriverSvc.GetDriverByUserID(c.Request.Context(), userID)
	if err != nil {
		common.Error(c, common.CodeDriverNotFound, "司机不存在")
		return
	}

	if err := h.DispatchSvc.AcceptOrder(c.Request.Context(), orderID, driver.ID); err != nil {
		common.Error(c, common.CodeInvalidStatus, err.Error())
		return
	}

	order, _ := h.OrderSvc.GetByID(c.Request.Context(), orderID)
	if order != nil {
		h.hub.SendToUser(order.PassengerID, ws.Message{
			Type: "order_status",
			Data: gin.H{
				"order_id":    order.ID,
				"status":      order.Status,
				"status_text": "司机已确认",
				"driver":      driver,
			},
		})
	}

	common.Success(c, nil)
}

func (h *Handler) DriverRejectOrder(c *gin.Context) {
	userID := c.GetInt64("user_id")
	orderID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	driver, err := h.DriverSvc.GetDriverByUserID(c.Request.Context(), userID)
	if err != nil {
		common.Error(c, common.CodeDriverNotFound, "司机不存在")
		return
	}

	var req struct {
		Reason string `json:"reason"`
	}
	_ = c.ShouldBindJSON(&req)
	if req.Reason == "" {
		req.Reason = "不接受此订单"
	}

	if err := h.OrderSvc.Reject(c.Request.Context(), orderID, driver.ID, req.Reason); err != nil {
		common.Error(c, common.CodeInvalidStatus, err.Error())
		return
	}

	order, _ := h.OrderSvc.GetByID(c.Request.Context(), orderID)
	if order != nil {
		h.hub.SendToUser(order.PassengerID, ws.Message{
			Type: "order_rejected",
			Data: gin.H{
				"order_id": order.ID,
				"driver":   driver,
				"reason":   req.Reason,
			},
		})
	}

	common.Success(c, nil)
}

func (h *Handler) DriverArrive(c *gin.Context) {
	userID := c.GetInt64("user_id")
	orderID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	driver, err := h.DriverSvc.GetDriverByUserID(c.Request.Context(), userID)
	if err != nil {
		common.Error(c, common.CodeDriverNotFound, "司机不存在")
		return
	}

	if err := h.OrderSvc.Arrive(c.Request.Context(), orderID, driver.ID); err != nil {
		common.Error(c, common.CodeInvalidStatus, err.Error())
		return
	}

	common.Success(c, nil)
}

func (h *Handler) DriverStartTrip(c *gin.Context) {
	userID := c.GetInt64("user_id")
	orderID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	driver, err := h.DriverSvc.GetDriverByUserID(c.Request.Context(), userID)
	if err != nil {
		common.Error(c, common.CodeDriverNotFound, "司机不存在")
		return
	}

	if err := h.OrderSvc.StartTrip(c.Request.Context(), orderID, driver.ID); err != nil {
		common.Error(c, common.CodeInvalidStatus, err.Error())
		return
	}

	common.Success(c, nil)
}

func (h *Handler) DriverCompleteOrder(c *gin.Context) {
	userID := c.GetInt64("user_id")
	orderID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	driver, err := h.DriverSvc.GetDriverByUserID(c.Request.Context(), userID)
	if err != nil {
		common.Error(c, common.CodeDriverNotFound, "司机不存在")
		return
	}

	if err := h.OrderSvc.Complete(c.Request.Context(), orderID, driver.ID); err != nil {
		common.Error(c, common.CodeInvalidStatus, err.Error())
		return
	}

	common.Success(c, nil)
}

func (h *Handler) DriverListOrders(c *gin.Context) {
	userID := c.GetInt64("user_id")
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	driver, err := h.DriverSvc.GetDriverByUserID(c.Request.Context(), userID)
	if err != nil {
		common.Error(c, common.CodeDriverNotFound, "司机不存在")
		return
	}

	orders, total, err := h.OrderSvc.ListByDriver(c.Request.Context(), driver.ID, offset, limit)
	if err != nil {
		common.Error(c, common.CodeInternalError, err.Error())
		return
	}
	common.Success(c, gin.H{
		"list":  orders,
		"total": total,
	})
}

func (h *Handler) DriverGetOrder(c *gin.Context) {
	userID := c.GetInt64("user_id")
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	driver, err := h.DriverSvc.GetDriverByUserID(c.Request.Context(), userID)
	if err != nil {
		common.Error(c, common.CodeDriverNotFound, "司机不存在")
		return
	}

	order, err := h.OrderSvc.GetByID(c.Request.Context(), id)
	if err != nil {
		common.Error(c, common.CodeOrderNotFound, "订单不存在")
		return
	}
	if order.DriverID == nil || *order.DriverID != driver.ID {
		common.Error(c, common.CodeForbidden, "无权查看此订单")
		return
	}
	common.Success(c, order)
}
