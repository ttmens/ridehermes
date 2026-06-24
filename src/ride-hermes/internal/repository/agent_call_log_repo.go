package repository

import (
	"context"

	"github.com/ridehermes/ride-hermes/internal/model"
	"gorm.io/gorm"
)

type AgentCallLogRepo struct{ db *gorm.DB }

func NewAgentCallLogRepo(db *gorm.DB) *AgentCallLogRepo {
	return &AgentCallLogRepo{db: db}
}

func (r *AgentCallLogRepo) Create(ctx context.Context, log *model.AgentCallLog) error {
	return r.db.WithContext(ctx).Create(log).Error
}

func (r *AgentCallLogRepo) ListByCredentialID(ctx context.Context, credID uint64, offset, limit int) ([]model.AgentCallLog, int64, error) {
	var logs []model.AgentCallLog
	var total int64
	query := r.db.WithContext(ctx).Model(&model.AgentCallLog{}).Where("credential_id = ?", credID)
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := query.Offset(offset).Limit(limit).Order("id DESC").Find(&logs).Error
	return logs, total, err
}

func (r *AgentCallLogRepo) ListByUserID(ctx context.Context, userID uint64, offset, limit int) ([]model.AgentCallLog, int64, error) {
	var logs []model.AgentCallLog
	var total int64
	query := r.db.WithContext(ctx).Model(&model.AgentCallLog{}).Where("user_id = ?", userID)
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := query.Offset(offset).Limit(limit).Order("id DESC").Find(&logs).Error
	return logs, total, err
}
