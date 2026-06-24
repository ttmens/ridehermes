package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/ridehermes/ride-hermes/internal/common"
	"github.com/ridehermes/ride-hermes/internal/model"
	"github.com/ridehermes/ride-hermes/internal/service"
	"gorm.io/gorm"
)

func (h *Handler) AdminCreatePassenger(c *gin.Context) {
	var req service.CreatePassengerReq
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	user, err := h.UserSvc.CreatePassengerWithDB(c.Request.Context(), h.db, &req)
	if err != nil {
		common.Error(c, common.CodePhoneExists, err.Error())
		return
	}

	common.Success(c, gin.H{
		"user": map[string]interface{}{
			"id":       user.ID,
			"phone":    req.Phone,
			"nickname": req.Nickname,
			"role":     model.RolePassenger,
		},
	})
}

func (h *Handler) AdminCreateDriver(c *gin.Context) {
	var req service.CreateDriverReq
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	var user *model.User
	var driver *model.Driver
	var vehicle *model.Vehicle
	var createErr error

	err := h.db.WithContext(c.Request.Context()).Transaction(func(tx *gorm.DB) error {
		user, driver, vehicle, createErr = h.UserSvc.CreateDriverWithDB(c.Request.Context(), tx, &req)
		return createErr
	})

	if err != nil {
		common.Error(c, common.CodeInternalError, err.Error())
		return
	}

	common.Success(c, gin.H{
		"user": gin.H{
			"id":       user.ID,
			"phone":    req.Phone,
			"nickname": req.Nickname,
			"role":     model.RoleDriver,
		},
		"driver": gin.H{
			"id":        driver.ID,
			"real_name": driver.RealName,
			"status":    driver.Status,
		},
		"vehicle": gin.H{
			"id":           vehicle.ID,
			"plate_number": vehicle.PlateNumber,
			"brand":        vehicle.Brand,
			"model":        vehicle.Model,
			"color":        vehicle.Color,
			"car_type":     vehicle.CarType,
		},
	})
}

func (h *Handler) AdminListUsers(c *gin.Context) {
	roleStr := c.Query("role")
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	var role *int8
	if roleStr != "" {
		r, _ := strconv.Atoi(roleStr)
		r8 := int8(r)
		role = &r8
	}

	users, total, err := h.AdminSvc.ListUsers(c.Request.Context(), role, offset, limit)
	if err != nil {
		common.Error(c, common.CodeInternalError, err.Error())
		return
	}

	common.Success(c, gin.H{
		"list":  users,
		"total": total,
	})
}

func (h *Handler) AdminGetUser(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	user, err := h.AdminSvc.GetUser(c.Request.Context(), id)
	if err != nil {
		common.Error(c, common.CodeUserNotFound, "用户不存在")
		return
	}
	common.Success(c, user)
}

func (h *Handler) AdminUpdateUserStatus(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	var req struct {
		Status int8 `json:"status"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	if err := h.AdminSvc.UpdateUserStatus(c.Request.Context(), id, req.Status); err != nil {
		common.Error(c, common.CodeInternalError, err.Error())
		return
	}
	common.Success(c, nil)
}

func (h *Handler) AdminListDrivers(c *gin.Context) {
	statusStr := c.Query("status")
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	var status *int8
	if statusStr != "" {
		s, _ := strconv.Atoi(statusStr)
		s8 := int8(s)
		status = &s8
	}

	drivers, total, err := h.DriverSvc.ListDrivers(c.Request.Context(), status, offset, limit)
	if err != nil {
		common.Error(c, common.CodeInternalError, err.Error())
		return
	}
	common.Success(c, gin.H{
		"list":  drivers,
		"total": total,
	})
}

func (h *Handler) AdminGetDriver(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	driver, err := h.DriverSvc.GetDriverByID(c.Request.Context(), id)
	if err != nil {
		common.Error(c, common.CodeDriverNotFound, "司机不存在")
		return
	}
	common.Success(c, driver)
}

func (h *Handler) AdminListOrders(c *gin.Context) {
	statusStr := c.Query("status")
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	var status *int8
	if statusStr != "" {
		s, _ := strconv.Atoi(statusStr)
		s8 := int8(s)
		status = &s8
	}

	orders, total, err := h.AdminSvc.ListOrders(c.Request.Context(), status, offset, limit)
	if err != nil {
		common.Error(c, common.CodeInternalError, err.Error())
		return
	}
	common.Success(c, gin.H{
		"list":  orders,
		"total": total,
	})
}

func (h *Handler) AdminGetOrder(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	order, err := h.AdminSvc.GetOrder(c.Request.Context(), id)
	if err != nil {
		common.Error(c, common.CodeOrderNotFound, "订单不存在")
		return
	}
	common.Success(c, order)
}

func (h *Handler) AdminUpdateDriver(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	var req service.UpdateDriverReq
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	if err := h.AdminSvc.UpdateDriver(c.Request.Context(), id, &req); err != nil {
		common.Error(c, common.CodeInternalError, err.Error())
		return
	}
	common.Success(c, nil)
}

func (h *Handler) AdminGetDriverLocations(c *gin.Context) {
	locs, err := h.LocationSvc.GetOnlineDriverLocations(c.Request.Context())
	if err != nil {
		common.Error(c, common.CodeInternalError, err.Error())
		return
	}
	common.Success(c, locs)
}

func (h *Handler) AdminGetPassengerLocations(c *gin.Context) {
	common.Success(c, []interface{}{})
}
