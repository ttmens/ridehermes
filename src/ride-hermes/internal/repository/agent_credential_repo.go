package repository

import (
	"context"

	"github.com/ridehermes/ride-hermes/internal/model"
	"gorm.io/gorm"
)

type AgentCredentialRepo struct{ db *gorm.DB }

func NewAgentCredentialRepo(db *gorm.DB) *AgentCredentialRepo {
	return &AgentCredentialRepo{db: db}
}

func (r *AgentCredentialRepo) FindByAPIKeyHash(ctx context.Context, hash string) (*model.AgentCredential, error) {
	var cred model.AgentCredential
	err := r.db.WithContext(ctx).Where("api_key_hash = ?", hash).First(&cred).Error
	if err != nil {
		return nil, err
	}
	return &cred, nil
}

func (r *AgentCredentialRepo) Create(ctx context.Context, cred *model.AgentCredential) error {
	return r.db.WithContext(ctx).Create(cred).Error
}

func (r *AgentCredentialRepo) ListByUserID(ctx context.Context, userID uint64) ([]model.AgentCredential, error) {
	var creds []model.AgentCredential
	err := r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Order("id DESC").
		Find(&creds).Error
	return creds, err
}

func (r *AgentCredentialRepo) UpdateStatus(ctx context.Context, id uint64, status int8) error {
	return r.db.WithContext(ctx).Model(&model.AgentCredential{}).
		Where("id = ?", id).Update("status", status).Error
}

func (r *AgentCredentialRepo) UpdateLastUsed(ctx context.Context, id uint64) error {
	return r.db.WithContext(ctx).Model(&model.AgentCredential{}).
		Where("id = ?", id).Update("last_used_at", gorm.Expr("NOW()")).Error
}

func (r *AgentCredentialRepo) Delete(ctx context.Context, id uint64) error {
	return r.db.WithContext(ctx).Delete(&model.AgentCredential{}, id).Error
}

func (r *AgentCredentialRepo) ListAll(ctx context.Context, offset, limit int) ([]model.AgentCredential, int64, error) {
	var creds []model.AgentCredential
	var total int64
	query := r.db.WithContext(ctx).Model(&model.AgentCredential{})
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := query.Offset(offset).Limit(limit).Order("id DESC").Find(&creds).Error
	return creds, total, err
}
