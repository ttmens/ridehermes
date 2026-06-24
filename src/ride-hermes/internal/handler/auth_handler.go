package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/ridehermes/ride-hermes/internal/common"
	"github.com/ridehermes/ride-hermes/internal/service"
)

func (h *Handler) AuthLogin(c *gin.Context) {
	var req service.LoginReq
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	resp, err := h.UserSvc.Login(c.Request.Context(), &req)
	if err != nil {
		common.Error(c, common.CodeParamError, err.Error())
		return
	}
	common.Success(c, resp)
}

func (h *Handler) AuthLoginOrRegister(c *gin.Context) {
	var req service.LoginOrRegisterReq
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	resp, err := h.UserSvc.LoginOrRegister(c.Request.Context(), &req)
	if err != nil {
		common.Error(c, common.CodeParamError, err.Error())
		return
	}
	common.Success(c, resp)
}

func (h *Handler) AuthRefresh(c *gin.Context) {
	// v0.1: Accept refresh_token in body and return new access token
	var req struct {
		RefreshToken string `json:"refresh_token"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, common.CodeParamError, "参数错误")
		return
	}

	// v0.1: refresh endpoint reserved for v0.2
	_ = req.RefreshToken
	common.Success(c, gin.H{"message": "refresh endpoint reserved for v0.2"})
}
