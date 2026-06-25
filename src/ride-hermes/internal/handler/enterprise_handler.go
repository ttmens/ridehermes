package handler

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/ridehermes/ride-hermes/internal/model"
	"go.uber.org/zap"
)

func (h *Handler) AdminCreateEnterprise(c *gin.Context) {
	var req struct {
		CompanyName    string `json:"company_name" binding:"required"`
		ContactName    string `json:"contact_name" binding:"required"`
		ContactPhone   string `json:"contact_phone" binding:"required"`
		ContractType   int8   `json:"contract_type"`
		ContractAmount float64 `json:"contract_amount"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ent := &model.EnterpriseCustomer{
		CompanyName:    req.CompanyName,
		ContactName:    req.ContactName,
		ContactPhone:   req.ContactPhone,
		ContractType:   req.ContractType,
		ContractAmount: req.ContractAmount,
		ContractStart:  time.Now(),
		ContractEnd:    time.Now().AddDate(1, 0, 0),
	}

	if err := h.EnterpriseSvc.Create(c.Request.Context(), ent); err != nil {
		h.logger.Error("failed to create enterprise", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "创建企业客户失败"})
		return
	}

	c.JSON(http.StatusOK, ent)
}

func (h *Handler) AdminListEnterprises(c *gin.Context) {
	list, err := h.EnterpriseSvc.List(c.Request.Context())
	if err != nil {
		h.logger.Error("failed to list enterprises", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询企业列表失败"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"total": len(list), "enterprises": list})
}

func (h *Handler) AdminGetEnterprise(c *gin.Context) {
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	ent, err := h.EnterpriseSvc.GetByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "企业不存在"})
		return
	}
	c.JSON(http.StatusOK, ent)
}

func (h *Handler) AdminAddEnterpriseEmployee(c *gin.Context) {
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	var req struct {
		UserID int64  `json:"user_id" binding:"required"`
		Name   string `json:"name" binding:"required"`
		Phone  string `json:"phone" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.EnterpriseSvc.AddEmployee(c.Request.Context(), id, req.UserID, req.Name, req.Phone); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "添加员工失败"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "添加成功"})
}

func (h *Handler) AdminGetEnterpriseBill(c *gin.Context) {
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	year := time.Now().Year()
	month := int(time.Now().Month())

	bill, err := h.EnterpriseSvc.GetMonthlyBill(c.Request.Context(), id, year, month)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询账单失败"})
		return
	}
	c.JSON(http.StatusOK, bill)
}
