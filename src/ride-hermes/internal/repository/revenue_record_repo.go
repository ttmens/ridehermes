package repository

import (
	"context"
	"time"

	"github.com/ridehermes/ride-hermes/internal/model"
	"gorm.io/gorm"
)

type RevenueRecordRepo struct{ db *gorm.DB }

func NewRevenueRecordRepo(db *gorm.DB) *RevenueRecordRepo {
	return &RevenueRecordRepo{db: db}
}

func (r *RevenueRecordRepo) Create(ctx context.Context, record *model.RevenueRecord) error {
	return r.db.WithContext(ctx).Create(record).Error
}

func (r *RevenueRecordRepo) FindByID(ctx context.Context, id int64) (*model.RevenueRecord, error) {
	var record model.RevenueRecord
	err := r.db.WithContext(ctx).Preload("Driver.User").Preload("Order").First(&record, id).Error
	if err != nil {
		return nil, err
	}
	return &record, nil
}

func (r *RevenueRecordRepo) FindByDriverID(ctx context.Context, driverID int64, offset, limit int) ([]model.RevenueRecord, int64, error) {
	var records []model.RevenueRecord
	var total int64
	query := r.db.WithContext(ctx).Model(&model.RevenueRecord{}).Where("driver_id = ?", driverID)
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := query.Preload("Driver.User").Preload("Order").
		Offset(offset).Limit(limit).Order("id DESC").Find(&records).Error
	return records, total, err
}

func (r *RevenueRecordRepo) FindByOrderID(ctx context.Context, orderID int64) ([]model.RevenueRecord, error) {
	var records []model.RevenueRecord
	err := r.db.WithContext(ctx).Preload("Driver.User").
		Where("order_id = ?", orderID).Order("id DESC").Find(&records).Error
	return records, err
}

func (r *RevenueRecordRepo) List(ctx context.Context, driverID *int64, revType *string, offset, limit int) ([]model.RevenueRecord, int64, error) {
	var records []model.RevenueRecord
	var total int64
	query := r.db.WithContext(ctx).Model(&model.RevenueRecord{})
	if driverID != nil {
		query = query.Where("driver_id = ?", *driverID)
	}
	if revType != nil {
		query = query.Where("type = ?", *revType)
	}
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := query.Preload("Driver.User").Preload("Order").
		Offset(offset).Limit(limit).Order("id DESC").Find(&records).Error
	return records, total, err
}

func (r *RevenueRecordRepo) Update(ctx context.Context, id int64, updates map[string]interface{}) error {
	return r.db.WithContext(ctx).Model(&model.RevenueRecord{}).Where("id = ?", id).Updates(updates).Error
}

func (r *RevenueRecordRepo) UpdateStatus(ctx context.Context, id int64, status int8) error {
	return r.db.WithContext(ctx).Model(&model.RevenueRecord{}).Where("id = ?", id).
		Update("status", status).Error
}

func (r *RevenueRecordRepo) Delete(ctx context.Context, id int64) error {
	return r.db.WithContext(ctx).Delete(&model.RevenueRecord{}, id).Error
}

func (r *RevenueRecordRepo) SumByDriver(ctx context.Context, driverID int64, revType string, from, to time.Time) (float64, error) {
	var sum float64
	err := r.db.WithContext(ctx).Model(&model.RevenueRecord{}).
		Where("driver_id = ? AND type = ? AND created_at BETWEEN ? AND ?", driverID, revType, from, to).
		Select("COALESCE(SUM(amount), 0)").Scan(&sum).Error
	return sum, err
}
