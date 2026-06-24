package repository

import (
	"context"

	"github.com/ridehermes/ride-hermes/internal/model"
	"gorm.io/gorm"
)

type LocationRepo struct{ db *gorm.DB }

func NewLocationRepo(db *gorm.DB) *LocationRepo { return &LocationRepo{db: db} }

func (r *LocationRepo) Create(ctx context.Context, loc *model.Location) error {
	return r.db.WithContext(ctx).Create(loc).Error
}

func (r *LocationRepo) BatchCreate(ctx context.Context, locs []model.Location) error {
	return r.db.WithContext(ctx).CreateInBatches(locs, 100).Error
}

func (r *LocationRepo) FindByUser(ctx context.Context, userID int64, userType int8, limit int) ([]model.Location, error) {
	var locs []model.Location
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND user_type = ?", userID, userType).
		Order("created_at DESC").Limit(limit).Find(&locs).Error
	return locs, err
}
