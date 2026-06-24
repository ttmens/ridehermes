package repository

import (
	"context"

	"github.com/ridehermes/ride-hermes/internal/model"
	"gorm.io/gorm"
)

type DriverRepo struct{ db *gorm.DB }

func NewDriverRepo(db *gorm.DB) *DriverRepo { return &DriverRepo{db: db} }

func (r *DriverRepo) Create(ctx context.Context, driver *model.Driver) error {
	return r.db.WithContext(ctx).Create(driver).Error
}

func (r *DriverRepo) FindByUserID(ctx context.Context, userID int64) (*model.Driver, error) {
	var driver model.Driver
	err := r.db.WithContext(ctx).Preload("User").Preload("Vehicle").
		Where("user_id = ?", userID).First(&driver).Error
	if err != nil {
		return nil, err
	}
	return &driver, nil
}

func (r *DriverRepo) FindByID(ctx context.Context, id int64) (*model.Driver, error) {
	var driver model.Driver
	err := r.db.WithContext(ctx).Preload("User").Preload("Vehicle").
		First(&driver, id).Error
	if err != nil {
		return nil, err
	}
	return &driver, nil
}

func (r *DriverRepo) FindByIDCardNo(ctx context.Context, idCardNo string) (*model.Driver, error) {
	var driver model.Driver
	err := r.db.WithContext(ctx).Where("id_card_no = ?", idCardNo).First(&driver).Error
	if err != nil {
		return nil, err
	}
	return &driver, nil
}

func (r *DriverRepo) FindByLicenseNo(ctx context.Context, licenseNo string) (*model.Driver, error) {
	var driver model.Driver
	err := r.db.WithContext(ctx).Where("license_no = ?", licenseNo).First(&driver).Error
	if err != nil {
		return nil, err
	}
	return &driver, nil
}

func (r *DriverRepo) List(ctx context.Context, status *int8, offset, limit int) ([]model.Driver, int64, error) {
	var drivers []model.Driver
	var total int64
	query := r.db.WithContext(ctx).Model(&model.Driver{})
	if status != nil {
		query = query.Where("status = ?", *status)
	}
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := query.Preload("User").Preload("Vehicle").
		Offset(offset).Limit(limit).Order("id DESC").Find(&drivers).Error
	return drivers, total, err
}

func (r *DriverRepo) UpdateStatus(ctx context.Context, id int64, status int8) error {
	return r.db.WithContext(ctx).Model(&model.Driver{}).Where("id = ?", id).
		Update("status", status).Error
}

func (r *DriverRepo) Update(ctx context.Context, id int64, updates map[string]interface{}) error {
	return r.db.WithContext(ctx).Model(&model.Driver{}).Where("id = ?", id).Updates(updates).Error
}

// FindByIDs 批量查询司机（单次 DB 查询，避免 N+1）
func (r *DriverRepo) FindByIDs(ctx context.Context, ids []int64) ([]model.Driver, error) {
	if len(ids) == 0 {
		return nil, nil
	}
	var drivers []model.Driver
	err := r.db.WithContext(ctx).Preload("User").Preload("Vehicle").
		Where("id IN ?", ids).Find(&drivers).Error
	return drivers, err
}
