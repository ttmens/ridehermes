package model

const (
	DriverStatusPending  int8 = 1
	DriverStatusActive   int8 = 2
	DriverStatusDisabled int8 = 3
)

type Driver struct {
	BaseModel
	UserID    int64   `gorm:"uniqueIndex;not null" json:"user_id"`
	RealName  string  `gorm:"size:50;not null" json:"real_name"`
	IDCardNo  string  `gorm:"uniqueIndex;size:18;not null" json:"id_card_no"`
	LicenseNo string  `gorm:"uniqueIndex;size:30;not null" json:"license_no"`
	Status    int8    `gorm:"not null;default:1;index" json:"status"`
	Rating    float64 `gorm:"type:decimal(3,2);not null;default:5.00" json:"rating"`
	Balance        float64 `gorm:"type:decimal(12,2);not null;default:0.00" json:"balance"`
	SubscriptionID *int64 `gorm:"index" json:"subscription_id"`
	User      User    `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Vehicle   Vehicle `gorm:"foreignKey:DriverID" json:"vehicle,omitempty"`
}

func (Driver) TableName() string { return "drivers" }
