package repository

import (
	"context"

	"github.com/ridehermes/ride-hermes/internal/model"
	"gorm.io/gorm"
)

type DispatchLogRepo struct{ db *gorm.DB }

func NewDispatchLogRepo(db *gorm.DB) *DispatchLogRepo { return &DispatchLogRepo{db: db} }

func (r *DispatchLogRepo) Create(ctx context.Context, log *model.DispatchLog) error {
	return r.db.WithContext(ctx).Create(log).Error
}

func (r *DispatchLogRepo) UpdateStatus(ctx context.Context, id int64, status int8) error {
	return r.db.WithContext(ctx).Model(&model.DispatchLog{}).Where("id = ?", id).
		Update("status", status).Error
}

func (r *DispatchLogRepo) FindByOrder(ctx context.Context, orderID int64) ([]model.DispatchLog, error) {
	var logs []model.DispatchLog
	err := r.db.WithContext(ctx).Where("order_id = ?", orderID).
		Order("round ASC").Find(&logs).Error
	return logs, err
}
