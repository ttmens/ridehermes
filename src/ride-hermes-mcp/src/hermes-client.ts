const DEFAULT_BASE_URL = "https://ride.accseal.cn";

export interface HermesConfig {
  apiKey: string;
  userId: string;
  baseUrl?: string;
}

export interface OrderResponse {
  id: number;
  order_no: string;
  status: number;
  status_text: string;
  est_price: number;
  est_distance: number;
  est_duration: number;
  pickup_addr: string;
  dropoff_addr: string;
  driver?: {
    nickname: string;
    rating: number;
    vehicle: {
      plate_number: string;
      brand: string;
      model: string;
      color: string;
    };
  };
}

export interface EstimateResponse {
  est_price: number;
  est_distance: number;
  est_duration: number;
}

function getDefaultConfig(): Partial<HermesConfig> {
  return {
    apiKey: process.env.RIDEHERMES_API_KEY || "",
    userId: process.env.RIDEHERMES_USER_ID || "",
    baseUrl: process.env.RIDEHERMES_API_URL,
  };
}

export class HermesClient {
  private apiKey: string;
  private userId: string;
  private baseUrl: string;

  constructor(config?: Partial<HermesConfig>) {
    const defaults = getDefaultConfig();
    this.apiKey = config?.apiKey || defaults.apiKey || "";
    this.userId = config?.userId || defaults.userId || "";
    this.baseUrl = config?.baseUrl || defaults.baseUrl || DEFAULT_BASE_URL;
  }

  hasCredentials(): boolean {
    return this.apiKey.length > 0 && this.userId.length > 0;
  }

  private get headers(): Record<string, string> {
    return {
      "X-API-Key": this.apiKey,
      "X-User-ID": this.userId,
      "Content-Type": "application/json",
    };
  }

  async estimate(params: {
    pickup_addr: string;
    dropoff_addr: string;
    car_type?: number;
  }): Promise<EstimateResponse> {
    const resp = await fetch(`${this.baseUrl}/api/v1/agent/orders/estimate`, {
      method: "POST",
      headers: this.headers,
      body: JSON.stringify({
        pickup_addr: params.pickup_addr,
        dropoff_addr: params.dropoff_addr,
        car_type: params.car_type || 1,
      }),
    });

    const body = await resp.json();
    if (body.code !== 0) {
      throw new Error(`估价失败: ${body.message}`);
    }
    return {
      est_price: body.data.est_price,
      est_distance: body.data.est_distance,
      est_duration: body.data.est_duration,
    };
  }

  async estimateMulti(pickupAddr: string, dropoffAddr: string): Promise<any[]> {
    const base = await this.estimate({ pickup_addr: pickupAddr, dropoff_addr: dropoffAddr });
    return [
      { car_type: 1, car_type_name: "快车", est_price: base.est_price, est_distance: base.est_distance, est_duration: base.est_duration },
      { car_type: 2, car_type_name: "专车", est_price: Math.round(base.est_price * 1.7), est_distance: base.est_distance, est_duration: base.est_duration },
      { car_type: 3, car_type_name: "豪华车", est_price: Math.round(base.est_price * 2.6), est_distance: base.est_distance, est_duration: base.est_duration },
    ];
  }

  async book(params: {
    pickup_addr: string;
    dropoff_addr: string;
    pickup_lat?: number;
    pickup_lng?: number;
    dropoff_lat?: number;
    dropoff_lng?: number;
    car_type?: number;
    departure_time?: string;
  }): Promise<OrderResponse> {
    const resp = await fetch(`${this.baseUrl}/api/v1/agent/orders`, {
      method: "POST",
      headers: this.headers,
      body: JSON.stringify({
        pickup_addr: params.pickup_addr,
        pickup_lat: params.pickup_lat,
        pickup_lng: params.pickup_lng,
        dropoff_addr: params.dropoff_addr,
        dropoff_lat: params.dropoff_lat,
        dropoff_lng: params.dropoff_lng,
        car_type: params.car_type || 1,
        departure_time: params.departure_time || "",
      }),
    });

    const body = await resp.json();
    if (body.code !== 0) {
      throw new Error(`叫车失败: ${body.message}`);
    }
    return body.data;
  }

  async status(orderId: string): Promise<OrderResponse> {
    const resp = await fetch(
      `${this.baseUrl}/api/v1/agent/orders/${encodeURIComponent(orderId)}`,
      { headers: this.headers }
    );
    const body = await resp.json();
    if (body.code !== 0) {
      throw new Error(`查询失败: ${body.message}`);
    }
    return body.data;
  }

  async cancel(orderId: string, reason?: string): Promise<void> {
    const resp = await fetch(
      `${this.baseUrl}/api/v1/agent/orders/${encodeURIComponent(orderId)}/cancel`,
      {
        method: "POST",
        headers: this.headers,
        body: JSON.stringify({ reason: reason || "" }),
      }
    );
    const body = await resp.json();
    if (body.code !== 0) {
      throw new Error(`取消失败: ${body.message}`);
    }
  }

  async history(limit?: number): Promise<OrderResponse[]> {
    const params = new URLSearchParams();
    if (limit) params.set("limit", String(Math.min(limit, 50)));
    const url = `${this.baseUrl}/api/v1/agent/orders?${params.toString()}`;
    const resp = await fetch(url, { headers: this.headers });
    const body = await resp.json();
    if (body.code !== 0) {
      throw new Error(`查询历史失败: ${body.message}`);
    }
    return body.data.list || [];
  }

  // === v2.0 地图API方法 ===

  async mapsPoiSearch(keywords: string, city?: string): Promise<any[]> {
    const params = new URLSearchParams({ keywords });
    if (city) params.set("city", city);
    const resp = await fetch(`${this.baseUrl}/api/v1/maps/poi/search?${params}`, { headers: this.headers });
    const body = await resp.json();
    return body.data || [];
  }

  async mapsPlaceAround(location: string, keywords?: string, radius?: number): Promise<any[]> {
    const params = new URLSearchParams({ location });
    if (keywords) params.set("keywords", keywords);
    if (radius) params.set("radius", String(radius));
    const resp = await fetch(`${this.baseUrl}/api/v1/maps/poi/around?${params}`, { headers: this.headers });
    const body = await resp.json();
    return body.data || [];
  }

  async mapsPlaceSuggestion(keywords: string, city?: string): Promise<any[]> {
    const params = new URLSearchParams({ keywords });
    if (city) params.set("city", city);
    const resp = await fetch(`${this.baseUrl}/api/v1/maps/place/suggestion?${params}`, { headers: this.headers });
    const body = await resp.json();
    return body.data || [];
  }

  async mapsStaticMap(center: string, zoom?: number): Promise<{ url: string }> {
    const params = new URLSearchParams({ center });
    if (zoom) params.set("zoom", String(zoom));
    const resp = await fetch(`${this.baseUrl}/api/v1/maps/static?${params}`, { headers: this.headers });
    const body = await resp.json();
    return body.data || { url: "" };
  }

  async mapsRoutePlan(origin: string, destination: string, mode?: string): Promise<any> {
    const params = new URLSearchParams({ origin, destination });
    if (mode) params.set("mode", mode);
    const resp = await fetch(`${this.baseUrl}/api/v1/maps/route?${params}`, { headers: this.headers });
    const body = await resp.json();
    return body.data || {};
  }
}
