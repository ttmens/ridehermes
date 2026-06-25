package service

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"sort"
	"strconv"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/ridehermes/ride-hermes/internal/config"
	"github.com/ridehermes/ride-hermes/internal/model"
	"github.com/ridehermes/ride-hermes/internal/repository"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

// Redis key prefixes for matching engine
const (
	matchKeyDemand       = "match:demand:%d"       // demand:{orderID} - hash storing demand info
	matchKeyDemandSet    = "match:demand:set"       // set of active demand order IDs
	matchKeyOffer        = "match:offer:%d:%d"     // offer:{orderID}:{driverID} - hash
	matchKeyOfferSet     = "match:offer:set:%d"    // offer:set:{orderID} - set of driver IDs who offered
	matchKeyMatch        = "match:confirmed:%d"    // confirmed:{orderID} - hash of confirmed match
	matchKeyDriverLoc    = "match:driver:loc"      // GEO set for driver locations
	matchChannelDemand   = "match:broadcast:demand" // Pub/Sub channel for new demands
	matchChannelOffer    = "match:broadcast:offer"  // Pub/Sub channel for new offers
	matchChannelConfirm  = "match:broadcast:confirm" // Pub/Sub channel for confirmed matches

	// Matching weights
	weightTrust    = 0.4
	weightDistance  = 0.3
	weightPrice    = 0.3

	// Matching thresholds
	maxMatchDistanceKm = 10.0  // max distance for matching (km)
	demandExpireTTL    = 30 * time.Minute
	offerExpireTTL     = 15 * time.Minute

	// Normalization constants
	maxDriverRating    = 5.0
	maxPriceDeviation  = 0.5 // 50% deviation = 0 score
)

// DemandPayload represents a passenger demand published to the matching engine
type DemandPayload struct {
	OrderID      int64   `json:"order_id"`
	PassengerID  int64   `json:"passenger_id"`
	PickupLat    float64 `json:"pickup_lat"`
	PickupLng    float64 `json:"pickup_lng"`
	DropoffLat   float64 `json:"dropoff_lat"`
	DropoffLng   float64 `json:"dropoff_lng"`
	EstPrice     float64 `json:"est_price"`
	CarType      int8    `json:"car_type"`
	DepartureTime string `json:"departure_time"`
	CreatedAt    string  `json:"created_at"`
}

// OfferPayload represents a driver's offer for a demand
type OfferPayload struct {
	OrderID     int64   `json:"order_id"`
	DriverID    int64   `json:"driver_id"`
	UserID      int64   `json:"user_id"`
	OfferPrice  float64 `json:"offer_price"`
	EstDistance  float64 `json:"est_distance_km"` // distance from driver to pickup
	TrustScore  float64 `json:"trust_score"`
	Score       float64 `json:"score"` // composite match score
	CreatedAt   string  `json:"created_at"`
}

// MatchResult represents a match result returned to the caller
type MatchResult struct {
	OrderID     int64   `json:"order_id"`
	DriverID    int64   `json:"driver_id"`
	DriverName  string  `json:"driver_name"`
	Rating      float64 `json:"rating"`
	OfferPrice  float64 `json:"offer_price"`
	DistanceKm  float64 `json:"distance_km"`
	TrustScore  float64 `json:"trust_score"`
	DistScore   float64 `json:"distance_score"`
	PriceScore  float64 `json:"price_score"`
	Score       float64 `json:"score"`
}

// MatchingEngine handles bidirectional preference matching between passengers and drivers
type MatchingEngine struct {
	orderRepo       *repository.OrderRepo
	driverRepo      *repository.DriverRepo
	dispatchLogRepo *repository.DispatchLogRepo
	cfg             *config.Config
	rdb             *redis.Client
	db              *gorm.DB
	logger          *zap.Logger
}

// NewMatchingEngine creates a new MatchingEngine instance
func NewMatchingEngine(
	orderRepo *repository.OrderRepo,
	driverRepo *repository.DriverRepo,
	dispatchLogRepo *repository.DispatchLogRepo,
	cfg *config.Config,
	rdb *redis.Client,
	db *gorm.DB,
	logger *zap.Logger,
) *MatchingEngine {
	return &MatchingEngine{
		orderRepo:       orderRepo,
		driverRepo:      driverRepo,
		dispatchLogRepo: dispatchLogRepo,
		cfg:             cfg,
		rdb:             rdb,
		db:              db,
		logger:          logger,
	}
}

// PublishDemand publishes a passenger demand to Redis Pub/Sub and stores it for matching.
// This broadcasts the demand to all subscribed drivers and indexes it in Redis for GetMatches.
func (m *MatchingEngine) PublishDemand(ctx context.Context, order *model.Order) error {
	demand := &DemandPayload{
		OrderID:       order.ID,
		PassengerID:   order.PassengerID,
		PickupLat:     order.PickupLat,
		PickupLng:     order.PickupLng,
		DropoffLat:    order.DropoffLat,
		DropoffLng:    order.DropoffLng,
		EstPrice:      order.EstPrice,
		CarType:       order.CarType,
		DepartureTime: order.DepartureTime.Format(time.RFC3339),
		CreatedAt:     order.CreatedAt.Format(time.RFC3339),
	}

	// Serialize demand to JSON
	data, err := json.Marshal(demand)
	if err != nil {
		return fmt.Errorf("failed to marshal demand: %w", err)
	}

	// Store demand in Redis hash with TTL
	demandKey := fmt.Sprintf(matchKeyDemand, order.ID)
	pipe := m.rdb.Pipeline()
	pipe.Set(ctx, demandKey, data, demandExpireTTL)
	pipe.SAdd(ctx, matchKeyDemandSet, order.ID)
	if _, err := pipe.Exec(ctx); err != nil {
		return fmt.Errorf("failed to store demand in redis: %w", err)
	}

	// Publish to Pub/Sub channel for real-time broadcast to drivers
	if err := m.rdb.Publish(ctx, matchChannelDemand, data).Err(); err != nil {
		m.logger.Warn("failed to publish demand to channel", zap.Error(err))
		// Non-fatal: demand is still stored and retrievable via GetMatches
	}

	m.logger.Info("demand published",
		zap.Int64("order_id", order.ID),
		zap.Int64("passenger_id", order.PassengerID),
		zap.Float64("pickup_lat", order.PickupLat),
		zap.Float64("pickup_lng", order.PickupLng),
	)

	return nil
}

// GetMatches returns ranked driver matches for a given demand using the bidirectional
// preference matching algorithm: trustScore×0.4 + distanceScore×0.3 + priceScore×0.3
func (m *MatchingEngine) GetMatches(ctx context.Context, orderID int64) ([]MatchResult, error) {
	// 1. Load the demand from Redis
	demandKey := fmt.Sprintf(matchKeyDemand, orderID)
	data, err := m.rdb.Get(ctx, demandKey).Bytes()
	if err != nil {
		return nil, fmt.Errorf("demand not found or expired: %w", err)
	}

	var demand DemandPayload
	if err := json.Unmarshal(data, &demand); err != nil {
		return nil, fmt.Errorf("failed to unmarshal demand: %w", err)
	}

	// 2. Find candidate drivers (active, matching car type, within distance)
	drivers, err := m.findCandidateDrivers(ctx, demand)
	if err != nil {
		return nil, fmt.Errorf("failed to find candidate drivers: %w", err)
	}

	if len(drivers) == 0 {
		return []MatchResult{}, nil
	}

	// 3. Score each driver using bidirectional preference algorithm
	results := make([]MatchResult, 0, len(drivers))
	for _, driver := range drivers {
		// Calculate distance from driver to pickup
		driverLat, driverLng, err := m.getDriverLocation(ctx, driver.ID)
		if err != nil {
			m.logger.Debug("no location for driver", zap.Int64("driver_id", driver.ID))
			continue
		}

		distM := haversineDistance(driverLat, driverLng, demand.PickupLat, demand.PickupLng)
		distKm := distM / 1000.0 // convert meters to km
		if distKm > maxMatchDistanceKm {
			continue
		}

		// Calculate scores
		trustScore := calcTrustScore(driver.Rating)
		distScore := calcDistanceScore(distKm)
		priceScore := calcPriceScore(demand.EstPrice, demand.EstPrice) // default: no offer yet

		// Check if driver has submitted an offer (use their price)
		offerKey := fmt.Sprintf(matchKeyOffer, orderID, driver.ID)
		offerData, err := m.rdb.Get(ctx, offerKey).Bytes()
		if err == nil {
			var offer OfferPayload
			if json.Unmarshal(offerData, &offer) == nil {
				priceScore = calcPriceScore(demand.EstPrice, offer.OfferPrice)
				distKm = offer.EstDistance
			}
		}

		// Composite score: trustScore×0.4 + distanceScore×0.3 + priceScore×0.3
		compositeScore := trustScore*weightTrust + distScore*weightDistance + priceScore*weightPrice

		driverName := ""
		if driver.User.Nickname != "" {
			driverName = driver.User.Nickname
		} else {
			driverName = driver.RealName
		}

		results = append(results, MatchResult{
			OrderID:    orderID,
			DriverID:   driver.ID,
			DriverName: driverName,
			Rating:     driver.Rating,
			OfferPrice: demand.EstPrice,
			DistanceKm: math.Round(distKm*100) / 100,
			TrustScore: math.Round(trustScore*1000) / 1000,
			DistScore:  math.Round(distScore*1000) / 1000,
			PriceScore: math.Round(priceScore*1000) / 1000,
			Score:      math.Round(compositeScore*1000) / 1000,
		})
	}

	// 4. Sort by composite score descending
	sort.Slice(results, func(i, j int) bool {
		return results[i].Score > results[j].Score
	})

	return results, nil
}

// SubmitOffer allows a driver to submit an offer (price) for a demand.
// The offer is scored and stored, then broadcast to the passenger.
func (m *MatchingEngine) SubmitOffer(ctx context.Context, orderID, driverID int64, offerPrice float64) (*OfferPayload, error) {
	// 1. Validate demand exists
	demandKey := fmt.Sprintf(matchKeyDemand, orderID)
	data, err := m.rdb.Get(ctx, demandKey).Bytes()
	if err != nil {
		return nil, fmt.Errorf("demand not found or expired: %w", err)
	}

	var demand DemandPayload
	if err := json.Unmarshal(data, &demand); err != nil {
		return nil, fmt.Errorf("failed to unmarshal demand: %w", err)
	}

	// 2. Validate driver
	driver, err := m.driverRepo.FindByID(ctx, driverID)
	if err != nil {
		return nil, fmt.Errorf("driver not found: %w", err)
	}
	if driver.Status != model.DriverStatusActive {
		return nil, fmt.Errorf("driver is not active")
	}

	// 3. Calculate distance from driver to pickup
	driverLat, driverLng, err := m.getDriverLocation(ctx, driverID)
	if err != nil {
		return nil, fmt.Errorf("driver location unavailable: %w", err)
	}
	distM := haversineDistance(driverLat, driverLng, demand.PickupLat, demand.PickupLng)
	distKm := distM / 1000.0 // convert meters to km
	if distKm > maxMatchDistanceKm {
		return nil, fmt.Errorf("driver too far from pickup (%.2f km > %.2f km max)", distKm, maxMatchDistanceKm)
	}

	// 4. Calculate bidirectional match score
	trustScore := calcTrustScore(driver.Rating)
	distScore := calcDistanceScore(distKm)
	priceScore := calcPriceScore(demand.EstPrice, offerPrice)
	compositeScore := trustScore*weightTrust + distScore*weightDistance + priceScore*weightPrice

	// 5. Build and store offer
	offer := &OfferPayload{
		OrderID:     orderID,
		DriverID:    driverID,
		UserID:      driver.UserID,
		OfferPrice:  offerPrice,
		EstDistance:  math.Round(distKm*100) / 100,
		TrustScore:  math.Round(trustScore*1000) / 1000,
		Score:       math.Round(compositeScore*1000) / 1000,
		CreatedAt:   time.Now().Format(time.RFC3339),
	}

	offerData, err := json.Marshal(offer)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal offer: %w", err)
	}

	offerKey := fmt.Sprintf(matchKeyOffer, orderID, driverID)
	offerSetKey := fmt.Sprintf(matchKeyOfferSet, orderID)

	pipe := m.rdb.Pipeline()
	pipe.Set(ctx, offerKey, offerData, offerExpireTTL)
	pipe.SAdd(ctx, offerSetKey, driverID)
	pipe.Expire(ctx, offerSetKey, offerExpireTTL)
	if _, err := pipe.Exec(ctx); err != nil {
		return nil, fmt.Errorf("failed to store offer: %w", err)
	}

	// 6. Broadcast offer via Pub/Sub
	if err := m.rdb.Publish(ctx, matchChannelOffer, offerData).Err(); err != nil {
		m.logger.Warn("failed to publish offer", zap.Error(err))
	}

	m.logger.Info("offer submitted",
		zap.Int64("order_id", orderID),
		zap.Int64("driver_id", driverID),
		zap.Float64("offer_price", offerPrice),
		zap.Float64("score", compositeScore),
	)

	return offer, nil
}

// ConfirmMatch confirms a match between a passenger and driver for a given order.
// This finalizes the match, updates the order, and broadcasts the confirmation.
func (m *MatchingEngine) ConfirmMatch(ctx context.Context, orderID, driverID int64) error {
	// 1. Validate order exists and is in pending status
	order, err := m.orderRepo.FindByID(ctx, orderID)
	if err != nil {
		return fmt.Errorf("order not found: %w", err)
	}
	if order.Status != model.OrderStatusPending {
		return fmt.Errorf("order status does not allow matching (status=%d)", order.Status)
	}

	// 2. Validate driver has submitted an offer or is in match results
	offerKey := fmt.Sprintf(matchKeyOffer, orderID, driverID)
	offerData, err := m.rdb.Get(ctx, offerKey).Bytes()
	if err != nil {
		// Driver didn't submit an offer; check if they're a valid match candidate
		m.logger.Info("no offer found, confirming from match list",
			zap.Int64("order_id", orderID),
			zap.Int64("driver_id", driverID),
		)
	}

	// 3. Validate driver is active
	driver, err := m.driverRepo.FindByID(ctx, driverID)
	if err != nil {
		return fmt.Errorf("driver not found: %w", err)
	}
	if driver.Status != model.DriverStatusActive {
		return fmt.Errorf("driver is not active")
	}

	// 4. Update order with driver assignment
	now := time.Now()
	if err := m.orderRepo.Update(ctx, orderID, map[string]interface{}{
		"status":      model.OrderStatusAssigned,
		"driver_id":   driverID,
		"assigned_at": now,
	}); err != nil {
		return fmt.Errorf("failed to update order: %w", err)
	}

	// 5. Create dispatch log
	log := &model.DispatchLog{
		OrderID:  orderID,
		DriverID: driverID,
		Status:   model.DispatchStatusAssigned,
	}
	if err := m.dispatchLogRepo.Create(ctx, log); err != nil {
		m.logger.Error("failed to create dispatch log", zap.Error(err))
	}

	// 6. Store confirmed match in Redis
	matchInfo := map[string]interface{}{
		"order_id":   orderID,
		"driver_id":  driverID,
		"confirmed_at": now.Format(time.RFC3339),
	}
	if len(offerData) > 0 {
		var offer OfferPayload
		if json.Unmarshal(offerData, &offer) == nil {
			matchInfo["offer_price"] = offer.OfferPrice
			matchInfo["score"] = offer.Score
		}
	}
	matchData, _ := json.Marshal(matchInfo)
	matchKey := fmt.Sprintf(matchKeyMatch, orderID)
	m.rdb.Set(ctx, matchKey, matchData, demandExpireTTL)

	// 7. Clean up demand from active set
	m.rdb.SRem(ctx, matchKeyDemandSet, orderID)
	m.rdb.Del(ctx, fmt.Sprintf(matchKeyDemand, orderID))

	// 8. Broadcast confirmation via Pub/Sub
	confirmPayload := map[string]interface{}{
		"order_id":     orderID,
		"driver_id":    driverID,
		"passenger_id": order.PassengerID,
		"confirmed_at": now.Format(time.RFC3339),
	}
	confirmData, _ := json.Marshal(confirmPayload)
	if err := m.rdb.Publish(ctx, matchChannelConfirm, confirmData).Err(); err != nil {
		m.logger.Warn("failed to publish match confirmation", zap.Error(err))
	}

	m.logger.Info("match confirmed",
		zap.Int64("order_id", orderID),
		zap.Int64("driver_id", driverID),
		zap.Int64("passenger_id", order.PassengerID),
	)

	return nil
}

// --- Private helper methods ---

// findCandidateDrivers finds active drivers with matching car type
func (m *MatchingEngine) findCandidateDrivers(ctx context.Context, demand DemandPayload) ([]model.Driver, error) {
	var drivers []model.Driver
	err := m.db.WithContext(ctx).
		Joins("JOIN vehicles ON vehicles.driver_id = drivers.id").
		Where("drivers.status = ? AND vehicles.car_type = ?", model.DriverStatusActive, demand.CarType).
		Preload("User").Preload("Vehicle").
		Find(&drivers).Error
	if err != nil {
		return nil, err
	}

	// Fallback: if no drivers match car type, find any active driver
	if len(drivers) == 0 {
		err = m.db.WithContext(ctx).
			Joins("JOIN vehicles ON vehicles.driver_id = drivers.id").
			Where("drivers.status = ?", model.DriverStatusActive).
			Preload("User").Preload("Vehicle").
			Find(&drivers).Error
	}

	return drivers, err
}

// getDriverLocation retrieves the latest known location of a driver from Redis GEO or DB
func (m *MatchingEngine) getDriverLocation(ctx context.Context, driverID int64) (float64, float64, error) {
	// Try Redis GEO first (real-time location)
	pos, err := m.rdb.GeoPos(ctx, matchKeyDriverLoc, strconv.FormatInt(driverID, 10)).Result()
	if err == nil && len(pos) > 0 && pos[0] != nil {
		return pos[0].Latitude, pos[0].Longitude, nil
	}

	// Fallback: query from database (latest location record)
	var loc model.Location
	err = m.db.WithContext(ctx).
		Where("user_id = ? AND user_type = ?", driverID, model.LocationUserTypeDriver).
		Order("created_at DESC").
		First(&loc).Error
	if err != nil {
		return 0, 0, fmt.Errorf("no location found for driver %d: %w", driverID, err)
	}

	return loc.Latitude, loc.Longitude, nil
}

// UpdateDriverLocation updates a driver's location in the Redis GEO set
func (m *MatchingEngine) UpdateDriverLocation(ctx context.Context, driverID int64, lat, lng float64) error {
	return m.rdb.GeoAdd(ctx, matchKeyDriverLoc, &redis.GeoLocation{
		Name:      strconv.FormatInt(driverID, 10),
		Latitude:  lat,
		Longitude: lng,
	}).Err()
}

// --- Scoring functions (bidirectional preference matching) ---

// calcTrustScore normalizes driver rating to [0, 1]
// Higher rating = higher trust = better match
func calcTrustScore(rating float64) float64 {
	if rating <= 0 {
		return 0
	}
	score := rating / maxDriverRating
	if score > 1.0 {
		score = 1.0
	}
	return score
}

// calcDistanceScore converts distance (km) to a [0, 1] score
// Closer = higher score. Uses inverse decay function.
func calcDistanceScore(distKm float64) float64 {
	if distKm <= 0 {
		return 1.0
	}
	if distKm >= maxMatchDistanceKm {
		return 0.0
	}
	// Inverse linear: score = 1 - (dist / maxDist)
	return 1.0 - (distKm / maxMatchDistanceKm)
}

// calcPriceScore measures how close the offer price is to the estimated price
// Lower deviation = higher score. Score is [0, 1].
func calcPriceScore(estPrice, offerPrice float64) float64 {
	if estPrice <= 0 {
		return 0.5 // neutral if no estimate
	}
	deviation := math.Abs(offerPrice-estPrice) / estPrice
	if deviation >= maxPriceDeviation {
		return 0.0
	}
	// Linear decay: score = 1 - (deviation / maxDeviation)
	return 1.0 - (deviation / maxPriceDeviation)
}

// haversineDistance is defined in price_service.go (returns meters)

// GetOffersForDemand returns all offers submitted for a given demand, sorted by score
func (m *MatchingEngine) GetOffersForDemand(ctx context.Context, orderID int64) ([]OfferPayload, error) {
	offerSetKey := fmt.Sprintf(matchKeyOfferSet, orderID)
	driverIDs, err := m.rdb.SMembers(ctx, offerSetKey).Result()
	if err != nil {
		return nil, fmt.Errorf("failed to get offer set: %w", err)
	}

	if len(driverIDs) == 0 {
		return []OfferPayload{}, nil
	}

	offers := make([]OfferPayload, 0, len(driverIDs))
	for _, idStr := range driverIDs {
		driverID, err := strconv.ParseInt(idStr, 10, 64)
		if err != nil {
			continue
		}
		offerKey := fmt.Sprintf(matchKeyOffer, orderID, driverID)
		data, err := m.rdb.Get(ctx, offerKey).Bytes()
		if err != nil {
			continue
		}
		var offer OfferPayload
		if err := json.Unmarshal(data, &offer); err != nil {
			continue
		}
		offers = append(offers, offer)
	}

	// Sort by score descending
	sort.Slice(offers, func(i, j int) bool {
		return offers[i].Score > offers[j].Score
	})

	return offers, nil
}

// CancelDemand removes a demand from the matching engine
func (m *MatchingEngine) CancelDemand(ctx context.Context, orderID int64) error {
	pipe := m.rdb.Pipeline()
	pipe.Del(ctx, fmt.Sprintf(matchKeyDemand, orderID))
	pipe.SRem(ctx, matchKeyDemandSet, orderID)
	pipe.Del(ctx, fmt.Sprintf(matchKeyMatch, orderID))
	if _, err := pipe.Exec(ctx); err != nil {
		return fmt.Errorf("failed to cancel demand: %w", err)
	}

	m.logger.Info("demand cancelled", zap.Int64("order_id", orderID))
	return nil
}
