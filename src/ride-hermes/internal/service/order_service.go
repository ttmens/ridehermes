package service

import (
	"context"
	"fmt"
	"time"

	"github.com/ridehermes/ride-hermes/internal/model"
	"github.com/ridehermes/ride-hermes/internal/repository"
)

type OrderService struct {
	orderRepo *repository.OrderRepo
}

func NewOrderService(orderRepo *repository.OrderRepo) *OrderService {
	return &OrderService{orderRepo: orderRepo}
}

type CreateOrderReq struct {
	PickupAddr    string  `json:"pickup_addr"`
	PickupLat     float64 `json:"pickup_lat"`
	PickupLng     float64 `json:"pickup_lng"`
	DropoffAddr   string  `json:"dropoff_addr"`
	DropoffLat    float64 `json:"dropoff_lat"`
	DropoffLng    float64 `json:"dropoff_lng"`
	CarType       int8    `json:"car_type"`
	DepartureTime string  `json:"departure_time"`
	SessionID     string  `json:"session_id"`
}

func (s *OrderService) Create(ctx context.Context, passengerID int64, req *CreateOrderReq) (*model.Order, error) {
	price, distance, duration := EstimatePrice(req.PickupLat, req.PickupLng, req.DropoffLat, req.DropoffLng, req.CarType)

	var departureTime time.Time
	if req.DepartureTime == "" {
		departureTime = time.Now()
	} else {
		var err error
		// Try RFC3339 formats with timezone
		departureTime, err = time.Parse(time.RFC3339, req.DepartureTime)
		if err != nil {
			departureTime, err = time.Parse(time.RFC3339Nano, req.DepartureTime)
			if err != nil {
				// Dart toIso8601String() local time: "2026-05-15T17:21:00.000" (no timezone)
				departureTime, err = time.ParseInLocation("2006-01-02T15:04:05.000", req.DepartureTime, time.Local)
				if err != nil {
					departureTime, err = time.ParseInLocation("2006-01-02T15:04:05", req.DepartureTime, time.Local)
					if err != nil {
						departureTime, err = time.Parse("2006-01-02 15:04:05", req.DepartureTime)
						if err != nil {
							return nil, fmt.Errorf("出发时间格式错误")
						}
					}
				}
			}
		}
	}

	order := &model.Order{
		OrderNo:       generateOrderNo(),
		PassengerID:   passengerID,
		Status:        model.OrderStatusPending,
		PickupAddr:    req.PickupAddr,
		PickupLat:     req.PickupLat,
		PickupLng:     req.PickupLng,
		DropoffAddr:   req.DropoffAddr,
		DropoffLat:    req.DropoffLat,
		DropoffLng:    req.DropoffLng,
		EstPrice:      price,
		EstDistance:    distance,
		EstDuration:   duration,
		CarType:       req.CarType,
		DepartureTime: departureTime,
	}

	if err := s.orderRepo.Create(ctx, order); err != nil {
		return nil, err
	}
	return order, nil
}

func (s *OrderService) GetByID(ctx context.Context, id int64) (*model.Order, error) {
	return s.orderRepo.FindByID(ctx, id)
}

func (s *OrderService) ListByPassenger(ctx context.Context, passengerID int64, offset, limit int) ([]model.Order, int64, error) {
	return s.orderRepo.ListByPassenger(ctx, passengerID, offset, limit)
}

func (s *OrderService) ListByDriver(ctx context.Context, driverID int64, offset, limit int) ([]model.Order, int64, error) {
	return s.orderRepo.ListByDriver(ctx, driverID, offset, limit)
}

func (s *OrderService) ListAll(ctx context.Context, status *int8, offset, limit int) ([]model.Order, int64, error) {
	return s.orderRepo.ListAll(ctx, status, offset, limit)
}

func (s *OrderService) UpdateStatus(ctx context.Context, orderID int64, status int8) error {
	return s.orderRepo.UpdateStatus(ctx, orderID, status)
}

func (s *OrderService) Accept(ctx context.Context, orderID int64, driverID int64) error {
	order, err := s.orderRepo.FindByID(ctx, orderID)
	if err != nil {
		return fmt.Errorf("订单不存在")
	}
	if order.Status != model.OrderStatusAssigned {
		return fmt.Errorf("当前订单状态不允许确认")
	}
	if order.DriverID == nil || *order.DriverID != driverID {
		return fmt.Errorf("无权操作此订单")
	}

	now := time.Now()
	return s.orderRepo.Update(ctx, orderID, map[string]interface{}{
		"status":      model.OrderStatusAccepted,
		"accepted_at": now,
	})
}

func (s *OrderService) Reject(ctx context.Context, orderID int64, driverID int64, reason string) error {
	order, err := s.orderRepo.FindByID(ctx, orderID)
	if err != nil {
		return fmt.Errorf("订单不存在")
	}
	if order.Status != model.OrderStatusAssigned {
		return fmt.Errorf("当前订单状态不允许拒绝")
	}
	if order.DriverID == nil || *order.DriverID != driverID {
		return fmt.Errorf("无权操作此订单")
	}

	return s.orderRepo.Update(ctx, orderID, map[string]interface{}{
		"driver_id":     nil,
		"status":        model.OrderStatusPending,
		"cancel_reason": "司机拒绝: " + reason,
	})
}

func (s *OrderService) Arrive(ctx context.Context, orderID int64, driverID int64) error {
	order, err := s.orderRepo.FindByID(ctx, orderID)
	if err != nil {
		return fmt.Errorf("订单不存在")
	}
	if order.DriverID == nil || *order.DriverID != driverID {
		return fmt.Errorf("无权操作此订单")
	}
	if order.Status != model.OrderStatusAssigned && order.Status != model.OrderStatusAccepted {
		return fmt.Errorf("当前订单状态不允许此操作")
	}

	now := time.Now()
	return s.orderRepo.Update(ctx, orderID, map[string]interface{}{
		"status":     model.OrderStatusWaitingPickup,
		"arrived_at": now,
	})
}

func (s *OrderService) StartTrip(ctx context.Context, orderID int64, driverID int64) error {
	order, err := s.orderRepo.FindByID(ctx, orderID)
	if err != nil {
		return fmt.Errorf("订单不存在")
	}
	if order.DriverID == nil || *order.DriverID != driverID {
		return fmt.Errorf("无权操作此订单")
	}
	if order.Status != model.OrderStatusWaitingPickup {
		return fmt.Errorf("当前订单状态不允许开始行程")
	}

	now := time.Now()
	return s.orderRepo.Update(ctx, orderID, map[string]interface{}{
		"status":     model.OrderStatusInTrip,
		"started_at": now,
	})
}

func (s *OrderService) Complete(ctx context.Context, orderID int64, driverID int64) error {
	order, err := s.orderRepo.FindByID(ctx, orderID)
	if err != nil {
		return fmt.Errorf("订单不存在")
	}
	if order.DriverID == nil || *order.DriverID != driverID {
		return fmt.Errorf("无权操作此订单")
	}
	if order.Status != model.OrderStatusInTrip {
		return fmt.Errorf("当前订单状态不允许完成")
	}

	now := time.Now()
	return s.orderRepo.Update(ctx, orderID, map[string]interface{}{
		"status":  model.OrderStatusCompleted,
		"ended_at": now,
	})
}

func (s *OrderService) HasActiveOrder(ctx context.Context, passengerID int64) (bool, error) {
	return s.orderRepo.HasActiveOrder(ctx, passengerID)
}

func (s *OrderService) Cancel(ctx context.Context, orderID int64, userID int64, role int8, reason string) error {
	order, err := s.orderRepo.FindByID(ctx, orderID)
	if err != nil {
		return fmt.Errorf("订单不存在")
	}

	// Only passenger or admin can cancel, or driver in accepted state
	if role == model.RolePassenger && order.PassengerID != userID {
		return fmt.Errorf("无权取消此订单")
	}

	cancellableStatuses := map[int8]bool{
		model.OrderStatusPending:  true,
		model.OrderStatusAssigned: true,
		model.OrderStatusAccepted: true,
	}
	if !cancellableStatuses[order.Status] {
		return fmt.Errorf("当前订单状态不允许取消")
	}

	now := time.Now()
	return s.orderRepo.Update(ctx, orderID, map[string]interface{}{
		"status":        model.OrderStatusCancelled,
		"cancelled_at":  now,
		"cancel_reason": reason,
	})
}

func generateOrderNo() string {
	now := time.Now()
	return fmt.Sprintf("RH%s%04d", now.Format("200601021504"), now.UnixMilli()%10000)
}
