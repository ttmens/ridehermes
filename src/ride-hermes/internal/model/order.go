package model

import "time"

const (
	OrderStatusPending       int8 = 1
	OrderStatusAssigned      int8 = 2
	OrderStatusAccepted      int8 = 3
	OrderStatusWaitingPickup int8 = 5
	OrderStatusInTrip        int8 = 6
	OrderStatusCompleted     int8 = 7
	OrderStatusCancelled     int8 = 8
)

var OrderStatusNames = map[int8]string{
	OrderStatusPending:       "待派单",
	OrderStatusAssigned:      "已派单",
	OrderStatusAccepted:      "司机已确认",
	OrderStatusWaitingPickup: "司机到达等待",
	OrderStatusInTrip:        "行程中",
	OrderStatusCompleted:     "已完成",
	OrderStatusCancelled:     "已取消",
}

type Order struct {
	BaseModel
	OrderNo      string     `gorm:"uniqueIndex;size:32;not null" json:"order_no"`
	PassengerID  int64      `gorm:"index;not null" json:"passenger_id"`
	DriverID     *int64     `gorm:"index" json:"driver_id"`
	Status       int8       `gorm:"index;not null;default:1" json:"status"`
	PickupAddr   string     `gorm:"size:255;not null" json:"pickup_addr"`
	PickupLat    float64    `gorm:"type:decimal(10,7);not null" json:"pickup_lat"`
	PickupLng    float64    `gorm:"type:decimal(10,7);not null" json:"pickup_lng"`
	DropoffAddr  string     `gorm:"size:255;not null" json:"dropoff_addr"`
	DropoffLat   float64    `gorm:"type:decimal(10,7);not null" json:"dropoff_lat"`
	DropoffLng   float64    `gorm:"type:decimal(10,7);not null" json:"dropoff_lng"`
	EstPrice     float64    `gorm:"type:decimal(10,2);not null;default:0" json:"est_price"`
	ActualPrice  float64    `gorm:"type:decimal(10,2);not null;default:0" json:"actual_price"`
	EstDistance  int        `gorm:"not null;default:0" json:"est_distance"`
	EstDuration  int        `gorm:"not null;default:0" json:"est_duration"`
	CarType       int8       `gorm:"not null;default:1" json:"car_type"`
	DepartureTime time.Time  `gorm:"not null" json:"departure_time"`
	AcceptedAt   *time.Time `json:"accepted_at"`
	AssignedAt   *time.Time `json:"assigned_at"`
	ArrivedAt    *time.Time `json:"arrived_at"`
	StartedAt    *time.Time `json:"started_at"`
	EndedAt      *time.Time `json:"ended_at"`
	CancelledAt  *time.Time `json:"cancelled_at"`
	DemandID     *int64     `gorm:"index" json:"demand_id"`
	MatchingMode int8       `gorm:"not null;default:1" json:"matching_mode"` // 1=Platform, 2=A2A
	CancelReason string     `gorm:"size:255;not null;default:''" json:"cancel_reason"`
	Passenger    User       `gorm:"foreignKey:PassengerID" json:"passenger,omitempty"`
	Driver       *Driver    `gorm:"foreignKey:DriverID" json:"driver,omitempty"`
}

func (Order) TableName() string { return "orders" }
