package model

const (
	DispatchStatusAssigned int8 = 1
)

type DispatchLog struct {
	BaseModel
	OrderID  int64 `gorm:"index;not null" json:"order_id"`
	DriverID int64 `gorm:"index;not null" json:"driver_id"`
	Status   int8  `gorm:"not null" json:"status"`
}

func (DispatchLog) TableName() string { return "dispatch_logs" }
