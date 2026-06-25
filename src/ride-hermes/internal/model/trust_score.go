package model

import "time"

const (
	// 信誉分4维度
	WeightPunctuality = 0.4
	WeightService     = 0.3
	WeightDriving     = 0.2
	WeightCompletion  = 0.1

	// 时间衰减
	Decay30Days  = 0.5
	Decay90Days  = 0.2
	Decay180Days = 0.05
)

type TrustScore struct {
	BaseModel
	DriverID    int64   `gorm:"uniqueIndex;not null" json:"driver_id"`
	TotalScore  float64 `gorm:"type:real;not null;default:5.00" json:"total_score"`
	Punctuality float64 `gorm:"type:real;not null;default:5.00" json:"punctuality"`
	Service     float64 `gorm:"type:real;not null;default:5.00" json:"service"`
	Driving     float64 `gorm:"type:real;not null;default:5.00" json:"driving"`
	Completion  float64 `gorm:"type:real;not null;default:5.00" json:"completion"`
	TotalOrders int     `gorm:"not null;default:0" json:"total_orders"`
	Ranking     int     `gorm:"not null;default:0" json:"ranking"`
	UpdatedAt   time.Time `json:"updated_at"`
}

func (TrustScore) TableName() string { return "trust_scores" }

type Evaluation struct {
	BaseModel
	DriverID    int64   `gorm:"index;not null" json:"driver_id"`
	OrderID     int64   `gorm:"index;not null" json:"order_id"`
	PassengerID int64   `json:"passenger_id"`
	Punctuality float64 `gorm:"type:real;not null" json:"punctuality"`
	Service     float64 `gorm:"type:real;not null" json:"service"`
	Driving     float64 `gorm:"type:real;not null" json:"driving"`
	Completion  float64 `gorm:"type:real;not null" json:"completion"`
	Comment     string  `gorm:"type:text" json:"comment"`
	Weight      float64 `gorm:"type:real;not null;default:1.00" json:"weight"`
	CreatedAt   time.Time `json:"created_at"`
}

func (Evaluation) TableName() string { return "evaluations" }
