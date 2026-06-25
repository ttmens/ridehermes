package service

import (
	"context"
	"fmt"
	"time"

	"github.com/ridehermes/ride-hermes/internal/model"
	"github.com/ridehermes/ride-hermes/internal/repository"
	"go.uber.org/zap"
)

type EnterpriseService struct {
	entRepo   *repository.EnterpriseRepo
	empRepo   *repository.EnterpriseEmployeeRepo
	orderRepo *repository.OrderRepo
	logger    *zap.Logger
}

func NewEnterpriseService(entRepo *repository.EnterpriseRepo, empRepo *repository.EnterpriseEmployeeRepo, orderRepo *repository.OrderRepo, logger *zap.Logger) *EnterpriseService {
	return &EnterpriseService{entRepo: entRepo, empRepo: empRepo, orderRepo: orderRepo, logger: logger}
}

func (s *EnterpriseService) Create(ctx context.Context, e *model.EnterpriseCustomer) error {
	return s.entRepo.Create(ctx, e)
}

func (s *EnterpriseService) List(ctx context.Context) ([]model.EnterpriseCustomer, error) {
	return s.entRepo.FindAll(ctx)
}

func (s *EnterpriseService) GetByID(ctx context.Context, id int64) (*model.EnterpriseCustomer, error) {
	return s.entRepo.FindByID(ctx, id)
}

func (s *EnterpriseService) AddEmployee(ctx context.Context, enterpriseID, userID int64, name, phone string) error {
	e := &model.EnterpriseEmployee{
		EnterpriseID: enterpriseID,
		UserID:       userID,
		Name:         name,
		Phone:        phone,
	}
	return s.empRepo.Create(ctx, e)
}

func (s *EnterpriseService) ListEmployees(ctx context.Context, enterpriseID int64) ([]model.EnterpriseEmployee, error) {
	return s.empRepo.FindByEnterpriseID(ctx, enterpriseID)
}

func (s *EnterpriseService) GetMonthlyBill(ctx context.Context, enterpriseID int64, year, month int) (*EnterpriseBill, error) {
	ent, err := s.entRepo.FindByID(ctx, enterpriseID)
	if err != nil {
		return nil, err
	}

	employees, err := s.empRepo.FindByEnterpriseID(ctx, enterpriseID)
	if err != nil {
		return nil, err
	}

	// Get orders for all employees
	var totalOrders int64
	var totalAmount float64
	for _, emp := range employees {
		orders, _, _ := s.orderRepo.ListByPassenger(ctx, emp.UserID, 0, 100)
		for _, o := range orders {
			if o.CreatedAt.Year() == year && o.CreatedAt.Month() == time.Month(month) && o.Status == model.OrderStatusCompleted {
				totalOrders++
				totalAmount += o.ActualPrice
			}
		}
	}

	bill := &EnterpriseBill{
		CompanyName:  ent.CompanyName,
		Year:         year,
		Month:        month,
		TotalOrders:  totalOrders,
		TotalAmount:  totalAmount,
		ContractType: ent.ContractType,
	}

	if ent.ContractType == model.ContractMonthly {
		bill.Settlement = fmt.Sprintf("月结 ¥%.2f", totalAmount)
	} else {
		bill.Settlement = fmt.Sprintf("预付费 ¥%.2f", ent.ContractAmount)
	}

	return bill, nil
}

type EnterpriseBill struct {
	CompanyName  string `json:"company_name"`
	Year         int    `json:"year"`
	Month        int    `json:"month"`
	TotalOrders  int64  `json:"total_orders"`
	TotalAmount  float64 `json:"total_amount"`
	ContractType int8    `json:"contract_type"`
	Settlement   string `json:"settlement"`
}
