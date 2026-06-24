package model

const (
	CarTypeEconomy int8 = 1
	CarTypeComfort int8 = 2
	CarTypeLuxury  int8 = 3
)

const (
	VehicleStatusActive   int8 = 1
	VehicleStatusDisabled int8 = 2
)

type Vehicle struct {
	BaseModel
	DriverID    int64  `gorm:"index;not null" json:"driver_id"`
	PlateNumber string `gorm:"uniqueIndex;size:20;not null" json:"plate_number"`
	Brand       string `gorm:"size:50;not null" json:"brand"`
	Model       string `gorm:"size:50;not null" json:"model"`
	Color       string `gorm:"size:20;not null" json:"color"`
	CarType     int8   `gorm:"not null;default:1" json:"car_type"`
	Status      int8   `gorm:"not null;default:1" json:"status"`
}

func (Vehicle) TableName() string { return "vehicles" }
