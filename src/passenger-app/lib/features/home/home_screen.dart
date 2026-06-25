import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:ride_hermes_passenger/providers/auth_provider.dart';
import 'package:ride_hermes_passenger/core/location/amap_service.dart';
import 'package:ride_hermes_passenger/features/home/widgets/greeting_bar.dart';
import 'package:ride_hermes_passenger/models/chat_message.dart';
import 'package:ride_hermes_passenger/features/home/widgets/ai_chat_bar.dart';
import 'package:ride_hermes_passenger/features/home/widgets/quick_commands.dart';
import 'package:ride_hermes_passenger/features/home/widgets/promo_banner.dart';
import 'package:ride_hermes_passenger/features/home/widgets/service_grid.dart';
import 'package:ride_hermes_passenger/features/home/widgets/safety_assurance.dart';
import 'package:ride_hermes_passenger/features/home/widgets/weather_card.dart';
import 'package:ride_hermes_passenger/features/home/widgets/recent_trips.dart';
import 'package:ride_hermes_passenger/models/poi.dart';
import 'package:ride_hermes_passenger/shared/widgets/address_input.dart';
import 'package:ride_hermes_passenger/features/plan_trip/plan_trip_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<ChatMessage> _messages = [];
  StreamSubscription? _locationSub;
  double _currentLat = 0;
  double _currentLng = 0;
  String _pickupAddr = '安排行程';
  bool _locationStarted = false;
  String _sessionId = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initLocation());
  }

  Future<void> _initLocation() async {
    try {
      final status = await Permission.location.request();
      debugPrint('[HomeScreen] permission result: $status');
      if (status.isGranted || status.isLimited) {
        _startLocationUpdates();
      } else {
        if (mounted) setState(() => _pickupAddr = '请开启定位权限');
      }
    } catch (e) {
      debugPrint('[HomeScreen] permission error: $e');
      if (mounted) setState(() => _pickupAddr = '定位权限获取失败');
    }
  }

  void _startLocationUpdates() {
    if (_locationStarted) return;
    _locationStarted = true;

    final locSvc = ref.read(locationServiceProvider);
    locSvc.startLocationUpdates();
    debugPrint('[HomeScreen] startLocationUpdates called');

    _locationSub = locSvc.onLocationChanged.listen((loc) {
      if (!mounted) return;
      debugPrint('[HomeScreen] location: ${loc.lat}, ${loc.lng}');
      setState(() {
        _currentLat = loc.lat;
        _currentLng = loc.lng;
      });
      final addr = locSvc.currentAddress;
      if (addr != null && addr.isNotEmpty) {
        setState(() => _pickupAddr = addr);
      } else {
        // Fallback: reverse geocode via REST API
        _reverseGeocode(loc.lat, loc.lng);
      }
    });

    // Fallback: if no location after 6 seconds, keep pickup prompt visible
    Future.delayed(const Duration(seconds: 6), () {
      if (_currentLat == 0 && _currentLng == 0 && mounted) {
        debugPrint('[HomeScreen] AMap SDK location timeout, using map showMyLocation');
        setState(() => _pickupAddr = '安排行程');
      }
    });
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    final amap = AmapService();
    final addr = await amap.reverseGeocode(lat, lng);
    if (mounted && addr != null && addr.isNotEmpty) {
      setState(() => _pickupAddr = addr);
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  Future<void> _onSendText(String text) async {
    setState(() {
      _messages.add(ChatMessage.user(text));
    });

    final api = ref.read(apiServiceProvider);
    final result = await api.post('/api/v1/passenger/ai/chat', data: {
      'text': text,
      'session_id': _sessionId,
    });

    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      final data = result.data!['data'] as Map<String, dynamic>?;
      final responseText = data?['response_text'] as String? ?? '收到您的消息';

      // Persist session_id for conversation context
      final serverSessionId = data?['session_id'] as String?;
      if (serverSessionId != null && serverSessionId.isNotEmpty) {
        _sessionId = serverSessionId;
      }

      setState(() {
        _messages.add(ChatMessage.assistant(responseText));
      });

      // Only navigate to order-confirm when intent is complete
      final intent = data?['intent'] as Map<String, dynamic>?;
      if (intent != null && intent['intent_type'] == 'ride_booking') {
        final missingFields =
            (intent['missing_fields'] as List<dynamic>?)?.cast<String>() ?? [];
        final pickup = intent['pickup'] as Map<String, dynamic>?;
        final dropoff = intent['dropoff'] as Map<String, dynamic>?;

        // Only proceed when all fields are complete
        if (missingFields.isEmpty &&
            pickup != null &&
            dropoff != null &&
            pickup['resolved'] == true &&
            dropoff['resolved'] == true) {
          final preview = data?['order_preview'] as Map<String, dynamic>?;
          if (context.mounted) {
            context.push('/order-confirm', extra: {
              'pickup': pickup,
              'dropoff': dropoff,
              'est_price': preview?['est_price'] ?? 0,
              'est_distance': preview?['est_distance'] ?? 0,
              'est_duration': preview?['est_duration'] ?? 0,
              'car_type': intent['car_type'] ?? 1,
              'session_id': _sessionId,
            });
          }
        }
      }
    } else {
      setState(() {
        _messages.add(ChatMessage.error('抱歉，AI 助手暂时不可用，请稍后再试'));
      });
    }
  }

  void _onQuickCommand(String text) => _onSendText(text);
  void _onStartRecording() => context.push('/ai-chat');
  void _onStopRecording() {}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('RideHermes', style: TextStyle(fontSize: 21))),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GreetingBar(),

                  // Destination search card
                  GestureDetector(
                    onTap: () => _openDestinationSearch(),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.search, color: theme.colorScheme.primary, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '你要去哪儿',
                                  style: TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _pickupAddr,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey[400], size: 28),
                        ],
                      ),
                    ),
                  ),

                  QuickCommands(onTap: _onQuickCommand),
                  const SizedBox(height: 16),
                  const PromoBanner(),
                  const SizedBox(height: 16),
                  // 计划出行入口
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlanTripScreen(),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.event_seat,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '计划出行',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '预约确定性出行，选择满意司机',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const ServiceGrid(),
                  const SizedBox(height: 16),
                  const WeatherCard(),
                  const SizedBox(height: 16),
                  const SafetyAssurance(),
                  const SizedBox(height: 16),
                  const RecentTrips(),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/ai-chat'),
                        icon: const Icon(Icons.chat, size: 24),
                        label: const Text('AI 智能助手', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),

                  if (_messages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) => ChatBubble(data: _messages[index]),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AIChatBar(
            onSend: _onSendText,
            onStartRecording: _onStartRecording,
            onStopRecording: _onStopRecording,
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage data;
  const ChatBubble({super.key, required this.data});

  Color _bgColor(BuildContext context) {
    if (data.type == ChatMessageType.error || data.type == ChatMessageType.fallback) {
      return Colors.orange[50]!;
    }
    return data.isUser ? Theme.of(context).colorScheme.primary : Colors.grey[100]!;
  }

  Color _textColor(BuildContext context) {
    if (data.type == ChatMessageType.error || data.type == ChatMessageType.fallback) {
      return Colors.orange[900]!;
    }
    return data.isUser ? Colors.white : Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bgColor(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: data.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!data.isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: data.type == ChatMessageType.error ||
                        data.type == ChatMessageType.fallback
                    ? Colors.orange
                    : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                data.type == ChatMessageType.error ||
                        data.type == ChatMessageType.fallback
                    ? Icons.error_outline
                    : Icons.smart_toy,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(data.isUser ? 16 : 4),
                  bottomRight: Radius.circular(data.isUser ? 4 : 16),
                ),
              ),
              child: Text(data.text, style: TextStyle(
                color: _textColor(context),
                fontSize: 17,
              )),
            ),
          ),
          if (data.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.blueGrey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person, size: 18, color: Colors.blueGrey),
            ),
          ],
        ],
      ),
    );
  }
}
