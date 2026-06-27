package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/ridehermes/ride-hermes/internal/model"
)

// GetSubscriptionPlans 获取所有订阅套餐
func (h *Handler) GetSubscriptionPlans(c *gin.Context) {
	plans := []gin.H{}

	for planType, config := range model.PlanConfigs {
		plans = append(plans, gin.H{
			"type":         planType,
			"name":         model.PlanTypeNames[planType],
			"monthly_fee":  config.MonthlyFee,
			"revenue_rate": config.RevenueRate,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"plans": plans,
		},
	})
}
