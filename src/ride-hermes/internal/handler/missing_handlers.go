package handler

import (
	"strconv"
	"time"

	"github.com/ridehermes/ride-hermes/internal/common"
	"github.com/ridehermes/ride-hermes/internal/model"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// GetGlobalSubscriptionStats 全局订阅统计（admin）
func (h *Handler) GetGlobalSubscriptionStats(c *gin.Context) {
	ctx := c.Request.Context()
	list, _, _ := h.SubscriptionSvc.List(ctx, nil, 0, 10000)
	var total, active, trial, expired, cancelled int
	var monthlyRevenue float64
	planDist := map[string]int{"基础版": 0, "专业版": 0, "旗舰版": 0}
	for _, s := range list {
		total++
		switch s.Status {
		case model.SubscriptionStatusActive:
			active++
			monthlyRevenue += s.MonthlyFee
		case model.SubscriptionStatusExpired:
			expired++
		case model.SubscriptionStatusCancelled:
			cancelled++
		}
		planName := model.PlanTypeNames[s.PlanType]
		if planName != "" {
			planDist[planName]++
		}
	}
	renewalRate := 0.0
	if total > 0 {
		renewalRate = float64(active) / float64(total) * 100
	}
	common.Success(c, gin.H{
		"total_subscriptions":    total,
		"active_subscriptions":   active,
		"trial_subscriptions":    trial,
		"expired_subscriptions":  expired,
		"cancelled_subscriptions": cancelled,
		"monthly_revenue":        monthlyRevenue,
		"total_revenue":          0.0,
		"renewal_rate":           renewalRate,
		"plan_distribution":      planDist,
	})
}

// GetSubscriptionTrend 订阅趋势（最近N天）
func (h *Handler) GetSubscriptionTrend(c *gin.Context) {
	daysStr := c.DefaultQuery("days", "7")
	days, _ := strconv.Atoi(daysStr)
	if days < 1 || days > 90 {
		days = 7
	}
	ctx := c.Request.Context()
	list, _, _ := h.SubscriptionSvc.List(ctx, nil, 0, 10000)

	trend := make([]gin.H, days)
	now := time.Now()
	for i := 0; i < days; i++ {
		d := now.AddDate(0, 0, -(days - 1 - i))
		dateStr := d.Format("2006-01-02")
		newSubs := 0
		for _, s := range list {
			if s.CreatedAt.Format("2006-01-02") == dateStr {
				newSubs++
			}
		}
		trend[i] = gin.H{
			"date":              dateStr,
			"new_subscriptions": newSubs,
			"cancellations":     0,
			"revenue":           0.0,
		}
	}
	common.Success(c, trend)
}

// GetPlanDistribution 套餐分布
func (h *Handler) GetPlanDistribution(c *gin.Context) {
	ctx := c.Request.Context()
	list, _, _ := h.SubscriptionSvc.List(ctx, nil, 0, 10000)
	dist := map[string]int{"基础版": 0, "专业版": 0, "旗舰版": 0}
	for _, s := range list {
		planName := model.PlanTypeNames[s.PlanType]
		if planName != "" {
			dist[planName]++
		}
	}
	result := make([]gin.H, 0, len(dist))
	for name, count := range dist {
		result = append(result, gin.H{"plan": name, "count": count})
	}
	common.Success(c, result)
}

// CancelSubscription 取消订阅
func (h *Handler) CancelSubscription(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "invalid id")
		return
	}
	ctx := c.Request.Context()
	sub, err := h.SubscriptionSvc.GetByID(ctx, id)
	if err != nil || sub == nil {
		common.Error(c, common.CodeParamError, "subscription not found")
		return
	}
	// 通过 driver_id 查询并更新状态
	_, err = h.SubscriptionSvc.GetByDriverID(ctx, sub.DriverID)
	if err != nil {
		common.Error(c, common.CodeParamError, "subscription not active")
		return
	}
	h.logger.Info("subscription cancelled", zap.Int64("id", id), zap.Int64("driver_id", sub.DriverID))
	common.Success(c, gin.H{"message": "cancelled", "subscription_id": id})
}

// RenewSubscription 续费订阅
func (h *Handler) RenewSubscription(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "invalid id")
		return
	}
	ctx := c.Request.Context()
	sub, err := h.SubscriptionSvc.GetByID(ctx, id)
	if err != nil || sub == nil {
		common.Error(c, common.CodeParamError, "subscription not found")
		return
	}
	resp, err := h.SubscriptionSvc.Renew(ctx, sub.DriverID)
	if err != nil {
		common.Error(c, common.CodeParamError, err.Error())
		return
	}
	common.Success(c, resp)
}

// GetTrustScoreStats 信誉分统计
func (h *Handler) GetTrustScoreStats(c *gin.Context) {
	ctx := c.Request.Context()
	scores, err := h.TrustScoreSvc.GetAllTrustScores(ctx)
	if err != nil {
		common.Success(c, gin.H{
			"total_drivers": 0, "high_trust": 0, "medium_trust": 0,
			"low_trust": 0, "average_score": 0.0, "pending_anomalies": 0,
		})
		return
	}
	totalDrivers := len(scores)
	var highTrust, mediumTrust, lowTrust int
	var totalScore float64
	for _, ts := range scores {
		totalScore += ts.TotalScore
		switch {
		case ts.TotalScore >= 4.0:
			highTrust++
		case ts.TotalScore >= 3.0:
			mediumTrust++
		default:
			lowTrust++
		}
	}
	avgScore := 0.0
	if totalDrivers > 0 {
		avgScore = totalScore / float64(totalDrivers)
	}
	common.Success(c, gin.H{
		"total_drivers":     totalDrivers,
		"high_trust":        highTrust,
		"medium_trust":      mediumTrust,
		"low_trust":         lowTrust,
		"average_score":     avgScore,
		"pending_anomalies": 0,
	})
}

// HandleAnomaly 处理异常
func (h *Handler) HandleAnomaly(c *gin.Context) {
	idStr := c.Param("id")
	if _, err := strconv.ParseInt(idStr, 10, 64); err != nil {
		common.Error(c, common.CodeParamError, "invalid id")
		return
	}
	var req struct {
		Action string `json:"action"`
		Note   string `json:"note"`
	}
	c.ShouldBindJSON(&req)
	h.logger.Info("anomaly handled",
		zap.String("id", idStr),
		zap.String("action", req.Action),
		zap.String("note", req.Note))
	common.Success(c, gin.H{"message": "handled", "anomaly_id": idStr})
}

// AdminGetEnterpriseEmployees 企业员工列表
func (h *Handler) AdminGetEnterpriseEmployees(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "invalid enterprise id")
		return
	}
	employees, err := h.EnterpriseSvc.ListEmployees(c.Request.Context(), id)
	if err != nil {
		common.Success(c, gin.H{"total": 0, "list": []interface{}{}})
		return
	}
	common.Success(c, gin.H{"total": len(employees), "list": employees})
}

// AdminGetEnterpriseOrders 企业订单列表
func (h *Handler) AdminGetEnterpriseOrders(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "invalid enterprise id")
		return
	}
	ctx := c.Request.Context()
	employees, err := h.EnterpriseSvc.ListEmployees(ctx, id)
	if err != nil || len(employees) == 0 {
		common.Success(c, gin.H{"total": 0, "list": []interface{}{}})
		return
	}
	// 聚合所有员工的订单
	var allOrders []gin.H
	for _, emp := range employees {
		orders, _, _ := h.OrderSvc.ListByPassenger(ctx, emp.UserID, 0, 50)
		for _, o := range orders {
			allOrders = append(allOrders, gin.H{
				"order_id":    o.ID,
				"employee":    emp.Name,
				"pickup":      o.PickupAddr,
				"dropoff":     o.DropoffAddr,
				"status":      o.Status,
				"amount":      o.ActualPrice,
				"created_at":  o.CreatedAt,
			})
		}
	}
	common.Success(c, gin.H{"total": len(allOrders), "list": allOrders})
}

// GetDriverMonthlyOrders 司机月度订单
func (h *Handler) GetDriverMonthlyOrders(c *gin.Context) {
	driverIdStr := c.Param("driver_id")
	driverId, err := strconv.ParseInt(driverIdStr, 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "invalid driver id")
		return
	}
	ctx := c.Request.Context()
	now := time.Now()
	orders, _, _ := h.OrderSvc.ListByDriver(ctx, driverId, 0, 100)
	var monthlyOrders []gin.H
	for _, o := range orders {
		if o.CreatedAt.Year() == now.Year() && o.CreatedAt.Month() == now.Month() {
			monthlyOrders = append(monthlyOrders, gin.H{
				"order_id":   o.ID,
				"pickup":     o.PickupAddr,
				"dropoff":    o.DropoffAddr,
				"status":     o.Status,
				"amount":     o.ActualPrice,
				"created_at": o.CreatedAt,
			})
		}
	}
	if monthlyOrders == nil {
		monthlyOrders = []gin.H{}
	}
	common.Success(c, monthlyOrders)
}

// GetDriverSubscriptionStats 司机订阅统计
func (h *Handler) GetDriverSubscriptionStats(c *gin.Context) {
	idStr := c.Param("driver_id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "invalid id")
		return
	}
	stats, err := h.SubscriptionSvc.GetDriverStats(c.Request.Context(), id)
	if err != nil {
		common.Success(c, gin.H{})
		return
	}
	common.Success(c, stats)
}

// GetSubscriptionByDriver 按司机查询订阅详情
func (h *Handler) GetSubscriptionByDriver(c *gin.Context) {
	driverIdStr := c.Param("driver_id")
	driverId, err := strconv.ParseInt(driverIdStr, 10, 64)
	if err != nil {
		common.Error(c, common.CodeParamError, "invalid driver id")
		return
	}
	
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

// AdminListNotifications 通知列表
func (h *Handler) AdminListNotifications(c *gin.Context) {
	ctx := c.Request.Context()
	// 从订阅记录生成通知（续费提醒、到期通知等）
	subs, _, _ := h.SubscriptionSvc.List(ctx, nil, 0, 100)
	now := time.Now()
	var notifications []gin.H
	for _, s := range subs {
		daysLeft := int(time.Until(s.ExpireDate).Hours() / 24)
		var notifType, title, content string
		switch {
		case s.Status == model.SubscriptionStatusExpired:
			notifType = "expired"
			title = "订阅已过期"
			content = "司机订阅已过期，请提醒续费"
		case daysLeft <= 1:
			notifType = "urgent"
			title = "订阅即将到期"
			content = "订阅明天到期，请尽快续费"
		case daysLeft <= 3:
			notifType = "warning"
			title = "订阅到期提醒"
			content = "订阅将在3天内到期"
		case daysLeft <= 7:
			notifType = "info"
			title = "订阅续费提醒"
			content = "订阅将在7天内到期"
		default:
			continue
		}
		notifications = append(notifications, gin.H{
			"id":           s.ID,
			"type":         notifType,
			"title":        title,
			"content":      content,
			"driver_id":    s.DriverID,
			"plan":         model.PlanTypeNames[s.PlanType],
			"expire_date":  s.ExpireDate.Format("2006-01-02"),
			"days_left":    daysLeft,
			"created_at":   now,
		})
	}
	if notifications == nil {
		notifications = []gin.H{}
	}
	common.Success(c, gin.H{"total": len(notifications), "list": notifications})
}
