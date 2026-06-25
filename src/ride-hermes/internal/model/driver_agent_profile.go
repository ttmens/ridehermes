package model

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"time"
)

// JSONArray 自定义类型，用于SQLite存储JSON数组
type JSONArray []int8

func (j JSONArray) Value() (driver.Value, error) {
	if j == nil {
		return "[]", nil
	}
	b, err := json.Marshal(j)
	return string(b), err
}

func (j *JSONArray) Scan(value interface{}) error {
	if value == nil {
		*j = []int8{}
		return nil
	}
	var bytes []byte
	switch v := value.(type) {
	case string:
		bytes = []byte(v)
	case []byte:
		bytes = v
	default:
		return errors.New("unsupported type for JSONArray")
	}
	return json.Unmarshal(bytes, j)
}

// JSONTimeSlots 时间段JSON
type JSONTimeSlots []TimeSlot

type TimeSlot struct {
	DayOfWeek int    `json:"day_of_week"` // 1=Monday, 7=Sunday
	Start     string `json:"start"`       // "08:00"
	End       string `json:"end"`         // "18:00"
}

func (j JSONTimeSlots) Value() (driver.Value, error) {
	if j == nil {
		return "[]", nil
	}
	b, err := json.Marshal(j)
	return string(b), err
}

func (j *JSONTimeSlots) Scan(value interface{}) error {
	if value == nil {
		*j = []TimeSlot{}
		return nil
	}
	var bytes []byte
	switch v := value.(type) {
	case string:
		bytes = []byte(v)
	case []byte:
		bytes = v
	default:
		return errors.New("unsupported type for JSONTimeSlots")
	}
	return json.Unmarshal(bytes, j)
}

// JSONArea 偏好区域（简化版，存储中心点和半径）
type JSONArea struct {
	Lat    float64 `json:"lat"`
	Lng    float64 `json:"lng"`
	Radius float64 `json:"radius"` // 公里
}

func (j JSONArea) Value() (driver.Value, error) {
	b, err := json.Marshal(j)
	return string(b), err
}

func (j *JSONArea) Scan(value interface{}) error {
	if value == nil {
		return nil
	}
	var bytes []byte
	switch v := value.(type) {
	case string:
		bytes = []byte(v)
	case []byte:
		bytes = v
	default:
		return errors.New("unsupported type for JSONArea")
	}
	return json.Unmarshal(bytes, j)
}

type DriverAgentProfile struct {
	BaseModel
	DriverID           int64         `gorm:"uniqueIndex;not null" json:"driver_id"`
	PreferredAreas     JSONArea      `gorm:"type:text" json:"preferred_areas"`
	PreferredTimeSlots JSONTimeSlots `gorm:"type:text" json:"preferred_time_slots"`
	PreferredCarTypes  JSONArray     `gorm:"type:text" json:"preferred_car_types"`
	BasePrice          float64       `gorm:"type:real;not null;default:3.50" json:"base_price"`
	PriceRange         float64       `gorm:"type:real;not null;default:0.20" json:"price_range"`
	MinAcceptPrice     float64       `gorm:"type:real;not null;default:25.00" json:"min_accept_price"`
	AvailableTimeSlots JSONTimeSlots `gorm:"type:text" json:"available_time_slots"`
	IsOnline           bool          `gorm:"not null;default:false" json:"is_online"`
	UpdatedAt          time.Time     `json:"updated_at"`
}

func (DriverAgentProfile) TableName() string { return "driver_agent_profiles" }
