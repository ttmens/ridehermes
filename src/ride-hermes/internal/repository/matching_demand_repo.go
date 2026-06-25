package repository

import (
	"context"

	"github.com/ridehermes/ride-hermes/internal/model"
	"gorm.io/gorm"
)

type MatchingDemandRepo struct{ db *gorm.DB }

func NewMatchingDemandRepo(db *gorm.DB) *MatchingDemandRepo {
	return &MatchingDemandRepo{db: db}
}

func (r *MatchingDemandRepo) Create(ctx context.Context, demand *model.MatchingDemand) error {
	return r.db.WithContext(ctx).Create(demand).Error
}

func (r *MatchingDemandRepo) FindByID(ctx context.Context, id int64) (*model.MatchingDemand, error) {
	var demand model.MatchingDemand
	err := r.db.WithContext(ctx).Preload("Passenger").First(&demand, id).Error
	if err != nil {
		return nil, err
	}
	return &demand, nil
}

func (r *MatchingDemandRepo) FindByPassengerID(ctx context.Context, passengerID int64, offset, limit int) ([]model.MatchingDemand, int64, error) {
	var demands []model.MatchingDemand
	var total int64
	query := r.db.WithContext(ctx).Model(&model.MatchingDemand{}).Where("passenger_id = ?", passengerID)
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := query.Preload("Passenger").Offset(offset).Limit(limit).Order("id DESC").Find(&demands).Error
	return demands, total, err
}

func (r *MatchingDemandRepo) ListByStatus(ctx context.Context, status int8, offset, limit int) ([]model.MatchingDemand, int64, error) {
	var demands []model.MatchingDemand
	var total int64
	query := r.db.WithContext(ctx).Model(&model.MatchingDemand{}).Where("status = ?", status)
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := query.Preload("Passenger").Offset(offset).Limit(limit).Order("id DESC").Find(&demands).Error
	return demands, total, err
}

func (r *MatchingDemandRepo) Update(ctx context.Context, id int64, updates map[string]interface{}) error {
	return r.db.WithContext(ctx).Model(&model.MatchingDemand{}).Where("id = ?", id).Updates(updates).Error
}

func (r *MatchingDemandRepo) UpdateStatus(ctx context.Context, id int64, status int8) error {
	return r.db.WithContext(ctx).Model(&model.MatchingDemand{}).Where("id = ?", id).
		Update("status", status).Error
}

func (r *MatchingDemandRepo) Delete(ctx context.Context, id int64) error {
	return r.db.WithContext(ctx).Delete(&model.MatchingDemand{}, id).Error
}
