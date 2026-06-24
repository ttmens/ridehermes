package model

import "time"

type AgentCallLog struct {
	ID           int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	CredentialID int64     `gorm:"index;not null" json:"credential_id"`
	UserID       int64     `gorm:"index;not null" json:"user_id"`
	AgentName    string    `gorm:"size:64;not null" json:"agent_name"`
	Endpoint     string    `gorm:"size:128;not null" json:"endpoint"`
	RequestBody  string    `gorm:"type:json" json:"request_body"`
	ResponseCode int       `json:"response_code"`
	OrderID      *int64    `json:"order_id"`
	IPAddress    string    `gorm:"size:45;not null;default:''" json:"ip_address"`
	LatencyMs    int       `gorm:"not null;default:0" json:"latency_ms"`
	CreatedAt    time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (AgentCallLog) TableName() string { return "agent_call_log" }
