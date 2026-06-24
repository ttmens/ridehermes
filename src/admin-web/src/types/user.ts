export enum UserRole {
  ADMIN = 1,
  PASSENGER = 2,
  DRIVER = 3,
}

export enum UserStatus {
  NORMAL = 1,
  DISABLED = 2,
}

export interface User {
  id: number;
  phone: string;
  nickname: string;
  role: UserRole;
  avatar_url: string;
  status: UserStatus;
  created_at: string;
  updated_at: string;
}

export interface CreatePassengerReq {
  phone: string;
  password: string;
  nickname: string;
}

export interface CreateDriverReq {
  phone: string;
  password: string;
  nickname: string;
  real_name: string;
  id_card_no: string;
  license_no: string;
  vehicle: {
    plate_number: string;
    brand: string;
    model: string;
    color: string;
    car_type: number;
  };
}
