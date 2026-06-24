package service

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/ridehermes/ride-hermes/internal/config"
	"github.com/ridehermes/ride-hermes/internal/model"
	"github.com/ridehermes/ride-hermes/internal/repository"
)

// Hardcoded placeholder coordinates for special addresses (v0.1 minimum).
// v0.2 will replace with user-address management.
var specialAddressCoords = map[string]struct{ Lat, Lng float64 }{
	"家":  {39.9150, 116.4040},
	"公司": {39.9042, 116.4074},
}

type AIService struct {
	cfg        *config.Config
	aiConvRepo *repository.AIConversationRepo
	httpClient *http.Client
	rdb        *redis.Client
}

func NewAIService(cfg *config.Config, aiConvRepo *repository.AIConversationRepo, rdb *redis.Client) *AIService {
	return &AIService{
		cfg:        cfg,
		aiConvRepo: aiConvRepo,
		httpClient: &http.Client{Timeout: time.Duration(cfg.AIService.Timeout) * time.Second},
		rdb:        rdb,
	}
}

type AIChatRequest struct {
	Text        string `json:"text"`
	SessionID   string `json:"session_id"`
	AudioBase64 string `json:"audio_base64"`
}

type AIChatResponse struct {
	SessionID    string        `json:"session_id"`
	ResponseText string        `json:"response_text"`
	Intent       *IntentResult `json:"intent"`
	OrderPreview *OrderPreview `json:"order_preview"`
	AsrText      string        `json:"asr_text"`
}

type IntentResult struct {
	Type          string        `json:"intent_type"`
	Pickup        *LocationInfo `json:"pickup"`
	Dropoff       *LocationInfo `json:"dropoff"`
	CarType       int8          `json:"car_type"`
	DepartureTime string        `json:"departure_time"`
	DepartureDesc string        `json:"departure_desc"`
	MissingFields []string      `json:"missing_fields"`
}

type LocationInfo struct {
	Address  string  `json:"address"`
	Lat      float64 `json:"lat"`
	Lng      float64 `json:"lng"`
	Resolved bool    `json:"resolved"`
}

type OrderPreview struct {
	EstPrice    float64 `json:"est_price"`
	EstDistance int     `json:"est_distance"`
	EstDuration int     `json:"est_duration"`
	CarType     int8    `json:"car_type"`
}

type aiChatPayload struct {
	SessionID   string       `json:"session_id"`
	UserID      int64        `json:"user_id"`
	Text        string       `json:"text"`
	AudioBase64 string       `json:"audio_base64,omitempty"`
	History     []aiMsgPair  `json:"history,omitempty"`
}

type aiMsgPair struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type aiChatResult struct {
	SessionID    string        `json:"session_id"`
	ResponseText string        `json:"response_text"`
	Intent       *IntentResult `json:"intent"`
	AsrText      string        `json:"asr_text"`
}

func (s *AIService) Chat(ctx context.Context, userID int64, req *AIChatRequest) (*AIChatResponse, error) {
	// Build history from recent conversations
	history, _ := s.aiConvRepo.FindBySession(ctx, userID, req.SessionID, 10)
	pairs := make([]aiMsgPair, 0)
	for _, h := range history {
		if h.Role == model.AIRoleUser {
			pairs = append(pairs, aiMsgPair{Role: "user", Content: h.InputText})
		} else if h.ResponseText != "" {
			pairs = append(pairs, aiMsgPair{Role: "assistant", Content: h.ResponseText})
		}
	}

	payload := aiChatPayload{
		SessionID:   req.SessionID,
		UserID:      userID,
		Text:        req.Text,
		AudioBase64: req.AudioBase64,
		History:     pairs,
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}

	resp, err := s.httpClient.Post(
		s.cfg.AIService.Addr+"/ai/chat",
		"application/json",
		bytes.NewReader(body),
	)
	if err != nil {
		return nil, fmt.Errorf("AI服务不可用: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("AI服务返回错误: status=%d, body=%s", resp.StatusCode, string(respBody))
	}

	var result aiChatResult
	if err := json.Unmarshal(respBody, &result); err != nil {
		return nil, err
	}

	// Save user message (use ASR text for voice input)
	userText := req.Text
	if userText == "" && result.AsrText != "" {
		userText = result.AsrText
	}
	s.aiConvRepo.Create(ctx, &model.AIConversation{
		UserID:       userID,
		SessionID:    req.SessionID,
		Role:         model.AIRoleUser,
		InputText:    userText,
		ResponseText: "",
	})

	// Save AI response
	intentJSON, _ := json.Marshal(result.Intent)
	intentJSONStr := string(intentJSON)
	s.aiConvRepo.Create(ctx, &model.AIConversation{
		UserID:       userID,
		SessionID:    req.SessionID,
		Role:         model.AIRoleAI,
		InputText:    "",
		IntentResult: &intentJSONStr,
		ResponseText: result.ResponseText,
	})

	response := &AIChatResponse{
		SessionID:    result.SessionID,
		ResponseText: result.ResponseText,
		Intent:       result.Intent,
		AsrText:      result.AsrText,
	}

	// Resolve special addresses (家/公司/current_location) to coordinates
	if result.Intent != nil {
		s.resolveSpecialAddresses(ctx, userID, result.Intent)
	}

	// Only calculate order_preview when intent is complete (no missing fields)
	if result.Intent != nil &&
		len(result.Intent.MissingFields) == 0 &&
		result.Intent.Pickup != nil && result.Intent.Dropoff != nil &&
		result.Intent.Pickup.Lat != 0 && result.Intent.Dropoff.Lat != 0 {
		price, dist, dur := EstimatePrice(
			result.Intent.Pickup.Lat, result.Intent.Pickup.Lng,
			result.Intent.Dropoff.Lat, result.Intent.Dropoff.Lng,
			result.Intent.CarType,
		)
		response.OrderPreview = &OrderPreview{
			EstPrice:    price,
			EstDistance: dist,
			EstDuration: dur,
			CarType:     result.Intent.CarType,
		}
	}

	return response, nil
}

// resolveSpecialAddresses fills in coordinates for special address markers.
func (s *AIService) resolveSpecialAddresses(ctx context.Context, userID int64, intent *IntentResult) {
	specialPickup := map[string]bool{
		"current_location": true, "当前位置": true, "这里": true,
	}
	if intent.Pickup != nil && !intent.Pickup.Resolved {
		if specialPickup[intent.Pickup.Address] {
			s.resolveCurrentLocation(ctx, userID, intent.Pickup)
		} else if coords, ok := specialAddressCoords[intent.Pickup.Address]; ok {
			intent.Pickup.Lat = coords.Lat
			intent.Pickup.Lng = coords.Lng
			intent.Pickup.Resolved = true
		}
	}
	if intent.Dropoff != nil && !intent.Dropoff.Resolved {
		if coords, ok := specialAddressCoords[intent.Dropoff.Address]; ok {
			intent.Dropoff.Lat = coords.Lat
			intent.Dropoff.Lng = coords.Lng
			intent.Dropoff.Resolved = true
		}
	}
}

func (s *AIService) resolveCurrentLocation(ctx context.Context, userID int64, loc *LocationInfo) {
	if s.rdb == nil {
		return
	}
	key := fmt.Sprintf("passenger:location:%d", userID)
	val, err := s.rdb.Get(ctx, key).Result()
	if err != nil {
		return
	}
	var lat, lng float64
	if _, err := fmt.Sscanf(val, "%f,%f", &lat, &lng); err == nil {
		loc.Lat = lat
		loc.Lng = lng
		loc.Resolved = true
	}
}

// CleanupSession removes the AI conversation session from Redis after order creation.
func (s *AIService) CleanupSession(ctx context.Context, sessionID string) {
	if s.rdb != nil && sessionID != "" {
		s.rdb.Del(ctx, fmt.Sprintf("ai:session:%s", sessionID))
	}
}

func (s *AIService) GetSessions(ctx context.Context, userID int64) ([]string, error) {
	return s.aiConvRepo.ListSessions(ctx, userID)
}
