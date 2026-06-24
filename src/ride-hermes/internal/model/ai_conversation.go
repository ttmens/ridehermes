package model

const (
	AIRoleUser int8 = 1
	AIRoleAI   int8 = 2
)

type AIConversation struct {
	BaseModel
	UserID         int64  `gorm:"index:idx_user_session,priority:1;not null" json:"user_id"`
	SessionID      string `gorm:"index:idx_user_session,priority:2;size:36;not null" json:"session_id"`
	Role           int8   `gorm:"not null" json:"role"`
	InputText      string `gorm:"type:text;not null" json:"input_text"`
	InputAudioURL  string `gorm:"size:500;not null;default:''" json:"input_audio_url"`
	IntentResult   *string `gorm:"type:json;null" json:"intent_result"`
	ResponseText   string `gorm:"type:text;not null" json:"response_text"`
}

func (AIConversation) TableName() string { return "ai_conversations" }
