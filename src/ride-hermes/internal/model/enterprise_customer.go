package model

import "time"

const (
	ContractPrepaid  int8 = 1
	ContractMonthly  int8 = 2
	EnterpriseActive   int8 = 1
	EnterpriseExpired  int8 = 2
)

type EnterpriseCustomer struct {
	BaseModel
	CompanyName    string    `gorm:"size:100;not null" json:"company_name"`
	ContactName    string    `gorm:"size:50;not null" json:"contact_name"`
	ContactPhone   string    `gorm:"size:20;not null" json:"contact_phone"`
	ContractType   int8      `gorm:"not null" json:"contract_type"`
	ContractAmount float64   `gorm:"type:real;not null" json:"contract_amount"`
	ContractStart  time.Time `gorm:"not null" json:"contract_start"`
	ContractEnd    time.Time `gorm:"not null" json:"contract_end"`
	Status         int8      `gorm:"not null;default:1" json:"status"`
}

func (EnterpriseCustomer) TableName() string { return "enterprise_customers" }

type EnterpriseEmployee struct {
	BaseModel
	EnterpriseID int64  `gorm:"index;not null" json:"enterprise_id"`
	UserID       int64  `gorm:"not null" json:"user_id"`
	Name         string `gorm:"size:50;not null" json:"name"`
	Phone        string `gorm:"size:20;not null" json:"phone"`
	Status       int8   `gorm:"not null;default:1" json:"status"`
}

func (EnterpriseEmployee) TableName() string { return "enterprise_employees" }
