package model

import "time"

const (
	OfferStatusPending  int8 = 1
	OfferStatusAccepted int8 = 2
	OfferStatusRejected int8 = 3
	OfferStatusExpired  int8 = 4
)

type MatchingOffer struct {
	BaseModel
	DriverID   int64      `gorm:"index;not null" json:"driver_id"`
	DemandID   *int64     `gorm:"index" json:"demand_id"`
	Lat        float64    `gorm:"type:decimal(10,7);not null" json:"lat"`
	Lng        float64    `gorm:"type:decimal(10,7);not null" json:"lng"`
	CarType    int8       `gorm:"not null;default:1" json:"car_type"`
	Price      float64    `gorm:"type:decimal(10,2);not null;default:0" json:"price"`
	AvailableFrom time.Time `gorm:"not null" json:"available_from"`
	AvailableTo   time.Time `gorm:"not null" json:"available_to"`
	Status     int8       `gorm:"index;not null;default:1" json:"status"`
	Driver     Driver     `gorm:"foreignKey:DriverID" json:"driver,omitempty"`
	Demand     *MatchingDemand `gorm:"foreignKey:DemandID" json:"demand,omitempty"`
}

func (MatchingOffer) TableName() string { return "matching_offers" }
