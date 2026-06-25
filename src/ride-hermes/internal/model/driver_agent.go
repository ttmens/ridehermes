package model

const (
	DriverAgentStatusActive   int8 = 1
	DriverAgentStatusDisabled int8 = 2
)

type DriverAgent struct {
	BaseModel
	DriverID  int64  `gorm:"uniqueIndex;not null" json:"driver_id"`
	AgentType string `gorm:"size:50;not null" json:"agent_type"`
	AgentID   string `gorm:"size:100;not null" json:"agent_id"`
	Status    int8   `gorm:"not null;default:1;index" json:"status"`
	Config    string `gorm:"type:text" json:"config"`
	Driver    Driver `gorm:"foreignKey:DriverID" json:"driver,omitempty"`
}

func (DriverAgent) TableName() string { return "driver_agents" }
