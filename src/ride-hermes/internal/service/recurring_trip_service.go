package service

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/ridehermes/ride-hermes/internal/model"
	"github.com/ridehermes/ride-hermes/internal/repository"
	"go.uber.org/zap"
)

type RecurringTripService struct {
	repo    *repository.RecurringTripRepo
	orderSvc *OrderService
	logger  *zap.Logger
}

func NewRecurringTripService(repo *repository.RecurringTripRepo, orderSvc *OrderService, logger *zap.Logger) *RecurringTripService {
	return &RecurringTripService{repo: repo, orderSvc: orderSvc, logger: logger}
}

func (s *RecurringTripService) Create(ctx context.Context, passengerID int64, req *RecurringTripRequest) (*model.RecurringTrip, error) {
	trip := &model.RecurringTrip{
		PassengerID:   passengerID,
		TripType:      req.TripType,
		PickupAddr:    req.PickupAddr,
		PickupLat:     req.PickupLat,
		PickupLng:     req.PickupLng,
		DropoffAddr:   req.DropoffAddr,
		DropoffLat:    req.DropoffLat,
		DropoffLng:    req.DropoffLng,
		DepartureTime: req.DepartureTime,
		DaysOfWeek:    req.DaysOfWeek,
		CarType:       req.CarType,
		PriceRangeMin: req.PriceRangeMin,
		PriceRangeMax: req.PriceRangeMax,
		MinTrustScore: req.MinTrustScore,
		StartDate:     req.StartDate,
		EndDate:       req.EndDate,
		IsActive:      true,
	}
	if err := s.repo.Create(ctx, trip); err != nil {
		return nil, err
	}
	return trip, nil
}

func (s *RecurringTripService) List(ctx context.Context, passengerID int64) ([]model.RecurringTrip, error) {
	return s.repo.FindByPassengerID(ctx, passengerID)
}

func (s *RecurringTripService) Delete(ctx context.Context, id int64) error {
	return s.repo.Delete(ctx, id)
}

func (s *RecurringTripService) ProcessDailyTrips(ctx context.Context) (int, error) {
	trips, err := s.repo.FindDueForCreation(ctx)
	if err != nil {
		return 0, err
	}

	now := time.Now()
	today := now.Weekday()
	count := 0

	for _, trip := range trips {
		// Check if today is a scheduled day
		days := strings.Split(trip.DaysOfWeek, ",")
		shouldRun := false
		if trip.TripType == model.RecurringDaily {
			shouldRun = true
		} else if trip.TripType == model.RecurringWorkday {
			if today >= time.Monday && today <= time.Friday {
				shouldRun = true
			}
		} else {
			for _, d := range days {
				if fmt.Sprintf("%d", today) == strings.TrimSpace(d) {
					shouldRun = true
					break
				}
			}
		}

		if !shouldRun {
			continue
		}

		// Parse departure time and create order request
		parts := strings.Split(trip.DepartureTime, ":")
		hour, min := 8, 0
		if len(parts) == 2 {
			fmt.Sscanf(parts[0], "%d", &hour)
			fmt.Sscanf(parts[1], "%d", &min)
		}

		departureTime := time.Date(now.Year(), now.Month(), now.Day(), hour, min, 0, 0, now.Location())

		req := &CreateOrderReq{
			PickupAddr:    trip.PickupAddr,
			PickupLat:     trip.PickupLat,
			PickupLng:     trip.PickupLng,
			DropoffAddr:   trip.DropoffAddr,
			DropoffLat:    trip.DropoffLat,
			DropoffLng:    trip.DropoffLng,
			DepartureTime: departureTime.Format(time.RFC3339),
			CarType:       trip.CarType,
		}

		if _, err := s.orderSvc.Create(ctx, trip.PassengerID, req); err != nil {
			s.logger.Error("failed to create recurring trip order", zap.Int64("trip_id", trip.ID), zap.Error(err))
			continue
		}
		count++
	}
	return count, nil
}

type RecurringTripRequest struct {
	TripType      string    `json:"trip_type" binding:"required"`
	PickupAddr    string    `json:"pickup_addr" binding:"required"`
	PickupLat     float64   `json:"pickup_lat"`
	PickupLng     float64   `json:"pickup_lng"`
	DropoffAddr   string    `json:"dropoff_addr" binding:"required"`
	DropoffLat    float64   `json:"dropoff_lat"`
	DropoffLng    float64   `json:"dropoff_lng"`
	DepartureTime string    `json:"departure_time" binding:"required"`
	DaysOfWeek    string    `json:"days_of_week"`
	CarType       int8      `json:"car_type"`
	PriceRangeMin float64   `json:"price_range_min"`
	PriceRangeMax float64   `json:"price_range_max"`
	MinTrustScore float64   `json:"min_trust_score"`
	StartDate     time.Time `json:"start_date"`
	EndDate       time.Time `json:"end_date"`
}
