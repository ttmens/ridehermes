import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/core/location/amap_service.dart';
import 'package:ride_hermes_passenger/providers/auth_provider.dart';

class WeatherCard extends ConsumerStatefulWidget {
  const WeatherCard({super.key});

  @override
  ConsumerState<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends ConsumerState<WeatherCard> {
  Map<String, dynamic>? _weather;
  bool _loading = false;
  String? _erroredCity;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadWeather);
  }

  Future<void> _loadWeather() async {
    final city = ref.read(locationServiceProvider).currentCity ?? '深圳市';
    if (_erroredCity == city && _weather == null) return;
    setState(() => _loading = true);
    final w = await AmapService().getCurrentWeather(city);
    if (!mounted) return;
    setState(() {
      _weather = w;
      _loading = false;
      if (w == null) _erroredCity = city;
    });
  }

  IconData _iconFor(String? weather) {
    if (weather == null) return Icons.cloud_queue;
    if (weather.contains('晴')) return Icons.wb_sunny;
    if (weather.contains('多云')) return Icons.cloud;
    if (weather.contains('阴')) return Icons.cloud_outlined;
    if (weather.contains('雨')) return Icons.umbrella;
    if (weather.contains('雪')) return Icons.ac_unit;
    if (weather.contains('雾') || weather.contains('霾')) return Icons.foggy;
    return Icons.cloud_queue;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final w = _weather;
    final weatherText = w?['weather'] as String?;
    final temp = w?['temperature'] as String?;
    final humidity = w?['humidity'] as String?;
    final wind = w?['winddirection'] as String?;
    final windPower = w?['windpower'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _iconFor(weatherText),
                color: primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _loading
                  ? const SizedBox(
                      height: 32,
                      child: Center(
                        child: SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : (w == null
                      ? Text(
                          '天气信息暂不可用',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  temp ?? '--',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Text('°C', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    weatherText ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '湿度 $humidity% · $wind $windPower 级',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              color: Colors.grey[400],
              onPressed: _loading
                  ? null
                  : () {
                      setState(() => _erroredCity = null);
                      _loadWeather();
                    },
            ),
          ],
        ),
      ),
    );
  }
}
