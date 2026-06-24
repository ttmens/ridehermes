package repository

import (
	"context"

	"github.com/ridehermes/ride-hermes/internal/model"
	"gorm.io/gorm"
)

type VehicleRepo struct{ db *gorm.DB }

func NewVehicleRepo(db *gorm.DB) *VehicleRepo { return &VehicleRepo{db: db} }

func (r *VehicleRepo) Create(ctx context.Context, v *model.Vehicle) error {
	return r.db.WithContext(ctx).Create(v).Error
}

func (r *VehicleRepo) FindByPlateNumber(ctx context.Context, plate string) (*model.Vehicle, error) {
	var vehicle model.Vehicle
	err := r.db.WithContext(ctx).Where("plate_number = ?", plate).First(&vehicle).Error
	if err != nil {
		return nil, err
	}
	return &vehicle, nil
}

func (r *VehicleRepo) FindByDriverID(ctx context.Context, driverID int64) (*model.Vehicle, error) {
	var vehicle model.Vehicle
	err := r.db.WithContext(ctx).Where("driver_id = ?", driverID).First(&vehicle).Error
	if err != nil {
		return nil, err
	}
	return &vehicle, nil
}

func (r *VehicleRepo) Update(ctx context.Context, driverID int64, updates map[string]interface{}) error {
	return r.db.WithContext(ctx).Model(&model.Vehicle{}).Where("driver_id = ?", driverID).Updates(updates).Error
}
