package service

import "math"

type RateTable struct {
	BaseFee float64
	PerKm   float64
	PerMin  float64
}

var rateTable = map[int8]RateTable{
	1: {BaseFee: 13.00, PerKm: 2.30, PerMin: 0.50}, // 快车
	2: {BaseFee: 18.00, PerKm: 3.50, PerMin: 0.80}, // 专车
	3: {BaseFee: 28.00, PerKm: 5.00, PerMin: 1.20}, // 豪华车
}

func EstimatePrice(pickupLat, pickupLng, dropoffLat, dropoffLng float64, carType int8) (price float64, distance int, duration int) {
	straightDist := haversineDistance(pickupLat, pickupLng, dropoffLat, dropoffLng)
	distance = int(straightDist * 1.3)
	duration = int(float64(distance) / 1000.0 / 30.0 * 3600)

	rate, ok := rateTable[carType]
	if !ok {
		rate = rateTable[1]
	}
	price = rate.BaseFee + float64(distance)/1000.0*rate.PerKm + float64(duration)/60.0*rate.PerMin
	price = math.Round(price*100) / 100
	return
}

func haversineDistance(lat1, lng1, lat2, lng2 float64) float64 {
	const earthRadius = 6371000.0
	dLat := (lat2 - lat1) * math.Pi / 180
	dLng := (lng2 - lng1) * math.Pi / 180
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180)*math.Cos(lat2*math.Pi/180)*
			math.Sin(dLng/2)*math.Sin(dLng/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return earthRadius * c
}
