export interface LocationPoint {
  user_id: number;
  user_type: number;
  latitude: number;
  longitude: number;
  accuracy: number;
  speed: number;
  bearing: number;
  updated_at: string;
}

export interface DriverLocation extends LocationPoint {
  driver_id: number;
  real_name: string;
  phone: string;
  plate_number: string;
  car_type: number;
  online: boolean;
}
