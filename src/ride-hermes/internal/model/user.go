package model

const (
	RoleAdmin     int8 = 1
	RolePassenger int8 = 2
	RoleDriver    int8 = 3
)

const (
	UserStatusNormal   int8 = 1
	UserStatusDisabled int8 = 2
)

type User struct {
	BaseModel
	Phone        string `gorm:"uniqueIndex;size:20;not null" json:"phone"`
	PasswordHash string `gorm:"size:255;not null" json:"-"`
	Nickname     string `gorm:"size:50;not null;default:''" json:"nickname"`
	Role         int8   `gorm:"not null;index" json:"role"`
	AvatarURL    string `gorm:"size:500;not null;default:''" json:"avatar_url"`
	Status       int8   `gorm:"not null;default:1" json:"status"`
}

func (User) TableName() string { return "users" }
