package service

import (
	"context"
	"fmt"

	"github.com/ridehermes/ride-hermes/internal/model"
	"github.com/ridehermes/ride-hermes/internal/repository"
)

type DriverService struct {
	driverRepo *repository.DriverRepo
	userRepo   *repository.UserRepo
}

func NewDriverService(driverRepo *repository.DriverRepo, userRepo *repository.UserRepo) *DriverService {
	return &DriverService{driverRepo: driverRepo, userRepo: userRepo}
}

func (s *DriverService) GetDriverByUserID(ctx context.Context, userID int64) (*model.Driver, error) {
	return s.driverRepo.FindByUserID(ctx, userID)
}

func (s *DriverService) GetDriverByID(ctx context.Context, id int64) (*model.Driver, error) {
	return s.driverRepo.FindByID(ctx, id)
}

func (s *DriverService) ListDrivers(ctx context.Context, status *int8, offset, limit int) ([]model.Driver, int64, error) {
	return s.driverRepo.List(ctx, status, offset, limit)
}

func (s *DriverService) UpdateStatus(ctx context.Context, id int64, status int8) error {
	return s.driverRepo.UpdateStatus(ctx, id, status)
}

type OnlineOfflineReq struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	CarType   int8    `json:"car_type"`
}

func (s *DriverService) VerifyDriverActive(ctx context.Context, userID int64) (*model.Driver, error) {
	driver, err := s.driverRepo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("司机不存在")
	}
	if driver.Status != model.DriverStatusActive {
		return nil, fmt.Errorf("司机状态不可接单")
	}
	return driver, nil
}
