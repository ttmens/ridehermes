package service

import (
	"context"
	"fmt"
	"strconv"

	"github.com/redis/go-redis/v9"
	"github.com/ridehermes/ride-hermes/internal/model"
	"github.com/ridehermes/ride-hermes/internal/repository"
)

type LocationService struct {
	locationRepo *repository.LocationRepo
	driverRepo   *repository.DriverRepo
	rdb          *redis.Client
}

func NewLocationService(locationRepo *repository.LocationRepo, driverRepo *repository.DriverRepo, rdb *redis.Client) *LocationService {
	return &LocationService{locationRepo: locationRepo, driverRepo: driverRepo, rdb: rdb}
}

type LocationUpdate struct {
	UserID    int64   `json:"user_id"`
	UserType  int8    `json:"user_type"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Accuracy  float64 `json:"accuracy"`
	Speed     float64 `json:"speed"`
	Bearing   float64 `json:"bearing"`
}

func (s *LocationService) UpdateLocation(ctx context.Context, loc *LocationUpdate) error {
	key := fmt.Sprintf("driver:location:%d", loc.UserID)
	s.rdb.HSet(ctx, key,
		"lat", loc.Latitude,
		"lng", loc.Longitude,
		"accuracy", loc.Accuracy,
		"speed", loc.Speed,
		"bearing", loc.Bearing,
	)
	s.rdb.Expire(ctx, key, 86400) // 24h TTL

	return nil
}

func (s *LocationService) PersistLocation(ctx context.Context, loc *LocationUpdate) error {
	m := &model.Location{
		UserID:    loc.UserID,
		UserType:  loc.UserType,
		Latitude:  loc.Latitude,
		Longitude: loc.Longitude,
		Accuracy:  loc.Accuracy,
		Speed:     loc.Speed,
		Bearing:   loc.Bearing,
	}
	return s.locationRepo.Create(ctx, m)
}

func (s *LocationService) getDriverLocationFromRedis(ctx context.Context, driverID int64) (map[string]string, error) {
	key := fmt.Sprintf("driver:location:%d", driverID)
	loc, err := s.rdb.HGetAll(ctx, key).Result()
	if err != nil {
		return nil, err
	}
	if len(loc) > 0 {
		return loc, nil
	}
	// Legacy: WS used to write driver:location:{user_id} before driver_id fix
	driver, derr := s.driverRepo.FindByID(ctx, driverID)
	if derr != nil || driver == nil {
		return loc, nil
	}
	legacyKey := fmt.Sprintf("driver:location:%d", driver.UserID)
	legacy, err := s.rdb.HGetAll(ctx, legacyKey).Result()
	return legacy, err
}

func (s *LocationService) GetDriverLocation(ctx context.Context, driverID int64) (map[string]string, error) {
	return s.getDriverLocationFromRedis(ctx, driverID)
}

type DriverLocationInfo struct {
	DriverID    int64   `json:"driver_id"`
	RealName    string  `json:"real_name"`
	Phone       string  `json:"phone"`
	PlateNumber string  `json:"plate_number"`
	CarType     int8    `json:"car_type"`
	Online      bool    `json:"online"`
	Latitude    float64 `json:"latitude"`
	Longitude   float64 `json:"longitude"`
	Accuracy    float64 `json:"accuracy"`
	Speed       float64 `json:"speed"`
	Bearing     float64 `json:"bearing"`
	UpdatedAt   string  `json:"updated_at"`
}

// GetOnlineDriverLocations 获取所有在线司机的位置信息
// 优化：使用 Redis Pipeline 批量获取位置，使用单次 DB 查询获取司机信息
func (s *LocationService) GetOnlineDriverLocations(ctx context.Context) ([]DriverLocationInfo, error) {
	driverIDs, err := s.rdb.ZRange(ctx, "driver:online", 0, -1).Result()
	if err != nil {
		return nil, err
	}
	if len(driverIDs) == 0 {
		return []DriverLocationInfo{}, nil
	}

	// 使用 Redis Pipeline 批量获取所有司机位置
	pipe := s.rdb.Pipeline()
	cmds := make(map[string]*redis.MapStringStringCmd, len(driverIDs))
	for _, idStr := range driverIDs {
		driverID, err := strconv.ParseInt(idStr, 10, 64)
		if err != nil {
			continue
		}
		key := fmt.Sprintf("driver:location:%d", driverID)
		cmds[idStr] = pipe.HGetAll(ctx, key)
	}
	_, err = pipe.Exec(ctx)
	if err != nil && err != redis.Nil {
		return nil, err
	}

	// 批量获取司机信息（单次 DB 查询）
	parsedIDs := make([]int64, 0, len(driverIDs))
	for _, idStr := range driverIDs {
		if id, err := strconv.ParseInt(idStr, 10, 64); err == nil {
			parsedIDs = append(parsedIDs, id)
		}
	}
	drivers, err := s.driverRepo.FindByIDs(ctx, parsedIDs)
	if err != nil {
		return nil, err
	}
	driverMap := make(map[int64]*model.Driver, len(drivers))
	for i := range drivers {
		driverMap[drivers[i].ID] = &drivers[i]
	}

	// 组装结果
	var results []DriverLocationInfo
	for idStr, cmd := range cmds {
		loc := cmd.Val()
		if len(loc) == 0 {
			continue
		}

		driverID, _ := strconv.ParseInt(idStr, 10, 64)
		lat, _ := strconv.ParseFloat(loc["lat"], 64)
		lng, _ := strconv.ParseFloat(loc["lng"], 64)
		accuracy, _ := strconv.ParseFloat(loc["accuracy"], 64)
		speed, _ := strconv.ParseFloat(loc["speed"], 64)
		bearing, _ := strconv.ParseFloat(loc["bearing"], 64)

		info := DriverLocationInfo{
			DriverID:  driverID,
			Online:    true,
			Latitude:  lat,
			Longitude: lng,
			Accuracy:  accuracy,
			Speed:     speed,
			Bearing:   bearing,
		}

		if driver, ok := driverMap[driverID]; ok {
			info.RealName = driver.RealName
			info.Phone = driver.User.Phone
			if driver.Vehicle.ID > 0 {
				info.PlateNumber = driver.Vehicle.PlateNumber
				info.CarType = driver.Vehicle.CarType
			}
		}

		results = append(results, info)
	}
	return results, nil
}
