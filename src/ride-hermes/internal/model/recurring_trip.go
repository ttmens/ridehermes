package model

import "time"

const (
	RecurringDaily    string = "daily"
	RecurringWeekly   string = "weekly"
	RecurringWorkday  string = "workday"
)

type RecurringTrip struct {
	BaseModel
	PassengerID   int64     `gorm:"index;not null" json:"passenger_id"`
	TripType      string    `gorm:"size:20;not null" json:"trip_type"`
	PickupAddr    string    `gorm:"size:255;not null" json:"pickup_addr"`
	PickupLat     float64   `gorm:"type:real;not null" json:"pickup_lat"`
	PickupLng     float64   `gorm:"type:real;not null" json:"pickup_lng"`
	DropoffAddr   string    `gorm:"size:255;not null" json:"dropoff_addr"`
	DropoffLat    float64   `gorm:"type:real;not null" json:"dropoff_lat"`
	DropoffLng    float64   `gorm:"type:real;not null" json:"dropoff_lng"`
	DepartureTime string    `gorm:"size:10;not null" json:"departure_time"` // HH:MM format
	DaysOfWeek    string    `gorm:"size:20" json:"days_of_week"`           // "1,2,3,4,5" for Mon-Fri
	CarType       int8      `gorm:"not null;default:1" json:"car_type"`
	PriceRangeMin float64   `gorm:"type:real;not null;default:0" json:"price_range_min"`
	PriceRangeMax float64   `gorm:"type:real;not null;default:0" json:"price_range_max"`
	MinTrustScore float64   `gorm:"type:real;not null;default:0" json:"min_trust_score"`
	IsActive      bool      `gorm:"not null;default:true" json:"is_active"`
	StartDate     time.Time `gorm:"not null" json:"start_date"`
	EndDate       time.Time `gorm:"not null" json:"end_date"`
	NextRunDate   *time.Time `json:"next_run_date"`
}

func (RecurringTrip) TableName() string { return "recurring_trips" }
