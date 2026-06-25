package repository

import (
	"context"

	"github.com/ridehermes/ride-hermes/internal/model"
	"gorm.io/gorm"
)

type EnterpriseRepo struct {
	db *gorm.DB
}

func NewEnterpriseRepo(db *gorm.DB) *EnterpriseRepo {
	return &EnterpriseRepo{db: db}
}

func (r *EnterpriseRepo) Create(ctx context.Context, e *model.EnterpriseCustomer) error {
	return r.db.WithContext(ctx).Create(e).Error
}
func (r *EnterpriseRepo) FindAll(ctx context.Context) ([]model.EnterpriseCustomer, error) {
	var list []model.EnterpriseCustomer
	err := r.db.WithContext(ctx).Find(&list).Error
	return list, err
}
func (r *EnterpriseRepo) FindByID(ctx context.Context, id int64) (*model.EnterpriseCustomer, error) {
	var e model.EnterpriseCustomer
	err := r.db.WithContext(ctx).First(&e, id).Error
	return &e, err
}
func (r *EnterpriseRepo) Update(ctx context.Context, id int64, updates map[string]interface{}) error {
	return r.db.WithContext(ctx).Model(&model.EnterpriseCustomer{}).Where("id = ?", id).Updates(updates).Error
}

type EnterpriseEmployeeRepo struct {
	db *gorm.DB
}
func NewEnterpriseEmployeeRepo(db *gorm.DB) *EnterpriseEmployeeRepo {
	return &EnterpriseEmployeeRepo{db: db}
}
func (r *EnterpriseEmployeeRepo) Create(ctx context.Context, e *model.EnterpriseEmployee) error {
	return r.db.WithContext(ctx).Create(e).Error
}
func (r *EnterpriseEmployeeRepo) FindByEnterpriseID(ctx context.Context, enterpriseID int64) ([]model.EnterpriseEmployee, error) {
	var list []model.EnterpriseEmployee
	err := r.db.WithContext(ctx).Where("enterprise_id = ?", enterpriseID).Find(&list).Error
	return list, err
}
func (r *EnterpriseEmployeeRepo) FindByUserID(ctx context.Context, userID int64) (*model.EnterpriseEmployee, error) {
	var e model.EnterpriseEmployee
	err := r.db.WithContext(ctx).Where("user_id = ?", userID).First(&e).Error
	return &e, err
}
