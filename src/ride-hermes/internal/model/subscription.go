package model

import "time"

const (
	// 订阅套餐类型
	PlanTypeBasic   int8 = 1 // 基础版
	PlanTypePro     int8 = 2 // 专业版
	PlanTypePremium int8 = 3 // 旗舰版

	// 订阅状态
	SubscriptionStatusActive   int8 = 1 // 有效
	SubscriptionStatusExpired  int8 = 2 // 已过期
	SubscriptionStatusCancelled int8 = 3 // 已取消

	// 支付状态
	PaymentStatusSuccess int8 = 1 // 成功
	PaymentStatusFailed  int8 = 2 // 失败
	PaymentStatusPending int8 = 3 // 待处理
)

var PlanTypeNames = map[int8]string{
	PlanTypeBasic:   "Basic",
	PlanTypePro:     "Pro",
	PlanTypePremium: "Premium",
}

// PlanConfig 套餐配置
type PlanConfig struct {
	MonthlyFee  float64 // 月费（元）
	RevenueRate float64 // 流水抽成比例
}

var PlanConfigs = map[int8]PlanConfig{
	PlanTypeBasic:   {MonthlyFee: 299, RevenueRate: 0.03},
	PlanTypePro:     {MonthlyFee: 499, RevenueRate: 0.05},
	PlanTypePremium: {MonthlyFee: 799, RevenueRate: 0.06},
}

type Subscription struct {
	BaseModel
	DriverID     int64     `gorm:"uniqueIndex;not null" json:"driver_id"`
	PlanType     int8      `gorm:"not null;default:1" json:"plan_type"`
	MonthlyFee   float64   `gorm:"type:decimal(10,2);not null" json:"monthly_fee"`
	RevenueRate  float64   `gorm:"type:decimal(5,4);not null" json:"revenue_rate"`
	StartDate    time.Time `gorm:"not null" json:"start_date"`
	ExpireDate   time.Time `gorm:"not null;index" json:"expire_date"`
	Status       int8      `gorm:"not null;default:1;index" json:"status"`
	TotalRevenue float64   `gorm:"type:decimal(14,2);not null;default:0.00" json:"total_revenue"`
	TotalCommission float64 `gorm:"type:decimal(14,2);not null;default:0.00" json:"total_commission"`
	Driver       Driver    `gorm:"foreignKey:DriverID" json:"driver,omitempty"`
}

func (Subscription) TableName() string { return "subscriptions" }

type SubscriptionPayment struct {
	BaseModel
	SubscriptionID int64     `gorm:"index;not null" json:"subscription_id"`
	DriverID       int64     `gorm:"index;not null" json:"driver_id"`
	Amount         float64   `gorm:"type:decimal(10,2);not null" json:"amount"`
	PlanType       int8      `gorm:"not null" json:"plan_type"`
	Status         int8      `gorm:"not null;default:3" json:"status"`
	PaymentDate    time.Time `gorm:"not null" json:"payment_date"`
	FailReason     string    `gorm:"size:255;not null;default:''" json:"fail_reason"`
	Subscription   Subscription `gorm:"foreignKey:SubscriptionID" json:"subscription,omitempty"`
}

func (SubscriptionPayment) TableName() string { return "subscription_payments" }
