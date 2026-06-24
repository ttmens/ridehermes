package service

import (
	"context"
	"fmt"
	"strconv"

	"github.com/redis/go-redis/v9"
	"github.com/ridehermes/ride-hermes/internal/config"
	"github.com/ridehermes/ride-hermes/internal/model"
	"github.com/ridehermes/ride-hermes/internal/repository"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

type DispatchService struct {
	dispatchLogRepo *repository.DispatchLogRepo
	orderRepo       *repository.OrderRepo
	driverRepo      *repository.DriverRepo
	cfg             *config.Config
	rdb             *redis.Client
	db              *gorm.DB
	logger          *zap.Logger
}

func NewDispatchService(
	dispatchLogRepo *repository.DispatchLogRepo,
	orderRepo *repository.OrderRepo,
	driverRepo *repository.DriverRepo,
	cfg *config.Config,
	rdb *redis.Client,
	db *gorm.DB,
	logger *zap.Logger,
) *DispatchService {
	return &DispatchService{
		dispatchLogRepo: dispatchLogRepo,
		orderRepo:       orderRepo,
		driverRepo:      driverRepo,
		cfg:             cfg,
		rdb:             rdb,
		db:              db,
		logger:          logger,
	}
}

func (s *DispatchService) AssignDriver(ctx context.Context, order *model.Order) (*model.Driver, error) {
	drivers, err := s.findActiveDriversByCarType(ctx, order.CarType)
	if err != nil || len(drivers) == 0 {
		// Fallback: match any active driver regardless of car type
		s.logger.Info("no drivers matching car type, falling back to any driver",
			zap.Int64("order_id", order.ID), zap.Int8("car_type", order.CarType))
		drivers, err = s.findAnyActiveDriver(ctx)
		if err != nil || len(drivers) == 0 {
			s.logger.Info("no available drivers", zap.Int64("order_id", order.ID))
			return nil, fmt.Errorf("暂无可用司机")
		}
	}

	drivers = s.sortByDispatchCount(ctx, drivers)

	selected := drivers[0]

	now := order.CreatedAt
	if err := s.orderRepo.Update(ctx, order.ID, map[string]interface{}{
		"status":      model.OrderStatusAssigned,
		"driver_id":   selected.ID,
		"assigned_at": now,
	}); err != nil {
		return nil, err
	}

	s.rdb.ZIncrBy(ctx, "driver:dispatch_count", 1, strconv.FormatInt(selected.ID, 10))

	log := &model.DispatchLog{
		OrderID:  order.ID,
		DriverID: selected.ID,
		Status:   model.DispatchStatusAssigned,
	}
	if err := s.dispatchLogRepo.Create(ctx, log); err != nil {
		s.logger.Error("failed to create dispatch log", zap.Error(err))
	}

	return &selected, nil
}

func (s *DispatchService) findActiveDriversByCarType(ctx context.Context, carType int8) ([]model.Driver, error) {
	var drivers []model.Driver
	err := s.db.WithContext(ctx).
		Joins("JOIN vehicles ON vehicles.driver_id = drivers.id").
		Where("drivers.status = ? AND vehicles.car_type = ?", model.DriverStatusActive, carType).
		Preload("User").Preload("Vehicle").
		Find(&drivers).Error
	return drivers, err
}

func (s *DispatchService) findAnyActiveDriver(ctx context.Context) ([]model.Driver, error) {
	var drivers []model.Driver
	err := s.db.WithContext(ctx).
		Joins("JOIN vehicles ON vehicles.driver_id = drivers.id").
		Where("drivers.status = ?", model.DriverStatusActive).
		Preload("User").Preload("Vehicle").
		Find(&drivers).Error
	return drivers, err
}

func (s *DispatchService) sortByDispatchCount(ctx context.Context, drivers []model.Driver) []model.Driver {
	// 使用 Redis Pipeline 批量获取派单次数（避免 N+1）
	pipe := s.rdb.Pipeline()
	cmds := make(map[int64]*redis.FloatCmd, len(drivers))
	for _, d := range drivers {
		cmds[d.ID] = pipe.ZScore(ctx, "driver:dispatch_count", strconv.FormatInt(d.ID, 10))
	}
	_, _ = pipe.Exec(ctx) // 忽略错误，默认为 0

	type driverScore struct {
		driver model.Driver
		count  float64
	}
	scores := make([]driverScore, 0, len(drivers))
	for _, d := range drivers {
		count := 0.0
		if cmd, ok := cmds[d.ID]; ok {
			count, _ = cmd.Result()
		}
		scores = append(scores, driverScore{driver: d, count: count})
	}
	// 按派单次数升序排序（次数少的优先）
	for i := 0; i < len(scores)-1; i++ {
		for j := i + 1; j < len(scores); j++ {
			if scores[j].count < scores[i].count {
				scores[i], scores[j] = scores[j], scores[i]
			}
		}
	}
	result := make([]model.Driver, len(scores))
	for i, s := range scores {
		result[i] = s.driver
	}
	return result
}

func (s *DispatchService) AcceptOrder(ctx context.Context, orderID, driverID int64) error {
	order, err := s.orderRepo.FindByID(ctx, orderID)
	if err != nil {
		return fmt.Errorf("订单不存在")
	}
	if order.Status != model.OrderStatusAssigned {
		return fmt.Errorf("订单状态不允许确认")
	}
	if order.DriverID == nil || *order.DriverID != driverID {
		return fmt.Errorf("无权操作此订单")
	}

	return s.orderRepo.Update(ctx, orderID, map[string]interface{}{
		"status": model.OrderStatusAccepted,
	})
}

func (s *DispatchService) DriverOnline(ctx context.Context, driverID int64, carType int8) {
	s.rdb.ZAdd(ctx, "driver:online", redis.Z{
		Score:  float64(driverID),
		Member: driverID,
	})
}

func (s *DispatchService) DriverOffline(ctx context.Context, driverID int64, carType int8) {
	s.rdb.ZRem(ctx, "driver:online", driverID)
	s.rdb.Del(ctx, fmt.Sprintf("driver:location:%d", driverID))
}
