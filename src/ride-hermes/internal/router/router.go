package router

import (
	"context"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"github.com/ridehermes/ride-hermes/internal/config"
	"github.com/ridehermes/ride-hermes/internal/handler"
	"github.com/ridehermes/ride-hermes/internal/middleware"
	"github.com/ridehermes/ride-hermes/internal/model"
	"github.com/ridehermes/ride-hermes/internal/repository"
	"github.com/ridehermes/ride-hermes/internal/service"
	ws "github.com/ridehermes/ride-hermes/internal/ws"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

func Setup(cfg *config.Config, db *gorm.DB, rdb *redis.Client, hub *ws.Hub) *gin.Engine {
	hub.SetConfig(cfg)
	logger := zap.L()
	hub.SetLogger(logger)

	// Repositories
	userRepo := repository.NewUserRepo(db)
	driverRepo := repository.NewDriverRepo(db)
	vehicleRepo := repository.NewVehicleRepo(db)
	orderRepo := repository.NewOrderRepo(db)
	locationRepo := repository.NewLocationRepo(db)
	dispatchLogRepo := repository.NewDispatchLogRepo(db)
	aiConvRepo := repository.NewAIConversationRepo(db)
	agentCredRepo := repository.NewAgentCredentialRepo(db)
	agentCallLogRepo := repository.NewAgentCallLogRepo(db)
	subscriptionRepo := repository.NewSubscriptionRepo(db)
	trustScoreRepo := repository.NewTrustScoreRepo(db)
	evalRepo := repository.NewEvaluationRepo(db)
	enterpriseRepo := repository.NewEnterpriseRepo(db)
	enterpriseEmployeeRepo := repository.NewEnterpriseEmployeeRepo(db)
	recurringTripRepo := repository.NewRecurringTripRepo(db)

	// Services
	userSvc := service.NewUserService(userRepo, driverRepo, vehicleRepo, cfg)
	driverSvc := service.NewDriverService(driverRepo, userRepo)
	orderSvc := service.NewOrderService(orderRepo)
	dispatchSvc := service.NewDispatchService(dispatchLogRepo, orderRepo, driverRepo, cfg, rdb, db, logger)
	locationSvc := service.NewLocationService(locationRepo, driverRepo, rdb)
	aiSvc := service.NewAIService(cfg, aiConvRepo, rdb)
	adminSvc := service.NewAdminService(userRepo, driverRepo, vehicleRepo, orderRepo, db)
	agentSvc := service.NewAgentService(agentCredRepo, agentCallLogRepo, userRepo)
	amapSvc := service.NewAmapService(cfg.Amap.APIKey)
	matchingEngine := service.NewMatchingEngine(orderRepo, driverRepo, dispatchLogRepo, cfg, rdb, db, logger)
	subscriptionSvc := service.NewSubscriptionService(subscriptionRepo, driverRepo)
	trustScoreSvc := service.NewTrustScoreService(trustScoreRepo, evalRepo, logger)
	enterpriseSvc := service.NewEnterpriseService(enterpriseRepo, enterpriseEmployeeRepo, orderRepo, logger)
	recurringTripSvc := service.NewRecurringTripService(recurringTripRepo, orderSvc, logger)

	h := handler.NewHandler(cfg, db, hub, logger,
		userSvc, driverSvc, orderSvc, dispatchSvc, locationSvc, aiSvc, adminSvc,
		agentSvc, amapSvc, matchingEngine, trustScoreSvc, enterpriseSvc, recurringTripSvc, subscriptionSvc)
	mapHandler := handler.NewMapHandler(amapSvc, logger)

	// Setup Gin
	if cfg.Server.Mode == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.New()
	r.Use(middleware.CORSMiddleware())
	r.Use(middleware.LoggerMiddleware(logger))
	r.Use(gin.Recovery())

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// Public auth routes
	auth := r.Group("/api/v1/auth")
	{
		auth.POST("/login", h.AuthLogin)
		auth.POST("/login-or-register", h.AuthLoginOrRegister)
		auth.POST("/refresh", h.AuthRefresh)
	}

	// WebSocket
	r.GET("/ws/location", h.HandleWebSocket)

	// Admin routes
	authMW := middleware.AuthMiddleware(cfg)
	admin := r.Group("/api/v1/admin")
	admin.Use(authMW, middleware.RoleMiddleware(model.RoleAdmin))
	{
		admin.POST("/users/passenger", h.AdminCreatePassenger)
		admin.POST("/users/driver", h.AdminCreateDriver)
		admin.GET("/users", h.AdminListUsers)
		admin.GET("/users/:id", h.AdminGetUser)
		admin.PUT("/users/:id/status", h.AdminUpdateUserStatus)
		admin.GET("/drivers", h.AdminListDrivers)
		admin.GET("/drivers/:id", h.AdminGetDriver)
		admin.PUT("/drivers/:id", h.AdminUpdateDriver)
		admin.GET("/orders", h.AdminListOrders)
		admin.GET("/orders/:id", h.AdminGetOrder)
		admin.GET("/locations/drivers", h.AdminGetDriverLocations)
		admin.GET("/locations/passengers", h.AdminGetPassengerLocations)
		// Agent management
		admin.GET("/agents/credentials", h.AdminListAgentCredentials)
		admin.POST("/agents/credentials", h.AdminGenerateAgentKey)
		admin.PUT("/agents/credentials/:id/revoke", h.AdminRevokeAgentKey)
		admin.GET("/subscriptions", h.ListSubscriptions)
		admin.GET("/trust-scores", h.AdminListTrustScores)
		admin.GET("/trust-scores/anomalies", h.AdminGetAnomalies)
		admin.GET("/enterprises", h.AdminListEnterprises)
		admin.POST("/enterprises", h.AdminCreateEnterprise)
		admin.GET("/enterprises/:id", h.AdminGetEnterprise)
		admin.POST("/enterprises/:id/employees", h.AdminAddEnterpriseEmployee)
		admin.GET("/enterprises/:id/bill", h.AdminGetEnterpriseBill)
		admin.GET("/subscriptions/stats", h.GetGlobalSubscriptionStats)
		admin.GET("/subscriptions/:driver_id/stats", h.GetSubscriptionByDriver)
		admin.GET("/agents/logs", h.AdminListAgentLogs)
		admin.GET("/notifications", h.AdminListNotifications)
	}

	// Passenger routes
	passenger := r.Group("/api/v1/passenger")
	passenger.Use(authMW, middleware.RoleMiddleware(model.RolePassenger))
	{
		passenger.POST("/matching/demands", h.CreateDemand)
		passenger.GET("/matching/demands/:order_id/matches", h.GetDemandMatches)
		passenger.POST("/matching/demands/:order_id/confirm", h.ConfirmMatch)
		passenger.POST("/orders", h.PassengerCreateOrder)
		passenger.GET("/orders", h.PassengerListOrders)
		passenger.GET("/orders/:id", h.PassengerGetOrder)
		passenger.POST("/orders/:id/cancel", h.PassengerCancelOrder)
		passenger.GET("/driver-location/:order_id", h.PassengerGetDriverLocation)
		passenger.POST("/ai/chat", h.PassengerAIChat)
		passenger.GET("/ai/sessions", h.PassengerAISessions)
		passenger.GET("/user/profile", h.GetProfile)
		passenger.PUT("/user/profile", h.UpdateProfile)
		// 周期出行 (A2A Intent)
		passenger.POST("/recurring-trips", h.CreateRecurringTrip)
		passenger.GET("/recurring-trips", h.ListRecurringTrips)
		passenger.DELETE("/recurring-trips/:id", h.DeleteRecurringTrip)
		// Agent key self-service (乘客自助管理 API Key)
		passengerAgent := passenger.Group("/agent")
		{
			passengerAgent.POST("/keys", h.PassengerGenerateAgentKey)
			passengerAgent.GET("/keys", h.PassengerListAgentKeys)
			passengerAgent.DELETE("/keys/:id", h.PassengerRevokeAgentKey)
		}
	}

	// Driver routes
	driver := r.Group("/api/v1/driver")
	driver.Use(authMW, middleware.RoleMiddleware(model.RoleDriver))
	{
		driver.PUT("/online", h.DriverOnline)
		driver.PUT("/offline", h.DriverOffline)
		driver.POST("/matching/demands/:order_id/offers", h.SubmitOffer)
		driver.POST("/orders/:id/accept", h.DriverAcceptOrder)
		driver.POST("/orders/:id/reject", h.DriverRejectOrder)
		driver.POST("/orders/:id/arrive", h.DriverArrive)
		driver.POST("/orders/:id/start", h.DriverStartTrip)
		driver.POST("/orders/:id/complete", h.DriverCompleteOrder)
		driver.GET("/orders", h.DriverListOrders)
		driver.GET("/orders/:id", h.DriverGetOrder)
		driver.POST("/subscriptions", h.CreateSubscription)
		driver.GET("/subscriptions", h.GetDriverSubscription)
		driver.GET("/trust-score", h.GetDriverTrustScore)
		driver.GET("/evaluations", h.GetDriverEvaluations)
		driver.GET("/user/profile", h.GetProfile)
		driver.PUT("/user/profile", h.UpdateProfile)
	}

	// Agent routes (X-API-Key + X-User-ID auth)
	agent := r.Group("/api/v1/agent")
	agent.Use(middleware.AgentAuthMiddleware(func(ctx context.Context, apiKey string) (*middleware.AgentCredentialInfo, error) {
		cred, err := agentSvc.ValidateAPIKey(ctx, apiKey)
		if err != nil {
			return nil, err
		}
		return &middleware.AgentCredentialInfo{
			ID:          cred.ID,
			UserID:      cred.UserID,
			AgentName:   cred.AgentName,
			Permissions: []string(cred.Permissions),
		}, nil
	}))
	agent.Use(middleware.RateLimitMiddleware(rdb, func(c *gin.Context) string {
		return c.GetString("agent_name") + ":" + strconv.FormatInt(c.GetInt64("user_id"), 10)
	}, 60, time.Minute))
	{
		agent.POST("/orders/estimate", h.AgentEstimateOrder)
		agent.POST("/orders", h.AgentCreateOrder)
		agent.GET("/orders", h.AgentListOrders)
		agent.GET("/orders/:id", h.AgentGetOrder)
		agent.POST("/orders/:id/cancel", h.AgentCancelOrder)
	}


	// Map routes (需要认证)
	mapRoutes := r.Group("/api/v1/maps")
	mapRoutes.Use(authMW)
	{
		mapRoutes.GET("/poi/search", mapHandler.POISearch)
		mapRoutes.GET("/poi/around", mapHandler.PlaceAround)
		mapRoutes.GET("/place/suggestion", mapHandler.PlaceSuggestion)
		mapRoutes.GET("/static", mapHandler.StaticMap)
		mapRoutes.GET("/route", mapHandler.RoutePlan)
	}

	return r
}
