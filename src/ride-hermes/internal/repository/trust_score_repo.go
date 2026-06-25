package repository

import (
	"context"

	"github.com/ridehermes/ride-hermes/internal/model"
	"gorm.io/gorm"
)

type TrustScoreRepo struct {
	db *gorm.DB
}

func NewTrustScoreRepo(db *gorm.DB) *TrustScoreRepo {
	return &TrustScoreRepo{db: db}
}

func (r *TrustScoreRepo) Create(ctx context.Context, ts *model.TrustScore) error {
	return r.db.WithContext(ctx).Create(ts).Error
}

func (r *TrustScoreRepo) FindByDriverID(ctx context.Context, driverID int64) (*model.TrustScore, error) {
	var ts model.TrustScore
	err := r.db.WithContext(ctx).Where("driver_id = ?", driverID).First(&ts).Error
	return &ts, err
}

func (r *TrustScoreRepo) Update(ctx context.Context, driverID int64, updates map[string]interface{}) error {
	return r.db.WithContext(ctx).Model(&model.TrustScore{}).Where("driver_id = ?", driverID).Updates(updates).Error
}

func (r *TrustScoreRepo) FindAll(ctx context.Context) ([]model.TrustScore, error) {
	var scores []model.TrustScore
	err := r.db.WithContext(ctx).Order("total_score DESC").Find(&scores).Error
	return scores, err
}

func (r *TrustScoreRepo) Upsert(ctx context.Context, ts *model.TrustScore) error {
	var existing model.TrustScore
	result := r.db.WithContext(ctx).Where("driver_id = ?", ts.DriverID).First(&existing)
	if result.Error != nil {
		return r.db.WithContext(ctx).Create(ts).Error
	}
	return r.db.WithContext(ctx).Model(&existing).Updates(map[string]interface{}{
		"total_score":  ts.TotalScore,
		"punctuality":  ts.Punctuality,
		"service":      ts.Service,
		"driving":      ts.Driving,
		"completion":   ts.Completion,
		"total_orders": ts.TotalOrders,
	}).Error
}
