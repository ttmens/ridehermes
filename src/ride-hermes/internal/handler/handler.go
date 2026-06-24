package handler

import (
	"github.com/ridehermes/ride-hermes/internal/config"
	"github.com/ridehermes/ride-hermes/internal/service"
	ws "github.com/ridehermes/ride-hermes/internal/ws"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

type Handler struct {
	cfg    *config.Config
	db     *gorm.DB
	hub    *ws.Hub
	logger *zap.Logger

	UserSvc     *service.UserService
	DriverSvc   *service.DriverService
	OrderSvc    *service.OrderService
	DispatchSvc *service.DispatchService
	LocationSvc *service.LocationService
	AISvc       *service.AIService
	AdminSvc    *service.AdminService
	AgentSvc    *service.AgentService
	AmapSvc     *service.AmapService
}

func NewHandler(
	cfg *config.Config,
	db *gorm.DB,
	hub *ws.Hub,
	logger *zap.Logger,
	userSvc *service.UserService,
	driverSvc *service.DriverService,
	orderSvc *service.OrderService,
	dispatchSvc *service.DispatchService,
	locationSvc *service.LocationService,
	aiSvc *service.AIService,
	adminSvc *service.AdminService,
	agentSvc *service.AgentService,
	amapSvc *service.AmapService,
) *Handler {
	return &Handler{
		cfg:         cfg,
		db:          db,
		hub:         hub,
		logger:      logger,
		UserSvc:     userSvc,
		DriverSvc:   driverSvc,
		OrderSvc:    orderSvc,
		DispatchSvc: dispatchSvc,
		LocationSvc: locationSvc,
		AISvc:       aiSvc,
		AdminSvc:    adminSvc,
		AgentSvc:    agentSvc,
		AmapSvc:     amapSvc,
	}
}
