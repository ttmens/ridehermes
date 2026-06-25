package model

import "time"

const (
	DemandStatusPending  int8 = 1
	DemandStatusMatched  int8 = 2
	DemandStatusExpired  int8 = 3
	DemandStatusCancelled int8 = 4
)

type MatchingDemand struct {
	BaseModel
	PassengerID   int64     `gorm:"index;not null" json:"passenger_id"`
	PickupAddr    string    `gorm:"size:255;not null" json:"pickup_addr"`
	PickupLat     float64   `gorm:"type:decimal(10,7);not null" json:"pickup_lat"`
	PickupLng     float64   `gorm:"type:decimal(10,7);not null" json:"pickup_lng"`
	DropoffAddr   string    `gorm:"size:255;not null" json:"dropoff_addr"`
	DropoffLat    float64   `gorm:"type:decimal(10,7);not null" json:"dropoff_lat"`
	DropoffLng    float64   `gorm:"type:decimal(10,7);not null" json:"dropoff_lng"`
	CarType       int8      `gorm:"not null;default:1" json:"car_type"`
	MaxPrice      float64   `gorm:"type:decimal(10,2);not null;default:0" json:"max_price"`
	DepartureTime time.Time `gorm:"not null" json:"departure_time"`
	Status        int8      `gorm:"index;not null;default:1" json:"status"`
	Passenger     User      `gorm:"foreignKey:PassengerID" json:"passenger,omitempty"`
}

func (MatchingDemand) TableName() string { return "matching_demands" }
