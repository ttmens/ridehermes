package model

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"time"
)

type JSONSlice []string

func (j JSONSlice) Value() (driver.Value, error) {
	if j == nil {
		return nil, nil
	}
	return json.Marshal(j)
}

func (j *JSONSlice) Scan(value interface{}) error {
	if value == nil {
		*j = nil
		return nil
	}
	bytes, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("failed to scan JSONSlice: expected []byte, got %T", value)
	}
	return json.Unmarshal(bytes, j)
}

const (
	AgentCredentialStatusActive   int8 = 1
	AgentCredentialStatusDisabled int8 = 0
)

type AgentCredential struct {
	BaseModel
	UserID      int64     `gorm:"index:idx_user_agent;not null" json:"user_id"`
	AgentName   string    `gorm:"size:64;index:idx_user_agent;not null" json:"agent_name"`
	APIKeyHash  string    `gorm:"uniqueIndex;size:128;not null" json:"-"` // never expose
	Permissions JSONSlice `gorm:"type:json" json:"permissions"`
	RateLimit   int       `gorm:"not null;default:60" json:"rate_limit"`
	Status      int8      `gorm:"not null;default:1" json:"status"`
	LastUsedAt  *time.Time `json:"last_used_at"`
}

func (AgentCredential) TableName() string { return "agent_credentials" }
