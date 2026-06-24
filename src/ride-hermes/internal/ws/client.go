package ws

import (
	"context"
	"encoding/json"
	"sync"
	"time"

	"go.uber.org/zap"
	"nhooyr.io/websocket"
)

type Client struct {
	hub       *Hub
	conn      *websocket.Conn
	UserID    int64
	DriverID  int64 // drivers.id, set on WS connect when role=driver
	UserRole  int8
	send      chan []byte
	closeOnce sync.Once
	logger    *zap.Logger
}

func NewClient(hub *Hub, conn *websocket.Conn, userID int64, userRole int8) *Client {
	return &Client{
		hub:      hub,
		conn:     conn,
		UserID:   userID,
		UserRole: userRole,
		send:     make(chan []byte, 64),
	}
}

func (c *Client) SetLogger(l *zap.Logger) { c.logger = l }

func (c *Client) SetDriverID(id int64) { c.DriverID = id }

func (c *Client) SendMessage(msg Message) error {
	select {
	case c.send <- msg.Marshal():
		return nil
	default:
		return nil
	}
}

func (c *Client) ReadPump() {
	defer c.Close()
	ctx := context.Background()

	for {
		_, data, err := c.conn.Read(ctx)
		if err != nil {
			if c.logger != nil {
				c.logger.Debug("ws read error", zap.Error(err))
			}
			return
		}

		var msg Message
		if err := json.Unmarshal(data, &msg); err != nil {
			continue
		}

		switch msg.Type {
		case "location_update":
			c.handleLocationUpdate(msg.Data)
		case "heartbeat":
			c.SendMessage(Message{Type: "heartbeat_ack"})
		}
	}
}

func (c *Client) WritePump() {
	ctx := context.Background()
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()
	defer c.Close()

	for {
		select {
		case msg, ok := <-c.send:
			if !ok {
				return
			}
			if err := c.conn.Write(ctx, websocket.MessageText, msg); err != nil {
				return
			}
		case <-ticker.C:
			// Ping
			if err := c.conn.Ping(ctx); err != nil {
				return
			}
		}
	}
}

func (c *Client) handleLocationUpdate(data interface{}) {
	d, _ := json.Marshal(data)
	var loc struct {
		Latitude  float64 `json:"latitude"`
		Longitude float64 `json:"longitude"`
		Accuracy  float64 `json:"accuracy"`
		Speed     float64 `json:"speed"`
		Bearing   float64 `json:"bearing"`
	}
	if err := json.Unmarshal(d, &loc); err != nil {
		return
	}

	if c.UserRole == 3 { // driver
		driverID := c.DriverID
		if driverID == 0 {
			return
		}
		c.hub.UpdateDriverLocation(driverID, loc.Latitude, loc.Longitude, loc.Accuracy, loc.Speed, loc.Bearing)
	} else if c.UserRole == 2 { // passenger
		c.hub.UpdatePassengerLocation(c.UserID, loc.Latitude, loc.Longitude)
	}
}

func (c *Client) Close() {
	c.closeOnce.Do(func() {
		close(c.send)
		c.conn.Close(websocket.StatusNormalClosure, "")
	})
}
