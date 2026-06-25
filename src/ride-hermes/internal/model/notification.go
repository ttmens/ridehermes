package model

import "time"

const (
	NotificationTypeInfo    string = "info"
	NotificationTypeWarning string = "warning"
	NotificationTypeUrgent  string = "urgent"

	NotificationChannelSMS      string = "sms"
	NotificationChannelAppPush  string = "app_push"
	NotificationChannelInApp    string = "in_app"

	NotificationStatusPending  int8 = 1
	NotificationStatusSent     int8 = 2
	NotificationStatusFailed   int8 = 3
)

type Notification struct {
	BaseModel
	DriverID    int64     `gorm:"index;not null" json:"driver_id"`
	Type        string    `gorm:"size:20;not null" json:"type"`       // info | warning | urgent
	Channel     string    `gorm:"size:20;not null" json:"channel"`    // sms | app_push | in_app
	Title       string    `gorm:"size:100;not null" json:"title"`
	Content     string    `gorm:"type:text;not null" json:"content"`
	Status      int8      `gorm:"not null;default:1" json:"status"`   // 1=pending, 2=sent, 3=failed
	SentAt      *time.Time `json:"sent_at"`
	FailReason  string    `gorm:"type:text" json:"fail_reason,omitempty"`
	CreatedAt   time.Time `json:"created_at"`
}

func (Notification) TableName() string { return "notifications" }
