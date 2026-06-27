package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// GetDriverTrustScore 司机查询自己的信誉分
func (h *Handler) GetDriverTrustScore(c *gin.Context) {
	driverID := c.GetInt64("user_id")
	if driverID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	ts, err := h.TrustScoreSvc.GetTrustScore(c.Request.Context(), driverID)
	if err != nil {
		h.logger.Error("failed to get trust score", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询信誉分失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": ts,
	})
}

// GetDriverEvaluations 司机查询评价历史
func (h *Handler) GetDriverEvaluations(c *gin.Context) {
	driverID := c.GetInt64("user_id")
	if driverID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	limitStr := c.DefaultQuery("limit", "10")
	limit, _ := strconv.Atoi(limitStr)

	evals, err := h.TrustScoreSvc.GetEvaluations(c.Request.Context(), driverID, limit)
	if err != nil {
		h.logger.Error("failed to get evaluations", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询评价失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"evaluations": evals,
			"count":       len(evals),
		},
	})
}

// AdminListTrustScores 管理员查询所有信誉分
func (h *Handler) AdminListTrustScores(c *gin.Context) {
	scores, err := h.TrustScoreSvc.GetAllTrustScores(c.Request.Context())
	if err != nil {
		h.logger.Error("failed to list trust scores", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询信誉分列表失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"total":  len(scores),
			"scores": scores,
		},
	})
}

// AdminGetAnomalies 管理员查询异常预警
func (h *Handler) AdminGetAnomalies(c *gin.Context) {
	anomalies, err := h.TrustScoreSvc.DetectAnomalies(c.Request.Context())
	if err != nil {
		h.logger.Error("failed to detect anomalies", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "检测异常失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"total":     len(anomalies),
			"anomalies": anomalies,
		},
	})
}

// AdminAdjustTrustScore 管理员调整司机信誉分
func (h *Handler) AdminAdjustTrustScore(c *gin.Context) {
	driverIDStr := c.Param("driver_id")
	driverID, err := strconv.ParseInt(driverIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的司机ID"})
		return
	}

	var req struct {
		NewScore int    `json:"new_score" binding:"required,min=0,max=100"`
		Reason   string `json:"reason" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 调用 service 层调整信誉分
	if err := h.TrustScoreSvc.AdjustTrustScore(c.Request.Context(), driverID, req.NewScore, req.Reason); err != nil {
		h.logger.Error("failed to adjust trust score", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "调整信誉分失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "信誉分调整成功",
	})
}
