package model

import "gorm.io/gorm"

func AutoMigrate(db *gorm.DB) error {
	return db.AutoMigrate(
		&User{},
		&Driver{},
		&Vehicle{},
		&Order{},
		&Location{},
		&DispatchLog{},
		&AIConversation{},
		&AgentCredential{},
		&AgentCallLog{},
		&MatchingDemand{},
		&MatchingOffer{},
		&Subscription{},
		&SubscriptionPayment{},
		&RevenueRecord{},
		&DriverAgentProfile{},
		&TrustScore{},
		&Evaluation{},
		&EnterpriseCustomer{},
		&EnterpriseEmployee{},
		&RecurringTrip{},
		&Notification{},
	)
}
