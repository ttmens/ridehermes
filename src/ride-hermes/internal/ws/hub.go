package ws

import (
	"context"
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/ridehermes/ride-hermes/internal/config"
	"github.com/ridehermes/ride-hermes/internal/middleware"
	"go.uber.org/zap"
)

type Hub struct {
	clients       sync.Map // userID -> *Client
	rdb           *redis.Client
	cfg           *config.Config
	logger        *zap.Logger
}

func NewHub(rdb *redis.Client) *Hub {
	return &Hub{
		rdb: rdb,
	}
}

func (h *Hub) SetConfig(cfg *config.Config)  { h.cfg = cfg }
func (h *Hub) SetLogger(l *zap.Logger)        { h.logger = l }

func (h *Hub) Run() {
	// Hub run loop — currently no background subscriptions needed.
	// Location updates and order notifications are handled via direct SendToUser calls.
}

func (h *Hub) RegisterClient(userID int64, client *Client) {
	// Close existing connection if any
	if old, ok := h.clients.LoadAndDelete(userID); ok {
		old.(*Client).Close()
	}
	h.clients.Store(userID, client)
}

func (h *Hub) UnregisterClient(userID int64) {
	h.clients.Delete(userID)
}

func (h *Hub) GetClient(userID int64) *Client {
	if c, ok := h.clients.Load(userID); ok {
		return c.(*Client)
	}
	return nil
}

func (h *Hub) SendToUser(userID int64, msg Message) error {
	if c := h.GetClient(userID); c != nil {
		return c.SendMessage(msg)
	}
	return fmt.Errorf("user not connected")
}

func (h *Hub) BroadcastToPassengers(msg Message) {
	h.clients.Range(func(key, value interface{}) bool {
		client := value.(*Client)
		if client.UserRole == 2 { // passenger
			client.SendMessage(msg)
		}
		return true
	})
}

func (h *Hub) BroadcastToDrivers(msg Message) {
	h.clients.Range(func(key, value interface{}) bool {
		client := value.(*Client)
		if client.UserRole == 3 { // driver
			client.SendMessage(msg)
		}
		return true
	})
}

func (h *Hub) DriverOnline(driverID int64, carType int8) {
	h.rdb.ZAdd(context.Background(), "driver:online", redis.Z{
		Score:  float64(time.Now().Unix()),
		Member: driverID,
	})
}

func (h *Hub) DriverOffline(driverID int64, carType int8) {
	ctx := context.Background()
	h.rdb.ZRem(ctx, "driver:online", driverID)
	h.rdb.Del(ctx, fmt.Sprintf("driver:location:%d", driverID))
}

func (h *Hub) UpdateDriverLocation(driverID int64, lat, lng, accuracy, speed, bearing float64) {
	ctx := context.Background()
	key := fmt.Sprintf("driver:location:%d", driverID)
	h.rdb.HSet(ctx, key,
		"lat", lat,
		"lng", lng,
		"accuracy", accuracy,
		"speed", speed,
		"bearing", bearing,
	)
}

func (h *Hub) UpdatePassengerLocation(userID int64, lat, lng float64) {
	ctx := context.Background()
	key := fmt.Sprintf("passenger:location:%d", userID)
	h.rdb.Set(ctx, key, fmt.Sprintf("%f,%f", lat, lng), 24*time.Hour)
}

func (h *Hub) GetDriverLocation(driverID int64) map[string]string {
	key := fmt.Sprintf("driver:location:%d", driverID)
	result, _ := h.rdb.HGetAll(context.Background(), key).Result()
	return result
}

// AuthenticateWS validates JWT token from WebSocket query parameter.
func (h *Hub) AuthenticateWS(tokenString string) (*middleware.Claims, error) {
	return middleware.ParseToken(tokenString, h.cfg.JWT.Secret)
}

// Message represents a WebSocket message.
type Message struct {
	Type string      `json:"type"`
	Data interface{} `json:"data"`
}

func (m Message) Marshal() []byte {
	b, _ := json.Marshal(m)
	return b
}
