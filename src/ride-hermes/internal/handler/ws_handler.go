package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/ridehermes/ride-hermes/internal/common"
	ws "github.com/ridehermes/ride-hermes/internal/ws"
	"go.uber.org/zap"
	"nhooyr.io/websocket"
)

func (h *Handler) HandleWebSocket(c *gin.Context) {
	token := c.Query("token")
	if token == "" {
		common.ErrorWithStatus(c, http.StatusUnauthorized, common.CodeUnauthorized, "未提供认证Token")
		return
	}

	claims, err := h.hub.AuthenticateWS(token)
	if err != nil {
		common.ErrorWithStatus(c, http.StatusUnauthorized, common.CodeTokenExpired, "Token无效")
		return
	}

	conn, err := websocket.Accept(c.Writer, c.Request, nil)
	if err != nil {
		h.logger.Error("websocket accept failed", zap.Error(err))
		return
	}

	client := ws.NewClient(h.hub, conn, claims.UserID, claims.Role)
	client.SetLogger(h.logger)

	// If driver, bind drivers.id for location redis key consistency
	if claims.Role == 3 {
		driver, _ := h.DriverSvc.GetDriverByUserID(c.Request.Context(), claims.UserID)
		if driver != nil {
			client.SetDriverID(driver.ID)
			h.hub.DriverOnline(driver.ID, 1)
			defer h.hub.DriverOffline(driver.ID, 1)
		}
	}

	h.hub.RegisterClient(claims.UserID, client)
	defer h.hub.UnregisterClient(claims.UserID)

	go client.WritePump()
	client.ReadPump()
}
