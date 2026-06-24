package service

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"time"
)

type AmapService struct {
	apiKey string
	client *http.Client
}

type GeocodeResult struct {
	Address  string  `json:"address"`
	Lat      float64 `json:"lat"`
	Lng      float64 `json:"lng"`
	Resolved bool    `json:"resolved"`
}

func NewAmapService(apiKey string) *AmapService {
	return &AmapService{
		apiKey: apiKey,
		client: &http.Client{Timeout: 10 * time.Second},
	}
}

func (s *AmapService) Geocode(address string) (*GeocodeResult, error) {
	if s.apiKey == "" {
		return &GeocodeResult{Address: address, Resolved: false}, nil
	}

	params := url.Values{}
	params.Set("key", s.apiKey)
	params.Set("address", address)
	params.Set("output", "JSON")

	resp, err := s.client.Get(fmt.Sprintf("https://restapi.amap.com/v3/geocode/geo?%s", params.Encode()))
	if err != nil {
		return &GeocodeResult{Address: address, Resolved: false}, fmt.Errorf("地理编码请求失败: %w", err)
	}
	defer resp.Body.Close()

	var result struct {
		Status   string `json:"status"`
		Geocodes []struct {
			Location string `json:"location"`
		} `json:"geocodes"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return &GeocodeResult{Address: address, Resolved: false}, nil
	}

	if result.Status != "1" || len(result.Geocodes) == 0 {
		return &GeocodeResult{Address: address, Resolved: false}, nil
	}

	location := result.Geocodes[0].Location
	var lng, lat float64
	if _, err := fmt.Sscanf(location, "%f,%f", &lng, &lat); err != nil {
		return &GeocodeResult{Address: address, Resolved: false}, nil
	}

	return &GeocodeResult{
		Address:  address,
		Lat:      lat,
		Lng:      lng,
		Resolved: true,
	}, nil
}

// === v2.0 新增方法 ===

// POI POI搜索结果
type POI struct {
	Name     string `json:"name"`
	Address  string `json:"address"`
	Location string `json:"location"`
	Tel      string `json:"tel,omitempty"`
	Type     string `json:"type,omitempty"`
	Distance string `json:"distance,omitempty"`
}

// POISearch 关键词搜索POI
func (s *AmapService) POISearch(keywords, city string) ([]POI, error) {
	if s.apiKey == "" {
		return nil, fmt.Errorf("AMap API key not configured")
	}

	params := url.Values{}
	params.Set("key", s.apiKey)
	params.Set("keywords", keywords)
	params.Set("output", "JSON")
	params.Set("extensions", "all")
	params.Set("offset", "20")
	if city != "" {
		params.Set("city", city)
	}

	resp, err := s.client.Get(fmt.Sprintf("https://restapi.amap.com/v3/place/text?%s", params.Encode()))
	if err != nil {
		return nil, fmt.Errorf("POI搜索请求失败: %w", err)
	}
	defer resp.Body.Close()

	var result struct {
		Status string `json:"status"`
		POIs   []struct {
			Name     string `json:"name"`
			Address  string `json:"address"`
			Location string `json:"location"`
			Tel      string `json:"tel"`
			Type     string `json:"type"`
		} `json:"pois"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	if result.Status != "1" {
		return []POI{}, nil
	}

	pois := make([]POI, len(result.POIs))
	for i, p := range result.POIs {
		pois[i] = POI{
			Name:     p.Name,
			Address:  p.Address,
			Location: p.Location,
			Tel:      p.Tel,
			Type:     p.Type,
		}
	}
	return pois, nil
}

// PlaceAround 周边搜索POI
func (s *AmapService) PlaceAround(location, keywords, radius string) ([]POI, error) {
	if s.apiKey == "" {
		return nil, fmt.Errorf("AMap API key not configured")
	}

	params := url.Values{}
	params.Set("key", s.apiKey)
	params.Set("location", location)
	params.Set("radius", radius)
	params.Set("output", "JSON")
	params.Set("extensions", "all")
	params.Set("offset", "20")
	if keywords != "" {
		params.Set("keywords", keywords)
	}

	resp, err := s.client.Get(fmt.Sprintf("https://restapi.amap.com/v3/place/around?%s", params.Encode()))
	if err != nil {
		return nil, fmt.Errorf("周边搜索请求失败: %w", err)
	}
	defer resp.Body.Close()

	var result struct {
		Status string `json:"status"`
		POIs   []struct {
			Name     string `json:"name"`
			Address  string `json:"address"`
			Location string `json:"location"`
			Distance string `json:"distance"`
			Type     string `json:"type"`
		} `json:"pois"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	if result.Status != "1" {
		return []POI{}, nil
	}

	pois := make([]POI, len(result.POIs))
	for i, p := range result.POIs {
		pois[i] = POI{
			Name:     p.Name,
			Address:  p.Address,
			Location: p.Location,
			Distance: p.Distance,
			Type:     p.Type,
		}
	}
	return pois, nil
}

// Suggestion 输入提示结果
type Suggestion struct {
	Name     string `json:"name"`
	Address  string `json:"address"`
	Location string `json:"location"`
	District string `json:"district"`
}

// PlaceSuggestion 输入提示/自动补全
func (s *AmapService) PlaceSuggestion(keywords, city string) ([]Suggestion, error) {
	if s.apiKey == "" {
		return nil, fmt.Errorf("AMap API key not configured")
	}

	params := url.Values{}
	params.Set("key", s.apiKey)
	params.Set("keywords", keywords)
	params.Set("output", "JSON")
	if city != "" {
		params.Set("city", city)
	}

	resp, err := s.client.Get(fmt.Sprintf("https://restapi.amap.com/v3/assistant/inputtips?%s", params.Encode()))
	if err != nil {
		return nil, fmt.Errorf("输入提示请求失败: %w", err)
	}
	defer resp.Body.Close()

	var result struct {
		Status string `json:"status"`
		Tips   []map[string]interface{} `json:"tips"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	if result.Status != "1" {
		return []Suggestion{}, nil
	}

	suggestions := make([]Suggestion, 0)
	for _, t := range result.Tips {
		// id 可能是字符串或数组，只处理有有效id的
		idVal := t["id"]
		var idStr string
		switch v := idVal.(type) {
		case string:
			idStr = v
		case []interface{}:
			if len(v) > 0 {
				if s, ok := v[0].(string); ok {
					idStr = s
				}
			}
		}
		if idStr == "" {
			continue
		}
		
		name, _ := t["name"].(string)
		address, _ := t["address"].(string)
		location, _ := t["location"].(string)
		district, _ := t["district"].(string)
		
		suggestions = append(suggestions, Suggestion{
			Name:     name,
			Address:  address,
			Location: location,
			District: district,
		})
	}
	return suggestions, nil
}

// StaticMapURL 生成静态地图URL
func (s *AmapService) StaticMapURL(center, zoom, size, markers string) string {
	params := url.Values{}
	params.Set("key", s.apiKey)
	params.Set("center", center)
	params.Set("zoom", zoom)
	params.Set("size", size)
	if markers != "" {
		params.Set("markers", markers)
	}
	return fmt.Sprintf("https://restapi.amap.com/v3/staticmap?%s", params.Encode())
}

// RouteStep 路线步骤
type RouteStep struct {
	Instruction string `json:"instruction"`
	Road        string `json:"road"`
	Distance    string `json:"distance"`
	Duration    string `json:"duration"`
	Polyline    string `json:"polyline"`
}

// RouteResult 路线规划结果
type RouteResult struct {
	Origin      string      `json:"origin"`
	Destination string      `json:"destination"`
	Distance    string      `json:"distance"`
	Duration    string      `json:"duration"`
	Steps       []RouteStep `json:"steps"`
}

// RoutePlan 路线规划
func (s *AmapService) RoutePlan(origin, destination, mode string) (*RouteResult, error) {
	if s.apiKey == "" {
		return nil, fmt.Errorf("AMap API key not configured")
	}

	params := url.Values{}
	params.Set("key", s.apiKey)
	params.Set("origin", origin)
	params.Set("destination", destination)
	params.Set("output", "JSON")

	var apiURL string
	switch mode {
	case "walking":
		apiURL = fmt.Sprintf("https://restapi.amap.com/v3/direction/walking?%s", params.Encode())
	case "bicycling":
		apiURL = fmt.Sprintf("https://restapi.amap.com/v4/direction/bicycling?%s", params.Encode())
	case "transit":
		params.Set("city", "北京")
		apiURL = fmt.Sprintf("https://restapi.amap.com/v3/direction/transit/integrated?%s", params.Encode())
	default:
		apiURL = fmt.Sprintf("https://restapi.amap.com/v3/direction/driving?%s", params.Encode())
	}

	resp, err := s.client.Get(apiURL)
	if err != nil {
		return nil, fmt.Errorf("路线规划请求失败: %w", err)
	}
	defer resp.Body.Close()

	var result struct {
		Status string `json:"status"`
		Route  struct {
			Origin      string `json:"origin"`
			Destination string `json:"destination"`
			Paths       []struct {
				Distance string `json:"distance"`
				Duration string `json:"duration"`
				Steps    []struct {
					Instruction string `json:"instruction"`
					Road        string `json:"road"`
					Distance    string `json:"distance"`
					Duration    string `json:"duration"`
					Polyline    string `json:"polyline"`
				} `json:"steps"`
			} `json:"paths"`
		} `json:"route"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	if result.Status != "1" || len(result.Route.Paths) == 0 {
		return &RouteResult{
			Origin:      origin,
			Destination: destination,
		}, nil
	}

	path := result.Route.Paths[0]
	steps := make([]RouteStep, len(path.Steps))
	for i, step := range path.Steps {
		steps[i] = RouteStep{
			Instruction: step.Instruction,
			Road:        step.Road,
			Distance:    step.Distance,
			Duration:    step.Duration,
			Polyline:    step.Polyline,
		}
	}

	return &RouteResult{
		Origin:      result.Route.Origin,
		Destination: result.Route.Destination,
		Distance:    path.Distance,
		Duration:    path.Duration,
		Steps:       steps,
	}, nil
}
