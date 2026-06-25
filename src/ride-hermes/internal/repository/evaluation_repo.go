package repository

import (
	"context"
	"time"

	"github.com/ridehermes/ride-hermes/internal/model"
	"gorm.io/gorm"
)

type EvaluationRepo struct {
	db *gorm.DB
}

func NewEvaluationRepo(db *gorm.DB) *EvaluationRepo {
	return &EvaluationRepo{db: db}
}

func (r *EvaluationRepo) Create(ctx context.Context, eval *model.Evaluation) error {
	return r.db.WithContext(ctx).Create(eval).Error
}

func (r *EvaluationRepo) FindByDriverID(ctx context.Context, driverID int64, limit int) ([]model.Evaluation, error) {
	var evals []model.Evaluation
	err := r.db.WithContext(ctx).Where("driver_id = ?", driverID).
		Order("created_at DESC").Limit(limit).Find(&evals).Error
	return evals, err
}

func (r *EvaluationRepo) FindRecently(ctx context.Context, driverID int64, duration time.Duration) ([]model.Evaluation, error) {
	var evals []model.Evaluation
	deadline := time.Now().Add(-duration)
	err := r.db.WithContext(ctx).
		Where("driver_id = ? AND created_at >= ?", driverID, deadline).
		Find(&evals).Error
	return evals, err
}

func (r *EvaluationRepo) FindBadEvaluations(ctx context.Context, driverID int64, duration time.Duration) ([]model.Evaluation, error) {
	var evals []model.Evaluation
	deadline := time.Now().Add(-duration)
	threshold := 3.0
	err := r.db.WithContext(ctx).
		Where("driver_id = ? AND created_at >= ? AND (punctuality < ? OR service < ? OR driving < ? OR completion < ?)",
			driverID, deadline, threshold, threshold, threshold, threshold).
		Find(&evals).Error
	return evals, err
}
