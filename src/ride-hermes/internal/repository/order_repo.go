package repository

import (
	"context"
	"time"

	"github.com/ridehermes/ride-hermes/internal/model"
	"gorm.io/gorm"
)

type OrderRepo struct{ db *gorm.DB }

func NewOrderRepo(db *gorm.DB) *OrderRepo { return &OrderRepo{db: db} }

func (r *OrderRepo) Create(ctx context.Context, order *model.Order) error {
	return r.db.WithContext(ctx).Create(order).Error
}

func (r *OrderRepo) FindByID(ctx context.Context, id int64) (*model.Order, error) {
	var order model.Order
	err := r.db.WithContext(ctx).Preload("Passenger").Preload("Driver.User").
		First(&order, id).Error
	if err != nil {
		return nil, err
	}
	return &order, nil
}

func (r *OrderRepo) FindByOrderNo(ctx context.Context, orderNo string) (*model.Order, error) {
	var order model.Order
	err := r.db.WithContext(ctx).Where("order_no = ?", orderNo).First(&order).Error
	if err != nil {
		return nil, err
	}
	return &order, nil
}

func (r *OrderRepo) ListByPassenger(ctx context.Context, passengerID int64, offset, limit int) ([]model.Order, int64, error) {
	var orders []model.Order
	var total int64
	query := r.db.WithContext(ctx).Model(&model.Order{}).Where("passenger_id = ?", passengerID)
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := query.Preload("Passenger").Preload("Driver.User").Preload("Driver.Vehicle").
		Offset(offset).Limit(limit).Order("id DESC").Find(&orders).Error
	return orders, total, err
}

func (r *OrderRepo) ListByDriver(ctx context.Context, driverID int64, offset, limit int) ([]model.Order, int64, error) {
	var orders []model.Order
	var total int64
	query := r.db.WithContext(ctx).Model(&model.Order{}).Where("driver_id = ?", driverID)
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := query.Preload("Passenger").Preload("Driver.User").Preload("Driver.Vehicle").
		Offset(offset).Limit(limit).Order("id DESC").Find(&orders).Error
	return orders, total, err
}

func (r *OrderRepo) ListAll(ctx context.Context, status *int8, offset, limit int) ([]model.Order, int64, error) {
	var orders []model.Order
	var total int64
	query := r.db.WithContext(ctx).Model(&model.Order{})
	if status != nil {
		query = query.Where("status = ?", *status)
	}
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := query.Preload("Passenger").Preload("Driver.User").Preload("Driver.Vehicle").
		Offset(offset).Limit(limit).Order("id DESC").Find(&orders).Error
	return orders, total, err
}

func (r *OrderRepo) UpdateStatus(ctx context.Context, id int64, status int8) error {
	return r.db.WithContext(ctx).Model(&model.Order{}).Where("id = ?", id).
		Update("status", status).Error
}

func (r *OrderRepo) Update(ctx context.Context, id int64, updates map[string]interface{}) error {
	return r.db.WithContext(ctx).Model(&model.Order{}).Where("id = ?", id).
		Updates(updates).Error
}

func (r *OrderRepo) FindByDriverAndStatus(ctx context.Context, driverID int64, statuses ...int8) (*model.Order, error) {
	var order model.Order
	err := r.db.WithContext(ctx).Where("driver_id = ? AND status IN ?", driverID, statuses).
		First(&order).Error
	if err != nil {
		return nil, err
	}
	return &order, nil
}

func (r *OrderRepo) Transaction(ctx context.Context, fn func(tx *gorm.DB) error) error {
	return r.db.WithContext(ctx).Transaction(fn)
}

func (r *OrderRepo) DB() *gorm.DB { return r.db }

func (r *OrderRepo) CountByStatus(ctx context.Context, status int8) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&model.Order{}).Where("status = ?", status).
		Count(&count).Error
	return count, err
}

func (r *OrderRepo) CountToday(ctx context.Context) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&model.Order{}).
		Where("created_at >= ?", time.Now().Truncate(24*time.Hour)).Count(&count).Error
	return count, err
}

var activeOrderStatuses = []int8{
	model.OrderStatusPending,
	model.OrderStatusAssigned,
	model.OrderStatusAccepted,
	model.OrderStatusWaitingPickup,
	model.OrderStatusInTrip,
}

func (r *OrderRepo) HasActiveOrder(ctx context.Context, passengerID int64) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&model.Order{}).
		Where("passenger_id = ? AND status IN ?", passengerID, activeOrderStatuses).
		Count(&count).Error
	return count > 0, err
}
