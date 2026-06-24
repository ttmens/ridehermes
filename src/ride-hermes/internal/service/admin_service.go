package service

import (
	"context"

	"github.com/ridehermes/ride-hermes/internal/model"
	"github.com/ridehermes/ride-hermes/internal/repository"
	"gorm.io/gorm"
)

type AdminService struct {
	userRepo    *repository.UserRepo
	driverRepo  *repository.DriverRepo
	vehicleRepo *repository.VehicleRepo
	orderRepo   *repository.OrderRepo
	db          *gorm.DB
}

func NewAdminService(
	userRepo *repository.UserRepo,
	driverRepo *repository.DriverRepo,
	vehicleRepo *repository.VehicleRepo,
	orderRepo *repository.OrderRepo,
	db *gorm.DB,
) *AdminService {
	return &AdminService{
		userRepo:    userRepo,
		driverRepo:  driverRepo,
		vehicleRepo: vehicleRepo,
		orderRepo:   orderRepo,
		db:          db,
	}
}

func (s *AdminService) ListUsers(ctx context.Context, role *int8, offset, limit int) ([]model.User, int64, error) {
	if role != nil {
		return s.userRepo.ListByRole(ctx, *role, offset, limit)
	}
	return s.userRepo.ListAll(ctx, offset, limit)
}

func (s *AdminService) GetUser(ctx context.Context, id int64) (*model.User, error) {
	return s.userRepo.FindByID(ctx, id)
}

func (s *AdminService) UpdateUserStatus(ctx context.Context, id int64, status int8) error {
	return s.userRepo.UpdateStatus(ctx, id, status)
}

func (s *AdminService) ListOrders(ctx context.Context, status *int8, offset, limit int) ([]model.Order, int64, error) {
	return s.orderRepo.ListAll(ctx, status, offset, limit)
}

func (s *AdminService) GetOrder(ctx context.Context, id int64) (*model.Order, error) {
	return s.orderRepo.FindByID(ctx, id)
}

type UpdateDriverReq struct {
	RealName  string `json:"real_name"`
	IDCardNo  string `json:"id_card_no"`
	LicenseNo string `json:"license_no"`
	Status    int8   `json:"status"`
	PlateNumber string `json:"plate_number"`
	Brand     string `json:"brand"`
	ModelName string `json:"model_name"`
	Color     string `json:"color"`
	CarType   int8   `json:"car_type"`
}

func (s *AdminService) UpdateDriver(ctx context.Context, id int64, req *UpdateDriverReq) error {
	return s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		driverUpdates := map[string]interface{}{
			"real_name":   req.RealName,
			"id_card_no":  req.IDCardNo,
			"license_no":  req.LicenseNo,
			"status":      req.Status,
		}
		if err := tx.Model(&model.Driver{}).Where("id = ?", id).Updates(driverUpdates).Error; err != nil {
			return err
		}

		vehicleUpdates := map[string]interface{}{
			"plate_number": req.PlateNumber,
			"brand":        req.Brand,
			"model":        req.ModelName,
			"color":        req.Color,
			"car_type":     req.CarType,
		}
		return tx.Model(&model.Vehicle{}).Where("driver_id = ?", id).Updates(vehicleUpdates).Error
	})
}
