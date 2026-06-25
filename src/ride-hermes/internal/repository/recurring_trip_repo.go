package repository

import (
	"context"
	"time"

	"github.com/ridehermes/ride-hermes/internal/model"
	"gorm.io/gorm"
)

type RecurringTripRepo struct {
	db *gorm.DB
}

func NewRecurringTripRepo(db *gorm.DB) *RecurringTripRepo {
	return &RecurringTripRepo{db: db}
}

func (r *RecurringTripRepo) Create(ctx context.Context, trip *model.RecurringTrip) error {
	return r.db.WithContext(ctx).Create(trip).Error
}

func (r *RecurringTripRepo) FindByPassengerID(ctx context.Context, passengerID int64) ([]model.RecurringTrip, error) {
	var trips []model.RecurringTrip
	err := r.db.WithContext(ctx).Where("passenger_id = ? AND is_active = ?", passengerID, true).Find(&trips).Error
	return trips, err
}

func (r *RecurringTripRepo) FindDueForCreation(ctx context.Context) ([]model.RecurringTrip, error) {
	now := time.Now()
	var trips []model.RecurringTrip
	err := r.db.WithContext(ctx).
		Where("is_active = ? AND start_date <= ? AND end_date >= ?", true, now, now).
		Find(&trips).Error
	return trips, err
}

func (r *RecurringTripRepo) Update(ctx context.Context, id int64, updates map[string]interface{}) error {
	return r.db.WithContext(ctx).Model(&model.RecurringTrip{}).Where("id = ?", id).Updates(updates).Error
}

func (r *RecurringTripRepo) Delete(ctx context.Context, id int64) error {
	return r.db.WithContext(ctx).Delete(&model.RecurringTrip{}, id).Error
}
