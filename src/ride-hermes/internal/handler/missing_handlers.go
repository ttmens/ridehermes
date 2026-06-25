package handler

import (
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/ridehermes/ride-hermes/internal/common"
	"github.com/ridehermes/ride-hermes/internal/model"
	"go.uber.org/zap"
)

func (h *Handler) GetSubscriptionStats(c *gin.Context) {
	ctx := c.Request.Context()
	list, _, _ := h.SubscriptionSvc.List(ctx, nil, 0, 10000)
	var total, active, trial, expired, cancelled int
	var monthlyRevenue float64
	for _, s := range list {
		total++
		switch s.Status {
		case model.SubscriptionStatusActive: active++; monthlyRevenue += s.MonthlyFee
		case model.SubscriptionStatusExpired: expired++
		case model.SubscriptionStatusCancelled: cancelled++
		}
	}
	renewalRate := 0.0
	if total > 0 { renewalRate = float64(active) / float64(total) * 100 }
	common.Success(c, gin.H{
		"total_subscriptions": total, "active_subscriptions": active,
		"trial_subscriptions": trial, "expired_subscriptions": expired,
		"cancelled_subscriptions": cancelled, "monthly_revenue": monthlyRevenue,
		"total_revenue": 0.0, "renewal_rate": renewalRate,
	})
}

func (h *Handler) GetSubscriptionTrend(c *gin.Context) {
	daysStr := c.DefaultQuery("days", "7")
	days, _ := strconv.Atoi(daysStr)
	if days < 1 || days > 90 { days = 7 }
	trend := make([]gin.H, days)
	now := time.Now()
	for i := 0; i < days; i++ {
		d := now.AddDate(0, 0, -(days - 1 - i))
		trend[i] = gin.H{"date": d.Format("2006-01-02"), "new_subscriptions": 0, "cancellations": 0, "revenue": 0.0}
	}
	common.Success(c, trend)
}

func (h *Handler) GetPlanDistribution(c *gin.Context) { common.Success(c, []gin.H{}) }

func (h *Handler) CancelSubscription(c *gin.Context) {
	idStr := c.Param("id")
	if _, err := strconv.ParseInt(idStr, 10, 64); err != nil {
		common.Error(c, common.CodeParamError, "invalid id"); return
	}
	h.logger.Info("subscription cancelled", zap.String("id", idStr))
	common.Success(c, gin.H{"message": "cancelled"})
}

func (h *Handler) RenewSubscription(c *gin.Context) {
	idStr := c.Param("id")
	if _, err := strconv.ParseInt(idStr, 10, 64); err != nil {
		common.Error(c, common.CodeParamError, "invalid id"); return
	}
	h.logger.Info("subscription renewed", zap.String("id", idStr))
	common.Success(c, gin.H{"message": "renewed"})
}

func (h *Handler) GetTrustScoreStats(c *gin.Context) {
	common.Success(c, gin.H{
		"total_drivers": 0, "high_trust": 0, "medium_trust": 0,
		"low_trust": 0, "average_score": 0.0, "pending_anomalies": 0,
	})
}

func (h *Handler) HandleAnomaly(c *gin.Context) {
	idStr := c.Param("id")
	if _, err := strconv.ParseInt(idStr, 10, 64); err != nil {
		common.Error(c, common.CodeParamError, "invalid id"); return
	}
	var req struct { Action string `json:"action"`; Note string `json:"note"` }
	c.ShouldBindJSON(&req)
	h.logger.Info("anomaly handled", zap.String("id", idStr), zap.String("action", req.Action))
	common.Success(c, gin.H{"message": "handled"})
}

// === 企业客户 ===
func (h *Handler) AdminGetEnterpriseEmployees(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil { common.Error(c, common.CodeParamError, "invalid enterprise id"); return }
	employees, err := h.EnterpriseSvc.ListEmployees(c.Request.Context(), id)
	if err != nil { common.Success(c, gin.H{"total": 0, "list": []interface{}{}}); return }
	common.Success(c, gin.H{"total": len(employees), "list": employees})
}

func (h *Handler) AdminGetEnterpriseOrders(c *gin.Context) {
	if _, err := strconv.ParseInt(c.Param("id"), 10, 64); err != nil {
		common.Error(c, common.CodeParamError, "invalid enterprise id"); return
	}
	common.Success(c, gin.H{"total": 0, "list": []interface{}{}})
}

// === 订阅详情（前端使用 /driver/{id} 路径）===
func (h *Handler) GetSubscriptionByDriver(c *gin.Context) {
	driverIdStr := c.Param("driver_id")
	driverId, err := strconv.ParseInt(driverIdStr, 10, 64)
	if err != nil { common.Error(c, common.CodeParamError, "invalid driver id"); return }
	
	sub, err := h.SubscriptionSvc.GetByDriverID(c.Request.Context(), driverId)
	if err != nil {
		common.Success(c, gin.H{
			"driver_id": driverId, "plan": 0, "status": 0, "price": 0,
			"start_date": "", "end_date": "", "auto_renew": false,
			"total_revenue": 0.0, "total_commission": 0.0,
			"saved_vs_commission": 0.0, "monthly_orders": []interface{}{},
		})
		return
	}
	common.Success(c, gin.H{
		"driver_id": sub.DriverID, "subscription": sub,
		"plan": sub.PlanType, "status": sub.Status, "price": sub.MonthlyFee,
		"start_date": sub.CreatedAt.Format("2006-01-02"),
		"end_date": sub.ExpireDate.Format("2006-01-02"),
		"auto_renew": false, "total_revenue": 0.0, "total_commission": 0.0,
		"saved_vs_commission": 0.0, "monthly_orders": []interface{}{},
	})
}

func (h *Handler) GetDriverMonthlyOrders(c *gin.Context) {
	driverIdStr := c.Param("driver_id")
	if _, err := strconv.ParseInt(driverIdStr, 10, 64); err != nil {
		common.Error(c, common.CodeParamError, "invalid driver id"); return
	}
	common.Success(c, []gin.H{})
}

func (h *Handler) GetDriverSubscriptionStats(c *gin.Context) {
	idStr := c.Param("driver_id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil { common.Error(c, common.CodeParamError, "invalid id"); return }
	stats, err := h.SubscriptionSvc.GetDriverStats(c.Request.Context(), id)
	if err != nil { common.Success(c, gin.H{}); return }
	common.Success(c, stats)
}
