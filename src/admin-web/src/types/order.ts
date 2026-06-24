export enum OrderStatus {
  PENDING = 1,
  ASSIGNED = 2,
  ACCEPTED = 3,
  WAITING_PICKUP = 5,
  IN_TRIP = 6,
  COMPLETED = 7,
  CANCELLED = 8,
}

export interface Order {
  id: number;
  order_no: string;
  passenger_id: number;
  driver_id: number | null;
  status: OrderStatus;
  pickup_addr: string;
  pickup_lat: number;
  pickup_lng: number;
  dropoff_addr: string;
  dropoff_lat: number;
  dropoff_lng: number;
  est_price: number;
  actual_price: number;
  est_distance: number;
  est_duration: number;
  car_type: number;
  departure_time: string;
  assigned_at: string | null;
  created_at: string;
  accepted_at: string | null;
  arrived_at: string | null;
  started_at: string | null;
  ended_at: string | null;
  cancelled_at: string | null;
  cancel_reason: string;
  passenger?: import('./user').User;
  driver?: import('./driver').Driver;
}
