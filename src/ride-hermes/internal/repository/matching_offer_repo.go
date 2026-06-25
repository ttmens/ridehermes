package repository

import (
	"context"

	"github.com/ridehermes/ride-hermes/internal/model"
	"gorm.io/gorm"
)

type MatchingOfferRepo struct{ db *gorm.DB }

func NewMatchingOfferRepo(db *gorm.DB) *MatchingOfferRepo {
	return &MatchingOfferRepo{db: db}
}

func (r *MatchingOfferRepo) Create(ctx context.Context, offer *model.MatchingOffer) error {
	return r.db.WithContext(ctx).Create(offer).Error
}

func (r *MatchingOfferRepo) FindByID(ctx context.Context, id int64) (*model.MatchingOffer, error) {
	var offer model.MatchingOffer
	err := r.db.WithContext(ctx).Preload("Driver.User").Preload("Demand").First(&offer, id).Error
	if err != nil {
		return nil, err
	}
	return &offer, nil
}

func (r *MatchingOfferRepo) FindByDemandID(ctx context.Context, demandID int64) ([]model.MatchingOffer, error) {
	var offers []model.MatchingOffer
	err := r.db.WithContext(ctx).Preload("Driver.User").
		Where("demand_id = ?", demandID).Order("id DESC").Find(&offers).Error
	return offers, err
}

func (r *MatchingOfferRepo) FindByDriverID(ctx context.Context, driverID int64, offset, limit int) ([]model.MatchingOffer, int64, error) {
	var offers []model.MatchingOffer
	var total int64
	query := r.db.WithContext(ctx).Model(&model.MatchingOffer{}).Where("driver_id = ?", driverID)
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := query.Preload("Driver.User").Preload("Demand").
		Offset(offset).Limit(limit).Order("id DESC").Find(&offers).Error
	return offers, total, err
}

func (r *MatchingOfferRepo) ListByStatus(ctx context.Context, status int8, offset, limit int) ([]model.MatchingOffer, int64, error) {
	var offers []model.MatchingOffer
	var total int64
	query := r.db.WithContext(ctx).Model(&model.MatchingOffer{}).Where("status = ?", status)
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := query.Preload("Driver.User").Preload("Demand").
		Offset(offset).Limit(limit).Order("id DESC").Find(&offers).Error
	return offers, total, err
}

func (r *MatchingOfferRepo) Update(ctx context.Context, id int64, updates map[string]interface{}) error {
	return r.db.WithContext(ctx).Model(&model.MatchingOffer{}).Where("id = ?", id).Updates(updates).Error
}

func (r *MatchingOfferRepo) UpdateStatus(ctx context.Context, id int64, status int8) error {
	return r.db.WithContext(ctx).Model(&model.MatchingOffer{}).Where("id = ?", id).
		Update("status", status).Error
}

func (r *MatchingOfferRepo) Delete(ctx context.Context, id int64) error {
	return r.db.WithContext(ctx).Delete(&model.MatchingOffer{}, id).Error
}
