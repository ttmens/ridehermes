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
  final int estDistance;
  final int estDuration;
  final int carType;
  final DateTime? departureTime;
  final Passenger? passenger;

  const Order({
    required this.id,
    required this.orderNo,
    required this.passengerId,
    this.driverId,
    required this.status,
    required this.pickupAddr,
    this.pickupLat = 0,
    this.pickupLng = 0,
    required this.dropoffAddr,
    this.dropoffLat = 0,
    this.dropoffLng = 0,
    this.estPrice = 0,
    this.estDistance = 0,
    this.estDuration = 0,
    this.carType = 1,
    this.departureTime,
    this.passenger,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderNo: json['order_no'] as String? ?? '',
      passengerId: (json['passenger_id'] as num?)?.toInt() ?? 0,
      driverId: (json['driver_id'] as num?)?.toInt(),
      status: (json['status'] as num?)?.toInt() ?? 1,
      pickupAddr: json['pickup_addr'] as String? ?? '',
      pickupLat: (json['pickup_lat'] as num?)?.toDouble() ?? 0,
      pickupLng: (json['pickup_lng'] as num?)?.toDouble() ?? 0,
      dropoffAddr: json['dropoff_addr'] as String? ?? '',
      dropoffLat: (json['dropoff_lat'] as num?)?.toDouble() ?? 0,
      dropoffLng: (json['dropoff_lng'] as num?)?.toDouble() ?? 0,
      estPrice: (json['est_price'] as num?)?.toDouble() ?? 0,
      estDistance: (json['est_distance'] as num?)?.toInt() ?? 0,
      estDuration: (json['est_duration'] as num?)?.toInt() ?? 0,
      carType: (json['car_type'] as num?)?.toInt() ?? 1,
      departureTime: json['departure_time'] != null
          ? DateTime.tryParse(json['departure_time'] as String)
          : null,
      passenger: json['passenger'] != null
          ? Passenger.fromJson(json['passenger'] as Map<String, dynamic>)
          : null,
    );
  }

  String get statusText {
    switch (status) {
      case 1: return '待派单';
      case 2: return '已派单(待确认)';
      case 3: return '已接单';
      case 5: return '等待上车';
      case 6: return '行程中';
      case 7: return '已完成';
      case 8: return '已取消';
      default: return '未知';
    }
  }

  bool get canAccept => status == 2;
  bool get canArrive => status == 2 || status == 3;
  bool get canStart => status == 5;
  bool get canComplete => status == 6;
}

class Passenger {
  final int id;
  final String nickname;
  final String phone;

  const Passenger({
    required this.id,
    required this.nickname,
    required this.phone,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nickname: json['nickname'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}
