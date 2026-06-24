package service

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"fmt"

	"github.com/ridehermes/ride-hermes/internal/model"
	"github.com/ridehermes/ride-hermes/internal/repository"
	"gorm.io/gorm"
)

type AgentService struct {
	credRepo *repository.AgentCredentialRepo
	callRepo *repository.AgentCallLogRepo
	userRepo *repository.UserRepo
}

func NewAgentService(
	credRepo *repository.AgentCredentialRepo,
	callRepo *repository.AgentCallLogRepo,
	userRepo *repository.UserRepo,
) *AgentService {
	return &AgentService{credRepo: credRepo, callRepo: callRepo, userRepo: userRepo}
}

func generateAPIKey() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return "rh_" + hex.EncodeToString(b), nil
}

func hashAPIKey(key string) string {
	h := sha256.Sum256([]byte(key))
	return hex.EncodeToString(h[:])
}

func (s *AgentService) GenerateAPIKey(ctx context.Context, userID uint64, agentName string) (*model.AgentCredential, string, error) {
	user, err := s.userRepo.FindByID(ctx, int64(userID))
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, "", fmt.Errorf("用户不存在")
		}
		return nil, "", err
	}

	if user.Role != model.RolePassenger {
		return nil, "", fmt.Errorf("仅乘客用户可生成 API Key")
	}

	apiKey, err := generateAPIKey()
	if err != nil {
		return nil, "", err
	}

	cred := &model.AgentCredential{
		UserID:      int64(userID),
		AgentName:   agentName,
		APIKeyHash:  hashAPIKey(apiKey),
		Permissions: model.JSONSlice{"ride:estimate", "ride:book", "ride:cancel", "ride:status", "ride:history"},
		RateLimit:   60,
		Status:      model.AgentCredentialStatusActive,
	}

	if err := s.credRepo.Create(ctx, cred); err != nil {
		return nil, "", err
	}
	return cred, apiKey, nil
}

func (s *AgentService) ValidateAPIKey(ctx context.Context, apiKey string) (*model.AgentCredential, error) {
	hash := hashAPIKey(apiKey)
	cred, err := s.credRepo.FindByAPIKeyHash(ctx, hash)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("无效的 API Key")
		}
		return nil, err
	}
	if cred.Status != model.AgentCredentialStatusActive {
		return nil, fmt.Errorf("API Key 已被禁用")
	}
	return cred, nil
}

func (s *AgentService) RevokeKey(ctx context.Context, id, userID uint64) error {
	return s.credRepo.UpdateStatus(ctx, id, model.AgentCredentialStatusDisabled)
}

func (s *AgentService) ListKeys(ctx context.Context, userID uint64) ([]model.AgentCredential, error) {
	return s.credRepo.ListByUserID(ctx, userID)
}

func (s *AgentService) ListAllCredentials(ctx context.Context, offset, limit int) ([]model.AgentCredential, int64, error) {
	return s.credRepo.ListAll(ctx, offset, limit)
}

func (s *AgentService) LogCall(ctx context.Context, credID int64, userID int64, agentName, endpoint, reqBody, ip string, statusCode int, orderID *int64, latencyMs int) {
	_ = s.callRepo.Create(ctx, &model.AgentCallLog{
		CredentialID: credID,
		UserID:       userID,
		AgentName:    agentName,
		Endpoint:     endpoint,
		RequestBody:  reqBody,
		ResponseCode: statusCode,
		OrderID:      orderID,
		IPAddress:    ip,
		LatencyMs:    latencyMs,
	})
	_ = s.credRepo.UpdateLastUsed(ctx, uint64(credID))
}

func (s *AgentService) GetCallLogs(ctx context.Context, userID uint64, offset, limit int) ([]model.AgentCallLog, int64, error) {
	return s.callRepo.ListByUserID(ctx, userID, offset, limit)
}

func (s *AgentService) GetCallLogsByCredential(ctx context.Context, credID uint64, offset, limit int) ([]model.AgentCallLog, int64, error) {
	return s.callRepo.ListByCredentialID(ctx, credID, offset, limit)
}
