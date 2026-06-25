package repository

import (
	"context"

	"github.com/ridehermes/ride-hermes/internal/model"
	"gorm.io/gorm"
)

type DriverAgentRepo struct {
	db *gorm.DB
}

func NewDriverAgentRepo(db *gorm.DB) *DriverAgentRepo {
	return &DriverAgentRepo{db: db}
}

func (r *DriverAgentRepo) Create(ctx context.Context, profile *model.DriverAgentProfile) error {
	return r.db.WithContext(ctx).Create(profile).Error
}

func (r *DriverAgentRepo) FindByDriverID(ctx context.Context, driverID int64) (*model.DriverAgentProfile, error) {
	var profile model.DriverAgentProfile
	err := r.db.WithContext(ctx).Where("driver_id = ?", driverID).First(&profile).Error
	return &profile, err
}

func (r *DriverAgentRepo) Update(ctx context.Context, driverID int64, updates map[string]interface{}) error {
	return r.db.WithContext(ctx).Model(&model.DriverAgentProfile{}).Where("driver_id = ?", driverID).Updates(updates).Error
}

func (r *DriverAgentRepo) FindOnlineDrivers(ctx context.Context) ([]model.DriverAgentProfile, error) {
	var profiles []model.DriverAgentProfile
	err := r.db.WithContext(ctx).Where("is_online = ?", true).Find(&profiles).Error
	return profiles, err
}
