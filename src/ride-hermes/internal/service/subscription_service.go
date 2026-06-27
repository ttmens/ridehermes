package service

import (
	"context"
	"fmt"
	"log"
	"math"
	"time"

	"github.com/ridehermes/ride-hermes/internal/model"
	"github.com/ridehermes/ride-hermes/internal/repository"
)

type SubscriptionService struct {
	subRepo    *repository.SubscriptionRepo
	driverRepo *repository.DriverRepo
}

func NewSubscriptionService(subRepo *repository.SubscriptionRepo, driverRepo *repository.DriverRepo) *SubscriptionService {
	return &SubscriptionService{subRepo: subRepo, driverRepo: driverRepo}
}

// CreateRequest 创建订阅请求
type CreateRequest struct {
	DriverID int64 `json:"driver_id" binding:"required"`
	PlanType int8  `json:"plan_type" binding:"required,min=1,max=3"`
}

// CreateResponse 创建订阅响应
type CreateResponse struct {
	SubscriptionID int64   `json:"subscription_id"`
	PlanType       string  `json:"plan_type"`
	MonthlyFee     float64 `json:"monthly_fee"`
	RevenueRate    float64 `json:"revenue_rate"`
	ExpireDate     string  `json:"expire_date"`
}

// Create 创建新订阅
func (s *SubscriptionService) Create(ctx context.Context, req *CreateRequest) (*CreateResponse, error) {
	// 验证套餐类型
	planConfig, ok := model.PlanConfigs[req.PlanType]
	if !ok {
		return nil, fmt.Errorf("无效的套餐类型")
	}

	// 检查司机是否已有有效订阅
	existing, _ := s.subRepo.FindByDriverID(ctx, req.DriverID)
	if existing != nil {
		return nil, fmt.Errorf("该司机已有有效订阅，请先取消或等待到期")
	}

	// 验证司机存在
	_, err := s.driverRepo.FindByID(ctx, req.DriverID)
	if err != nil {
		return nil, fmt.Errorf("司机不存在")
	}

	now := time.Now()
	expireDate := now.AddDate(0, 1, 0) // 一个月后到期

	sub := &model.Subscription{
		DriverID:        req.DriverID,
		PlanType:        req.PlanType,
		MonthlyFee:      planConfig.MonthlyFee,
		RevenueRate:     planConfig.RevenueRate,
		StartDate:       now,
		ExpireDate:      expireDate,
		Status:          model.SubscriptionStatusActive,
		TotalRevenue:    0,
		TotalCommission: 0,
	}

	if err := s.subRepo.Create(ctx, sub); err != nil {
		return nil, fmt.Errorf("创建订阅失败: %w", err)
	}

	// 记录首次支付
	payment := &model.SubscriptionPayment{
		SubscriptionID: sub.ID,
		DriverID:       req.DriverID,
		Amount:         planConfig.MonthlyFee,
		PlanType:       req.PlanType,
		Status:         model.PaymentStatusSuccess,
		PaymentDate:    now,
	}
	if err := s.subRepo.CreatePayment(ctx, payment); err != nil {
		log.Printf("[WARN] 创建支付记录失败: %v", err)
	}

	return &CreateResponse{
		SubscriptionID: sub.ID,
		PlanType:       model.PlanTypeNames[req.PlanType],
		MonthlyFee:     planConfig.MonthlyFee,
		RevenueRate:    planConfig.RevenueRate,
		ExpireDate:     expireDate.Format("2006-01-02"),
	}, nil
}

// Renew 续费订阅
func (s *SubscriptionService) Renew(ctx context.Context, subscriptionID int64) (*CreateResponse, error) {
	sub, err := s.subRepo.FindByID(ctx, subscriptionID)
	if err != nil {
		return nil, fmt.Errorf("未找到订阅")
	}
	if sub == nil {
		return nil, fmt.Errorf("订阅不存在")
	}

	planConfig, ok := model.PlanConfigs[sub.PlanType]
	if !ok {
		return nil, fmt.Errorf("套餐配置异常")
	}

	now := time.Now()
	// 续费从当前到期日开始（如果已过期则从现在开始）
	baseDate := sub.ExpireDate
	if baseDate.Before(now) {
		baseDate = now
	}
	newExpireDate := baseDate.AddDate(0, 1, 0)

	// 更新订阅到期日
	if err := s.subRepo.Update(ctx, sub.ID, map[string]interface{}{
		"expire_date": newExpireDate,
		"status":      model.SubscriptionStatusActive,
	}); err != nil {
		return nil, fmt.Errorf("续费失败: %w", err)
	}

	// 记录续费支付
	payment := &model.SubscriptionPayment{
		SubscriptionID: sub.ID,
		DriverID:       sub.DriverID,
		Amount:         planConfig.MonthlyFee,
		PlanType:       sub.PlanType,
		Status:         model.PaymentStatusSuccess,
		PaymentDate:    now,
	}
	if err := s.subRepo.CreatePayment(ctx, payment); err != nil {
		log.Printf("[WARN] 创建续费支付记录失败: %v", err)
	}

	return &CreateResponse{
		SubscriptionID: sub.ID,
		PlanType:       model.PlanTypeNames[sub.PlanType],
		MonthlyFee:     planConfig.MonthlyFee,
		RevenueRate:    sub.RevenueRate,
		ExpireDate:     newExpireDate.Format("2006-01-02"),
	}, nil
}

// Cancel 取消订阅
func (s *SubscriptionService) Cancel(ctx context.Context, subscriptionID int64) error {
	sub, err := s.subRepo.FindByID(ctx, subscriptionID)
	if err != nil {
		return fmt.Errorf("未找到订阅记录")
	}
	if sub == nil {
		return fmt.Errorf("订阅不存在")
	}

	err = s.subRepo.Update(ctx, subscriptionID, map[string]interface{}{
		"status": model.SubscriptionStatusCancelled,
	})
	if err != nil {
		return fmt.Errorf("取消订阅失败: %w", err)
	}

	return nil
}

// GetByDriverID 查询司机当前有效订阅
func (s *SubscriptionService) GetByDriverID(ctx context.Context, driverID int64) (*model.Subscription, error) {
	return s.subRepo.FindByDriverID(ctx, driverID)
}

// GetByID 根据ID查询订阅
func (s *SubscriptionService) GetByID(ctx context.Context, id int64) (*model.Subscription, error) {
	return s.subRepo.FindByID(ctx, id)
}

// List 查询订阅列表（管理员）
func (s *SubscriptionService) List(ctx context.Context, status *int8, offset, limit int) ([]model.Subscription, int64, error) {
	return s.subRepo.List(ctx, status, offset, limit)
}

// RecordRevenue 记录流水并计算佣金
func (s *SubscriptionService) RecordRevenue(ctx context.Context, subscriptionID int64, orderAmount float64) error {
	sub, err := s.subRepo.FindByID(ctx, subscriptionID)
	if err != nil {
		return fmt.Errorf("订阅不存在")
	}
	if sub.Status != model.SubscriptionStatusActive {
		return fmt.Errorf("订阅已失效")
	}

	commission := math.Round(orderAmount*sub.RevenueRate*100) / 100
	if err := s.subRepo.AddRevenue(ctx, subscriptionID, orderAmount, commission); err != nil {
		return fmt.Errorf("记录流水失败: %w", err)
	}
	return nil
}

// DriverStats 司机订阅统计
type DriverStats struct {
	DriverID          int64   `json:"driver_id"`
	TotalRevenue      float64 `json:"total_revenue"`
	TotalCommission   float64 `json:"total_commission"`
	SubscriptionFee   float64 `json:"subscription_fee"`
	NetIncome         float64 `json:"net_income"`
	SavedVsCommission float64 `json:"saved_vs_commission"`
}

// GetDriverStats 获取司机订阅统计
func (s *SubscriptionService) GetDriverStats(ctx context.Context, driverID int64) (*DriverStats, error) {
	sub, err := s.subRepo.FindByDriverID(ctx, driverID)
	if err != nil {
		return nil, fmt.Errorf("未找到订阅记录")
	}

	// 计算按普通佣金比例（假设默认15%）需要支付的佣金
	defaultCommissionRate := 0.15
	defaultCommission := sub.TotalRevenue * defaultCommissionRate
	saved := math.Round((defaultCommission-sub.TotalCommission)*100) / 100
	netIncome := math.Round((sub.TotalRevenue-sub.TotalCommission)*100) / 100

	return &DriverStats{
		DriverID:          driverID,
		TotalRevenue:      sub.TotalRevenue,
		TotalCommission:   sub.TotalCommission,
		SubscriptionFee:   sub.MonthlyFee,
		NetIncome:         netIncome,
		SavedVsCommission: saved,
	}, nil
}

// ProcessMonthlyBilling 月费扣款 Cron Job
// 频率：每天00:00执行
// 逻辑：查询到期订阅 → 扣款 → 续期 / 失败则标记过期
func (s *SubscriptionService) ProcessMonthlyBilling(ctx context.Context) {
	log.Println("[Cron] ProcessMonthlyBilling 开始执行")

	// 1. 查询已到期需要扣款的订阅
	expired, err := s.subRepo.FindExpired(ctx)
	if err != nil {
		log.Printf("[Cron] 查询到期订阅失败: %v", err)
		return
	}

	successCount := 0
	failCount := 0

	for _, sub := range expired {
		err := s.processBillingForSubscription(ctx, &sub)
		if err != nil {
			failCount++
			log.Printf("[Cron] 扣款失败 driver_id=%d sub_id=%d: %v", sub.DriverID, sub.ID, err)
		} else {
			successCount++
		}
	}

	// 2. 查询即将到期（7天内）的订阅，发送提醒
	expiring, err := s.subRepo.FindExpiringSoon(ctx, 7)
	if err != nil {
		log.Printf("[Cron] 查询即将到期订阅失败: %v", err)
	} else {
		for _, sub := range expiring {
			daysLeft := int(time.Until(sub.ExpireDate).Hours() / 24)
			s.sendRenewalReminder(ctx, &sub, daysLeft)
		}
	}

	log.Printf("[Cron] ProcessMonthlyBilling 完成: 成功=%d, 失败=%d, 提醒=%d",
		successCount, failCount, len(expiring))
}

// processBillingForSubscription 处理单个订阅的扣款
func (s *SubscriptionService) processBillingForSubscription(ctx context.Context, sub *model.Subscription) error {
	planConfig, ok := model.PlanConfigs[sub.PlanType]
	if !ok {
		return fmt.Errorf("套餐配置不存在")
	}

	now := time.Now()

	// 模拟扣款（实际应对接支付网关）
	paymentSuccess := s.chargeDriver(ctx, sub.DriverID, planConfig.MonthlyFee)

	payment := &model.SubscriptionPayment{
		SubscriptionID: sub.ID,
		DriverID:       sub.DriverID,
		Amount:         planConfig.MonthlyFee,
		PlanType:       sub.PlanType,
		PaymentDate:    now,
	}

	if paymentSuccess {
		payment.Status = model.PaymentStatusSuccess
		if err := s.subRepo.CreatePayment(ctx, payment); err != nil {
			return fmt.Errorf("记录支付失败: %w", err)
		}
		// 续期一个月
		newExpireDate := sub.ExpireDate.AddDate(0, 1, 0)
		return s.subRepo.Update(ctx, sub.ID, map[string]interface{}{
			"expire_date": newExpireDate,
			"status":      model.SubscriptionStatusActive,
		})
	}

	// 扣款失败：标记过期
	payment.Status = model.PaymentStatusFailed
	payment.FailReason = "余额不足或支付失败"
	if err := s.subRepo.CreatePayment(ctx, payment); err != nil {
		log.Printf("[WARN] 记录失败支付记录出错: %v", err)
	}

	return s.subRepo.Update(ctx, sub.ID, map[string]interface{}{
		"status": model.SubscriptionStatusExpired,
	})
}

// chargeDriver 模拟扣款（实际应对接支付/钱包系统）
func (s *SubscriptionService) chargeDriver(ctx context.Context, driverID int64, amount float64) bool {
	driver, err := s.driverRepo.FindByID(ctx, driverID)
	if err != nil {
		return false
	}
	if driver.Balance < amount {
		return false
	}
	// 扣减余额
	if err := s.driverRepo.Update(ctx, driverID, map[string]interface{}{
		"balance": driver.Balance - amount,
	}); err != nil {
		return false
	}
	return true
}

// sendRenewalReminder 发送续费提醒
func (s *SubscriptionService) sendRenewalReminder(ctx context.Context, sub *model.Subscription, daysLeft int) {
	// 根据剩余天数确定提醒级别
	var reminderType string
	switch {
	case daysLeft <= 1:
		reminderType = "urgent"
	case daysLeft <= 3:
		reminderType = "warning"
	default:
		reminderType = "info"
	}

	log.Printf("[Reminder] driver_id=%d, plan=%s, days_left=%d, type=%s",
		sub.DriverID, model.PlanTypeNames[sub.PlanType], daysLeft, reminderType)

	// TODO: 对接推送服务（APP推送 + 短信）
	// pushService.Send(ctx, sub.DriverID, reminderType, ...)
	// smsService.Send(ctx, sub.DriverID, ...)
}

// StartCronJobs 启动定时任务（由 main 或启动器调用）
func (s *SubscriptionService) StartCronJobs(ctx context.Context) {
	go s.runBillingCron(ctx)
	go s.runReminderCron(ctx)
}

// runBillingCron 每天00:00执行月费扣款
func (s *SubscriptionService) runBillingCron(ctx context.Context) {
	for {
		now := time.Now()
		next := time.Date(now.Year(), now.Month(), now.Day()+1, 0, 0, 0, 0, now.Location())
		timer := time.NewTimer(time.Until(next))
		<-timer.C

		s.ProcessMonthlyBilling(ctx)
	}
}

// runReminderCron 每天09:00执行续费提醒
func (s *SubscriptionService) runReminderCron(ctx context.Context) {
	for {
		now := time.Now()
		next := time.Date(now.Year(), now.Month(), now.Day(), 9, 0, 0, 0, now.Location())
		if next.Before(now) {
			next = next.AddDate(0, 0, 1)
		}
		timer := time.NewTimer(time.Until(next))
		<-timer.C

		log.Println("[Cron] RenewalReminder 开始执行")
		expiring, err := s.subRepo.FindExpiringSoon(ctx, 7)
		if err != nil {
			log.Printf("[Cron] 查询即将到期订阅失败: %v", err)
			continue
		}
		for _, sub := range expiring {
			daysLeft := int(time.Until(sub.ExpireDate).Hours() / 24)
			s.sendRenewalReminder(ctx, &sub, daysLeft)
		}
		log.Printf("[Cron] RenewalReminder 完成: 提醒数=%d", len(expiring))
	}
}
