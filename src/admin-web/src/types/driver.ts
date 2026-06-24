export enum DriverStatus {
  PENDING = 1,
  ACTIVE = 2,
  DISABLED = 3,
}

export interface Vehicle {
  id: number;
  driver_id: number;
  plate_number: string;
  brand: string;
  model: string;
  color: string;
  car_type: number;
  status: number;
}

export interface Driver {
  id: number;
  user_id: number;
  real_name: string;
  id_card_no: string;
  license_no: string;
  status: DriverStatus;
  rating: number;
  balance: number;
  user?: import('./user').User;
  vehicle?: Vehicle;
  created_at: string;
}
