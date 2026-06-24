package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/ridehermes/ride-hermes/internal/service"
	"go.uber.org/zap"
)

type MapHandler struct {
	amapSvc *service.AmapService
	logger  *zap.Logger
}

func NewMapHandler(amapSvc *service.AmapService, logger *zap.Logger) *MapHandler {
	return &MapHandler{amapSvc: amapSvc, logger: logger}
}

// POISearch 关键词搜索POI
func (h *MapHandler) POISearch(c *gin.Context) {
	keywords := c.Query("keywords")
	if keywords == "" {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "keywords is required"})
		return
	}
	city := c.Query("city")
	result, err := h.amapSvc.POISearch(keywords, city)
	if err != nil {
		h.logger.Error("POI search failed", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"code": 0, "data": result})
}

// PlaceAround 周边搜索POI
func (h *MapHandler) PlaceAround(c *gin.Context) {
	location := c.Query("location")
	if location == "" {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "location is required (lng,lat)"})
		return
	}
	keywords := c.Query("keywords")
	radius := c.DefaultQuery("radius", "1000")
	result, err := h.amapSvc.PlaceAround(location, keywords, radius)
	if err != nil {
		h.logger.Error("Place around failed", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"code": 0, "data": result})
}

// PlaceSuggestion 输入提示/自动补全
func (h *MapHandler) PlaceSuggestion(c *gin.Context) {
	keywords := c.Query("keywords")
	if keywords == "" {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "keywords is required"})
		return
	}
	city := c.Query("city")
	result, err := h.amapSvc.PlaceSuggestion(keywords, city)
	if err != nil {
		h.logger.Error("Place suggestion failed", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"code": 0, "data": result})
}

// StaticMap 生成静态地图URL
func (h *MapHandler) StaticMap(c *gin.Context) {
	center := c.Query("center")
	if center == "" {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "center is required (lng,lat)"})
		return
	}
	zoom := c.DefaultQuery("zoom", "14")
	size := c.DefaultQuery("size", "400x300")
	markers := c.Query("markers")
	result := h.amapSvc.StaticMapURL(center, zoom, size, markers)
	c.JSON(http.StatusOK, gin.H{"code": 0, "data": gin.H{"url": result}})
}

// RoutePlan 路线规划
func (h *MapHandler) RoutePlan(c *gin.Context) {
	origin := c.Query("origin")
	destination := c.Query("destination")
	if origin == "" || destination == "" {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "origin and destination are required (lng,lat)"})
		return
	}
	mode := c.DefaultQuery("mode", "driving")
	result, err := h.amapSvc.RoutePlan(origin, destination, mode)
	if err != nil {
		h.logger.Error("Route plan failed", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"code": 0, "data": result})
}
