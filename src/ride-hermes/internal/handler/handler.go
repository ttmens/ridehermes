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

	UserSvc         *service.UserService
	DriverSvc       *service.DriverService
	OrderSvc        *service.OrderService
	DispatchSvc     *service.DispatchService
	LocationSvc     *service.LocationService
	AISvc           *service.AIService
	AdminSvc        *service.AdminService
	AgentSvc        *service.AgentService
	AmapSvc         *service.AmapService
	MatchingEngine  *service.MatchingEngine
	TrustScoreSvc      *service.TrustScoreService
	EnterpriseSvc       *service.EnterpriseService
	RecurringTripSvc  *service.RecurringTripService
	SubscriptionSvc *service.SubscriptionService
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
	matchingEngine *service.MatchingEngine,
	trustScoreSvc    *service.TrustScoreService,
enterpriseSvc      *service.EnterpriseService,
	recurringTripSvc   *service.RecurringTripService,
	subscriptionSvc *service.SubscriptionService,
) *Handler {
	return &Handler{
		cfg:               cfg,
		db:                db,
		hub:               hub,
		logger:            logger,
		UserSvc:           userSvc,
		DriverSvc:         driverSvc,
		OrderSvc:          orderSvc,
		DispatchSvc:       dispatchSvc,
		LocationSvc:       locationSvc,
		AISvc:             aiSvc,
		AdminSvc:          adminSvc,
		AgentSvc:          agentSvc,
		AmapSvc:           amapSvc,
		MatchingEngine:    matchingEngine,
		TrustScoreSvc:     trustScoreSvc,
		SubscriptionSvc:   subscriptionSvc,
		EnterpriseSvc:     enterpriseSvc,
		RecurringTripSvc:  recurringTripSvc,
	}
}
