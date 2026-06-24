package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/ridehermes/ride-hermes/internal/config"
	"github.com/ridehermes/ride-hermes/internal/model"
	"github.com/ridehermes/ride-hermes/internal/router"
	ws "github.com/ridehermes/ride-hermes/internal/ws"
	"go.uber.org/zap"
	"gorm.io/driver/mysql"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	gormlogger "gorm.io/gorm/logger"
)

func main() {
	migrateFlag := flag.Bool("migrate", false, "run database migrations")
	flag.Parse()

	// Load config
	cfg, err := config.Load("configs/config.yaml")
	if err != nil {
		log.Fatalf("failed to load config: %v", err)
	}

	// Init logger
	logger := initLogger(cfg)
	defer logger.Sync()
	zap.ReplaceGlobals(logger)

	// Init database
	db, err := initDB(cfg)
	if err != nil {
		logger.Fatal("failed to connect database", zap.Error(err))
	}

	if *migrateFlag {
		if err := model.AutoMigrate(db); err != nil {
			logger.Fatal("failed to migrate database", zap.Error(err))
		}
		logger.Info("database migration completed")
		return
	}

	// Init Redis
	rdb := initRedis(cfg)

	// Init WebSocket Hub
	hub := ws.NewHub(rdb)
	go hub.Run()

	// Init router
	r := router.Setup(cfg, db, rdb, hub)

	// Start server
	srv := &http.Server{
		Addr:    fmt.Sprintf(":%d", cfg.Server.Port),
		Handler: r,
	}

	go func() {
		logger.Info("server starting", zap.Int("port", cfg.Server.Port))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("server failed", zap.Error(err))
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal("server forced to shutdown", zap.Error(err))
	}
	logger.Info("server exited")
}

func initLogger(cfg *config.Config) *zap.Logger {
	var logger *zap.Logger
	if cfg.Log.Format == "json" {
		logger, _ = zap.NewProduction()
	} else {
		logger, _ = zap.NewDevelopment()
	}
	return logger
}

func initDB(cfg *config.Config) (*gorm.DB, error) {
	level := gormlogger.Warn
	if cfg.Server.Mode == "debug" {
		level = gormlogger.Info
	}

	// SQLite 模式
	if cfg.Database.Type == "sqlite" {
		dbPath := cfg.Database.DBName
		if dbPath == "" {
			dbPath = "ridehermes.db"
		}
		return gorm.Open(sqlite.Open(dbPath), &gorm.Config{
			Logger: gormlogger.Default.LogMode(level),
		})
	}

	// MySQL 模式（默认）
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		cfg.Database.User, cfg.Database.Password,
		cfg.Database.Host, cfg.Database.Port,
		cfg.Database.DBName,
	)

	return gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: gormlogger.Default.LogMode(level),
	})
}

func initRedis(cfg *config.Config) *redis.Client {
	return redis.NewClient(&redis.Options{
		Addr:     cfg.Redis.Addr,
		Password: cfg.Redis.Password,
		DB:       cfg.Redis.DB,
	})
}
