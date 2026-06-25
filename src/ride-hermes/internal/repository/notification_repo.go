package repository

import (
	"context"
	"time"

	"github.com/ridehermes/ride-hermes/internal/model"
	"gorm.io/gorm"
)

type NotificationRepo struct {
	db *gorm.DB
}

func NewNotificationRepo(db *gorm.DB) *NotificationRepo {
	return &NotificationRepo{db: db}
}

func (r *NotificationRepo) Create(ctx context.Context, n *model.Notification) error {
	return r.db.WithContext(ctx).Create(n).Error
}

func (r *NotificationRepo) FindByDriverID(ctx context.Context, driverID int64, limit int) ([]model.Notification, error) {
	var list []model.Notification
	err := r.db.WithContext(ctx).Where("driver_id = ?", driverID).
		Order("created_at DESC").Limit(limit).Find(&list).Error
	return list, err
}

func (r *NotificationRepo) FindAll(ctx context.Context, offset, limit int) ([]model.Notification, int64, error) {
	var list []model.Notification
	var total int64
	r.db.WithContext(ctx).Model(&model.Notification{}).Count(&total)
	err := r.db.WithContext(ctx).Order("created_at DESC").Offset(offset).Limit(limit).Find(&list).Error
	return list, total, err
}

func (r *NotificationRepo) UpdateStatus(ctx context.Context, id int64, status int8, failReason string) error {
	updates := map[string]interface{}{"status": status}
	if status == model.NotificationStatusSent {
		now := time.Now()
		updates["sent_at"] = &now
	}
	if failReason != "" {
		updates["fail_reason"] = failReason
	}
	return r.db.WithContext(ctx).Model(&model.Notification{}).Where("id = ?", id).Updates(updates).Error
}
