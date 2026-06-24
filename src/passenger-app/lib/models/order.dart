class Order {
  final int id;
  final String orderNo;
  final int passengerId;
  final int? driverId;
  final int status;
  final String pickupAddr;
  final double pickupLat;
  final double pickupLng;
  final String dropoffAddr;
  final double dropoffLat;
  final double dropoffLng;
  final double estPrice;
  final double actualPrice;
  final int estDistance;
  final int estDuration;
  final int carType;
  final DateTime? departureTime;
  final DateTime? assignedAt;
  final String? createdAt;
  final String? acceptedAt;
  final String? arrivedAt;
  final String? startedAt;
  final String? endedAt;
  final String? cancelledAt;
  final String cancelReason;
  final Driver? driver;

  const Order({
    required this.id,
    required this.orderNo,
    required this.passengerId,
    this.driverId,
    required this.status,
    required this.pickupAddr,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffAddr,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.estPrice,
    required this.actualPrice,
    required this.estDistance,
    required this.estDuration,
    required this.carType,
    this.departureTime,
    this.assignedAt,
    this.createdAt,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.endedAt,
    this.cancelledAt,
    required this.cancelReason,
    this.driver,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      orderNo: json['order_no'] as String,
      passengerId: json['passenger_id'] as int,
      driverId: json['driver_id'] as int?,
      status: json['status'] as int,
      pickupAddr: json['pickup_addr'] as String,
      pickupLat: (json['pickup_lat'] as num).toDouble(),
      pickupLng: (json['pickup_lng'] as num).toDouble(),
      dropoffAddr: json['dropoff_addr'] as String,
      dropoffLat: (json['dropoff_lat'] as num).toDouble(),
      dropoffLng: (json['dropoff_lng'] as num).toDouble(),
      estPrice: (json['est_price'] as num).toDouble(),
      actualPrice: (json['actual_price'] as num).toDouble(),
      estDistance: json['est_distance'] as int,
      estDuration: json['est_duration'] as int,
      carType: json['car_type'] as int,
      departureTime: json['departure_time'] != null
          ? DateTime.parse(json['departure_time'] as String)
          : null,
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : null,
      createdAt: json['created_at'] as String?,
      acceptedAt: json['accepted_at'] as String?,
      arrivedAt: json['arrived_at'] as String?,
      startedAt: json['started_at'] as String?,
      endedAt: json['ended_at'] as String?,
      cancelledAt: json['cancelled_at'] as String?,
      cancelReason: json['cancel_reason'] as String? ?? '',
      driver: json['driver'] != null ? Driver.fromJson(json['driver']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_no': orderNo,
      'passenger_id': passengerId,
      'driver_id': driverId,
      'status': status,
      'pickup_addr': pickupAddr,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'dropoff_addr': dropoffAddr,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      'est_price': estPrice,
      'actual_price': actualPrice,
      'est_distance': estDistance,
      'est_duration': estDuration,
      'car_type': carType,
      if (departureTime != null)
        'departure_time': departureTime!.toIso8601String(),
      if (assignedAt != null)
        'assigned_at': assignedAt!.toIso8601String(),
      'created_at': createdAt,
      'accepted_at': acceptedAt,
      'arrived_at': arrivedAt,
      'started_at': startedAt,
      'ended_at': endedAt,
      'cancelled_at': cancelledAt,
      'cancel_reason': cancelReason,
    };
  }

  String get statusText {
    switch (status) {
      case 1: return '待派单';
      case 2: return '已派单';
      case 3: return '司机已接单';
      case 5: return '司机已到达';
      case 6: return '行程中';
      case 7: return '已完成';
      case 8: return '已取消';
      default: return '未知';
    }
  }
}

class Driver {
  final int id;
  final String? nickname;
  final String? phone;
  final double? rating;
  final Vehicle? vehicle;

  const Driver({
    required this.id,
    this.nickname,
    this.phone,
    this.rating,
    this.vehicle,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as int,
      nickname: json['user']?['nickname'] as String?,
      phone: json['user']?['phone'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      vehicle: json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
    );
  }
}

class Vehicle {
  final int id;
  final String plateNumber;
  final String brand;
  final String model;
  final String color;
  final int carType;

  const Vehicle({
    required this.id,
    required this.plateNumber,
    required this.brand,
    required this.model,
    required this.color,
    required this.carType,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as int,
      plateNumber: json['plate_number'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      color: json['color'] as String,
      carType: json['car_type'] as int,
    );
  }
}
