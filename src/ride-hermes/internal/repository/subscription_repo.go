package repository

import (
	"context"
	"time"

	"github.com/ridehermes/ride-hermes/internal/model"
	"gorm.io/gorm"
)

type SubscriptionRepo struct{ db *gorm.DB }

func NewSubscriptionRepo(db *gorm.DB) *SubscriptionRepo {
	return &SubscriptionRepo{db: db}
}

func (r *SubscriptionRepo) Create(ctx context.Context, sub *model.Subscription) error {
	return r.db.WithContext(ctx).Create(sub).Error
}

func (r *SubscriptionRepo) FindByID(ctx context.Context, id int64) (*model.Subscription, error) {
	var sub model.Subscription
	err := r.db.WithContext(ctx).Preload("Driver.User").First(&sub, id).Error
	if err != nil {
		return nil, err
	}
	return &sub, nil
}

func (r *SubscriptionRepo) FindByDriverID(ctx context.Context, driverID int64) (*model.Subscription, error) {
	var sub model.Subscription
	err := r.db.WithContext(ctx).Preload("Driver.User").
		Where("driver_id = ? AND status = ?", driverID, model.SubscriptionStatusActive).
		First(&sub).Error
	if err != nil {
		return nil, err
	}
	return &sub, nil
}

func (r *SubscriptionRepo) FindByUserID(ctx context.Context, userID int64) ([]model.Subscription, error) {
	var subs []model.Subscription
	err := r.db.WithContext(ctx).Preload("Driver.User").
		Joins("JOIN drivers ON drivers.id = subscriptions.driver_id").
		Where("drivers.user_id = ?", userID).Order("id DESC").Find(&subs).Error
	return subs, err
}

func (r *SubscriptionRepo) FindActiveByUserID(ctx context.Context, userID int64) (*model.Subscription, error) {
	var sub model.Subscription
	err := r.db.WithContext(ctx).Preload("Driver.User").
		Joins("JOIN drivers ON drivers.id = subscriptions.driver_id").
		Where("drivers.user_id = ? AND subscriptions.status = ?", userID, model.SubscriptionStatusActive).
		Order("subscriptions.id DESC").First(&sub).Error
	if err != nil {
		return nil, err
	}
	return &sub, nil
}

func (r *SubscriptionRepo) List(ctx context.Context, status *int8, offset, limit int) ([]model.Subscription, int64, error) {
	var subs []model.Subscription
	var total int64
	query := r.db.WithContext(ctx).Model(&model.Subscription{})
	if status != nil {
		query = query.Where("status = ?", *status)
	}
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := query.Preload("Driver.User").Offset(offset).Limit(limit).Order("id DESC").Find(&subs).Error
	return subs, total, err
}

func (r *SubscriptionRepo) Update(ctx context.Context, id int64, updates map[string]interface{}) error {
	return r.db.WithContext(ctx).Model(&model.Subscription{}).Where("id = ?", id).Updates(updates).Error
}

func (r *SubscriptionRepo) UpdateStatus(ctx context.Context, id int64, status int8) error {
	return r.db.WithContext(ctx).Model(&model.Subscription{}).Where("id = ?", id).
		Update("status", status).Error
}

func (r *SubscriptionRepo) Delete(ctx context.Context, id int64) error {
	return r.db.WithContext(ctx).Delete(&model.Subscription{}, id).Error
}

// FindExpiringSoon 查询即将到期的订阅（withinDays天内到期）
func (r *SubscriptionRepo) FindExpiringSoon(ctx context.Context, withinDays int) ([]model.Subscription, error) {
	var subs []model.Subscription
	now := time.Now()
	deadline := now.AddDate(0, 0, withinDays)
	err := r.db.WithContext(ctx).Preload("Driver.User").
		Where("status = ? AND expire_date > ? AND expire_date <= ?",
			model.SubscriptionStatusActive, now, deadline).
		Find(&subs).Error
	return subs, err
}

// FindExpired 查询已到期但状态仍为active的订阅
func (r *SubscriptionRepo) FindExpired(ctx context.Context) ([]model.Subscription, error) {
	var subs []model.Subscription
	now := time.Now()
	err := r.db.WithContext(ctx).Preload("Driver.User").
		Where("status = ? AND expire_date <= ?",
			model.SubscriptionStatusActive, now).
		Find(&subs).Error
	return subs, err
}

// CreatePayment 创建支付记录
func (r *SubscriptionRepo) CreatePayment(ctx context.Context, payment *model.SubscriptionPayment) error {
	return r.db.WithContext(ctx).Create(payment).Error
}

// ListPayments 查询支付记录
func (r *SubscriptionRepo) ListPayments(ctx context.Context, subscriptionID int64, offset, limit int) ([]model.SubscriptionPayment, int64, error) {
	var payments []model.SubscriptionPayment
	var total int64
	query := r.db.WithContext(ctx).Model(&model.SubscriptionPayment{}).
		Where("subscription_id = ?", subscriptionID)
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := query.Offset(offset).Limit(limit).Order("id DESC").Find(&payments).Error
	return payments, total, err
}

// AddRevenue 累加流水和佣金
func (r *SubscriptionRepo) AddRevenue(ctx context.Context, subscriptionID int64, revenue, commission float64) error {
	return r.db.WithContext(ctx).Model(&model.Subscription{}).Where("id = ?", subscriptionID).
		Updates(map[string]interface{}{
			"total_revenue":    gorm.Expr("total_revenue + ?", revenue),
			"total_commission": gorm.Expr("total_commission + ?", commission),
		}).Error
}

func (r *SubscriptionRepo) Transaction(ctx context.Context, fn func(tx *gorm.DB) error) error {
	return r.db.WithContext(ctx).Transaction(fn)
}

func (r *SubscriptionRepo) DB() *gorm.DB { return r.db }
