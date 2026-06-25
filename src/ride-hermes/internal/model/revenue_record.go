package model

const (
	RevenueTypeTrip      string = "trip"
	RevenueTypeCommission string = "commission"
	RevenueTypeBonus     string = "bonus"
	RevenueTypePenalty   string = "penalty"

	RevenueStatusPending  int8 = 1
	RevenueStatusSettled  int8 = 2
	RevenueStatusReversed int8 = 3
)

type RevenueRecord struct {
	BaseModel
	DriverID int64   `gorm:"index;not null" json:"driver_id"`
	OrderID  *int64  `gorm:"index" json:"order_id"`
	Amount   float64 `gorm:"type:decimal(12,2);not null;default:0" json:"amount"`
	Type     string  `gorm:"size:30;not null" json:"type"`
	Remark   string  `gorm:"size:255;not null;default:''" json:"remark"`
	Status   int8    `gorm:"index;not null;default:1" json:"status"`
	Driver   Driver  `gorm:"foreignKey:DriverID" json:"driver,omitempty"`
	Order    *Order  `gorm:"foreignKey:OrderID" json:"order,omitempty"`
}

func (RevenueRecord) TableName() string { return "revenue_records" }
