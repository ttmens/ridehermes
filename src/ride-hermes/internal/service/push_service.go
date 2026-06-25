package service

import (
	"context"
	"fmt"
	"time"

	"github.com/ridehermes/ride-hermes/internal/model"
	"github.com/ridehermes/ride-hermes/internal/repository"
	"go.uber.org/zap"
)

type PushService struct {
	notifRepo  *repository.NotificationRepo
	driverRepo *repository.DriverRepo
	logger     *zap.Logger
}

func NewPushService(notifRepo *repository.NotificationRepo, driverRepo *repository.DriverRepo, logger *zap.Logger) *PushService {
	return &PushService{notifRepo: notifRepo, driverRepo: driverRepo, logger: logger}
}

// SendSMS 通过短信发送通知（模拟对接阿里云SMS）
func (s *PushService) SendSMS(ctx context.Context, driverID int64, title, content string) (*model.Notification, error) {
	notif := &model.Notification{
		DriverID: driverID,
		Type:     model.NotificationTypeInfo,
		Channel:  model.NotificationChannelSMS,
		Title:    title,
		Content:  content,
		Status:   model.NotificationStatusPending,
	}

	if err := s.notifRepo.Create(ctx, notif); err != nil {
		return nil, err
	}

	// 模拟SMS发送（实际应对接阿里云SMS API）
	// TODO: 对接阿里云SMS API
	driver, err := s.driverRepo.FindByID(ctx, driverID)
	if err == nil {
		s.logger.Info("[SMS] 短信发送",
			zap.Int64("driver_id", driverID),
			zap.String("phone", driver.RealName), // 实际应为driver phone
			zap.String("content", content),
		)
	}

	now := time.Now()
	s.notifRepo.UpdateStatus(ctx, notif.ID, model.NotificationStatusSent, "")
	notif.Status = model.NotificationStatusSent
	notif.SentAt = &now

	return notif, nil
}

// SendAppPush 通过APP推送发送通知（模拟对接极光/FCM）
func (s *PushService) SendAppPush(ctx context.Context, driverID int64, title, content string) (*model.Notification, error) {
	notif := &model.Notification{
		DriverID: driverID,
		Type:     model.NotificationTypeInfo,
		Channel:  model.NotificationChannelAppPush,
		Title:    title,
		Content:  content,
		Status:   model.NotificationStatusPending,
	}

	if err := s.notifRepo.Create(ctx, notif); err != nil {
		return nil, err
	}

	// 模拟APP推送（实际应对接极光/FCM）
	s.logger.Info("[APP Push] 推送发送",
		zap.Int64("driver_id", driverID),
		zap.String("title", title),
		zap.String("content", content),
	)

	now := time.Now()
	s.notifRepo.UpdateStatus(ctx, notif.ID, model.NotificationStatusSent, "")
	notif.Status = model.NotificationStatusSent
	notif.SentAt = &now

	return notif, nil
}

// SendRenewalReminder 发送续费提醒（整合SMS + APP推送）
func (s *PushService) SendRenewalReminder(ctx context.Context, driverID int64, daysLeft int, planName string) {
	notifType := s.getReminderType(daysLeft)
	title := s.getReminderTitle(daysLeft)
	content := fmt.Sprintf("您的%s套餐将在%d天后到期，请及时续费以继续享受服务。", planName, daysLeft)

	notif := &model.Notification{
		DriverID: driverID,
		Type:     notifType,
		Channel:  model.NotificationChannelInApp,
		Title:    title,
		Content:  content,
		Status:   model.NotificationStatusPending,
	}

	if err := s.notifRepo.Create(ctx, notif); err != nil {
		s.logger.Error("Failed to create renewal reminder", zap.Error(err))
		return
	}

	now := time.Now()
	s.notifRepo.UpdateStatus(ctx, notif.ID, model.NotificationStatusSent, "")
	notif.Status = model.NotificationStatusSent
	notif.SentAt = &now

	s.logger.Info("[Renewal Reminder] created",
		zap.Int64("driver_id", driverID),
		zap.String("type", notifType),
		zap.Int("days_left", daysLeft),
	)
}

// SendUrgentExpiration 发送到期紧急通知（最后1天）
func (s *PushService) SendUrgentExpiration(ctx context.Context, driverID int64, planName string) {
	title := "⚠️ 订阅即将到期"
	content := fmt.Sprintf("您的%s套餐将在明天到期！到期后Agent将自动下线，请立即续费。", planName)

	// SMS + APP推送双通道
	go s.SendSMS(ctx, driverID, title, content)
	go s.SendAppPush(ctx, driverID, title, content)
}

func (s *PushService) getReminderType(daysLeft int) string {
	if daysLeft <= 1 {
		return model.NotificationTypeUrgent
	} else if daysLeft <= 3 {
		return model.NotificationTypeWarning
	}
	return model.NotificationTypeInfo
}

func (s *PushService) getReminderTitle(daysLeft int) string {
	switch {
	case daysLeft <= 1:
		return "⚠️ 订阅即将到期，请立即续费"
	case daysLeft <= 3:
		return "⚡ 订阅即将到期，请尽快续费"
	case daysLeft <= 7:
		return "📢 订阅即将到期提醒"
	default:
		return "📢 续费提醒"
	}
}

// ListNotifications 获取推送记录
func (s *PushService) ListNotifications(ctx context.Context, offset, limit int) ([]model.Notification, int64, error) {
	return s.notifRepo.FindAll(ctx, offset, limit)
}

// ListDriverNotifications 获取司机推送记录
func (s *PushService) ListDriverNotifications(ctx context.Context, driverID int64, limit int) ([]model.Notification, error) {
	return s.notifRepo.FindByDriverID(ctx, driverID, limit)
}
