import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:dio/dio.dart';
import 'package:ride_hermes_passenger/config/app_config.dart';

class AmapService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  Future<LatLng?> geocode(String address, {String? city}) async {
    if (address.trim().isEmpty) return null;
    try {
      final params = <String, dynamic>{
        'key': AppConfig.amapWebKey,
        'address': address,
        'output': 'JSON',
      };
      if (city != null && city.isNotEmpty) {
        params['city'] = city;
      }
      final resp = await _dio.get(
        'https://restapi.amap.com/v3/geocode/geo',
        queryParameters: params,
      );
      final data = resp.data as Map<String, dynamic>;
      if (data['status'] == '1') {
        final codes = data['geocodes'] as List?;
        if (codes != null && codes.isNotEmpty) {
          final loc = codes[0]['location'] as String?;
          if (loc != null && loc.contains(',')) {
            final parts = loc.split(',');
            return LatLng(double.parse(parts[1]), double.parse(parts[0]));
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final resp = await _dio.get(
        'https://restapi.amap.com/v3/geocode/regeo',
        queryParameters: {
          'key': AppConfig.amapWebKey,
          'location': '$lng,$lat',
          'output': 'JSON',
        },
      );
      final data = resp.data as Map<String, dynamic>;
      if (data['status'] == '1') {
        final regeo = data['regeocode'] as Map<String, dynamic>?;
        return regeo?['formatted_address'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> getCityFromLocation(double lat, double lng) async {
    try {
      final resp = await _dio.get(
        'https://restapi.amap.com/v3/geocode/regeo',
        queryParameters: {
          'key': AppConfig.amapWebKey,
          'location': '$lng,$lat',
          'output': 'JSON',
        },
      );
      final data = resp.data as Map<String, dynamic>;
      if (data['status'] == '1') {
        final regeo = data['regeocode'] as Map<String, dynamic>?;
        final comp = regeo?['addressComponent'] as Map<String, dynamic>?;
        if (comp != null) {
          final city = comp['city'];
          if (city is String && city.isNotEmpty) return city;
          // 直辖市 city 可能为空，用 province
          final province = comp['province'];
          if (province is String && province.isNotEmpty) return province;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<LatLng?> ipLocation() async {
    try {
      final resp = await _dio.get(
        'https://restapi.amap.com/v3/ip',
        queryParameters: {
          'key': AppConfig.amapWebKey,
          'output': 'JSON',
        },
      );
      final data = resp.data as Map<String, dynamic>;
      if (data['status'] == '1') {
        final rect = data['rectangle'] as String?;
        if (rect != null && rect.contains(';')) {
          final parts = rect.split(';');
          final lb = parts[0].split(',');
          final rt = parts[1].split(',');
          final centerLat =
              (double.parse(lb[1]) + double.parse(rt[1])) / 2;
          final centerLng =
              (double.parse(lb[0]) + double.parse(rt[0])) / 2;
          return LatLng(centerLat, centerLng);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getCurrentWeather(String city) async {
    try {
      final resp = await _dio.get(
        'https://restapi.amap.com/v3/weather/weatherInfo',
        queryParameters: {
          'key': AppConfig.amapWebKey,
          'city': city,
          'extensions': 'base',
          'output': 'JSON',
        },
      );
      final data = resp.data as Map<String, dynamic>;
      if (data['status'] == '1') {
        final lives = data['lives'] as List?;
        if (lives != null && lives.isNotEmpty) {
          return lives[0] as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<LatLng>?> getDrivingRoute(LatLng origin, LatLng dest) async {
    try {
      final resp = await _dio.get(
        'https://restapi.amap.com/v3/direction/driving',
        queryParameters: {
          'key': AppConfig.amapWebKey,
          'origin': '${origin.longitude},${origin.latitude}',
          'destination': '${dest.longitude},${dest.latitude}',
          'output': 'JSON',
        },
      );
      final data = resp.data as Map<String, dynamic>;
      if (data['status'] == '1') {
        final route = data['route'] as Map<String, dynamic>?;
        final paths = route?['paths'] as List?;
        if (paths != null && paths.isNotEmpty) {
          final steps = paths[0]['steps'] as List;
          final points = <LatLng>[];
          for (final step in steps) {
            final polyline = step['polyline'] as String;
            for (final coord in polyline.split(';')) {
              final parts = coord.split(',');
              if (parts.length == 2) {
                points.add(LatLng(double.parse(parts[1]), double.parse(parts[0])));
              }
            }
          }
          return points;
        }
      }
    } catch (_) {}
    return null;
  }

  // === v2.0 新增方法 ===
  Future<List<Map<String, dynamic>>> poiSearch(
    String keywords, {
    String? city,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        "key": AppConfig.amapWebKey,
        "keywords": keywords,
        "output": "JSON",
        "offset": limit,
        "extensions": "all",
      };
      if (city != null && city.isNotEmpty) {
        params["city"] = city;
      }
      final resp = await _dio.get(
        "https://restapi.amap.com/v3/place/text",
        queryParameters: params,
      );
      final data = resp.data as Map<String, dynamic>;
      if (data["status"] == "1") {
        final pois = data["pois"] as List? ?? [];
        return pois.map<Map<String, dynamic>>((poi) => {
          "name": poi["name"] ?? "",
          "address": poi["address"] ?? "",
          "location": poi["location"] ?? "",
          "tel": poi["tel"] ?? "",
          "type": poi["type"] ?? "",
        }).toList();
      }
    } catch (_) {}
    return [];
  }
  Future<List<Map<String, dynamic>>> placeSuggestion(
    String keywords, {
    String? city,
  }) async {
    try {
      final params = <String, dynamic>{
        "key": AppConfig.amapWebKey,
        "keywords": keywords,
        "output": "JSON",
      };
      if (city != null && city.isNotEmpty) {
        params["city"] = city;
      }
      final resp = await _dio.get(
        "https://restapi.amap.com/v3/assistant/inputtips",
        queryParameters: params,
      );
      final data = resp.data as Map<String, dynamic>;
      if (data["status"] == "1") {
        final tips = data["tips"] as List? ?? [];
        return tips.where((tip) {
          final id = tip["id"];
          return id != null && id != "" && id is String;
        }).map<Map<String, dynamic>>((tip) => {
          "name": tip["name"] ?? "",
          "address": tip["address"] ?? "",
          "location": tip["location"] ?? "",
          "district": tip["district"] ?? "",
        }).toList();
      }
    } catch (_) {}
    return [];
  }
  Future<List<Map<String, dynamic>>> placeAround(
    double lat, double lng, {
    String keywords = "",
    int radius = 1000,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        "key": AppConfig.amapWebKey,
        "location": "$lng,$lat",
        "radius": radius,
        "output": "JSON",
        "offset": limit,
        "extensions": "all",
      };
      if (keywords.isNotEmpty) {
        params["keywords"] = keywords;
      }
      final resp = await _dio.get(
        "https://restapi.amap.com/v3/place/around",
        queryParameters: params,
      );
      final data = resp.data as Map<String, dynamic>;
      if (data["status"] == "1") {
        final pois = data["pois"] as List? ?? [];
        return pois.map<Map<String, dynamic>>((poi) => {
          "name": poi["name"] ?? "",
          "address": poi["address"] ?? "",
          "location": poi["location"] ?? "",
          "distance": poi["distance"] ?? 0,
          "type": poi["type"] ?? "",
        }).toList();
      }
    } catch (_) {}
    return [];
  }
}
