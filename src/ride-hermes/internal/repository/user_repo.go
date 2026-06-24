package repository

import (
	"context"

	"github.com/ridehermes/ride-hermes/internal/model"
	"gorm.io/gorm"
)

type UserRepo struct{ db *gorm.DB }

func NewUserRepo(db *gorm.DB) *UserRepo { return &UserRepo{db: db} }

func (r *UserRepo) Create(ctx context.Context, user *model.User) error {
	return r.db.WithContext(ctx).Create(user).Error
}

func (r *UserRepo) FindByPhone(ctx context.Context, phone string) (*model.User, error) {
	var user model.User
	err := r.db.WithContext(ctx).Where("phone = ?", phone).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *UserRepo) FindByID(ctx context.Context, id int64) (*model.User, error) {
	var user model.User
	err := r.db.WithContext(ctx).First(&user, id).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *UserRepo) ListByRole(ctx context.Context, role int8, offset, limit int) ([]model.User, int64, error) {
	var users []model.User
	var total int64
	query := r.db.WithContext(ctx).Model(&model.User{}).Where("role = ?", role)
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := query.Offset(offset).Limit(limit).Order("id DESC").Find(&users).Error
	return users, total, err
}

func (r *UserRepo) ListAll(ctx context.Context, offset, limit int) ([]model.User, int64, error) {
	var users []model.User
	var total int64
	query := r.db.WithContext(ctx).Model(&model.User{})
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := query.Offset(offset).Limit(limit).Order("id DESC").Find(&users).Error
	return users, total, err
}

func (r *UserRepo) UpdateStatus(ctx context.Context, id int64, status int8) error {
	return r.db.WithContext(ctx).Model(&model.User{}).Where("id = ?", id).
		Update("status", status).Error
}

func (r *UserRepo) Update(ctx context.Context, id int64, updates map[string]interface{}) error {
	return r.db.WithContext(ctx).Model(&model.User{}).Where("id = ?", id).
		Updates(updates).Error
}
