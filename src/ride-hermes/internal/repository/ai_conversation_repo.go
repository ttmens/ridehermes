package repository

import (
	"context"

	"github.com/ridehermes/ride-hermes/internal/model"
	"gorm.io/gorm"
)

type AIConversationRepo struct{ db *gorm.DB }

func NewAIConversationRepo(db *gorm.DB) *AIConversationRepo { return &AIConversationRepo{db: db} }

func (r *AIConversationRepo) Create(ctx context.Context, conv *model.AIConversation) error {
	return r.db.WithContext(ctx).Create(conv).Error
}

func (r *AIConversationRepo) FindBySession(ctx context.Context, userID int64, sessionID string, limit int) ([]model.AIConversation, error) {
	var convs []model.AIConversation
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND session_id = ?", userID, sessionID).
		Order("created_at ASC").Limit(limit).Find(&convs).Error
	return convs, err
}

func (r *AIConversationRepo) ListSessions(ctx context.Context, userID int64) ([]string, error) {
	var sessions []string
	err := r.db.WithContext(ctx).Model(&model.AIConversation{}).
		Where("user_id = ?", userID).
		Distinct("session_id").Pluck("session_id", &sessions).Error
	return sessions, err
}
