package model

const (
	LocationUserTypePassenger int8 = 2
	LocationUserTypeDriver    int8 = 3
)

type Location struct {
	BaseModel
	UserID    int64   `gorm:"index:idx_user_type,priority:1;not null" json:"user_id"`
	UserType  int8    `gorm:"index:idx_user_type,priority:2;not null" json:"user_type"`
	Latitude  float64 `gorm:"type:decimal(10,7);not null" json:"latitude"`
	Longitude float64 `gorm:"type:decimal(10,7);not null" json:"longitude"`
	Accuracy  float64 `gorm:"type:decimal(6,2);not null;default:0" json:"accuracy"`
	Speed     float64 `gorm:"type:decimal(6,2);not null;default:0" json:"speed"`
	Bearing   float64 `gorm:"type:decimal(6,2);not null;default:0" json:"bearing"`
}

func (Location) TableName() string { return "locations" }
