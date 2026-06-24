import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:ride_hermes_passenger/models/chat_message.dart';
import 'package:ride_hermes_passenger/models/ai_chat.dart';
import 'package:ride_hermes_passenger/services/api_service.dart';
import 'package:ride_hermes_passenger/providers/auth_provider.dart';

class AIChatState {
  final List<ChatMessage> messages;
  final String sessionId;
  final bool isLoading;

  const AIChatState({
    this.messages = const [],
    this.sessionId = '',
    this.isLoading = false,
  });

  AIChatState copyWith({
    List<ChatMessage>? messages,
    String? sessionId,
    bool? isLoading,
  }) =>
      AIChatState(
        messages: messages ?? this.messages,
        sessionId: sessionId ?? this.sessionId,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AIChatNotifier extends StateNotifier<AIChatState> {
  final ApiService _api;

  AIChatNotifier(this._api)
      : super(AIChatState(sessionId: const Uuid().v4()));

  /// Send a text message to the AI service.
  Future<Map<String, dynamic>?> sendText(String text) async {
    if (text.isEmpty || state.isLoading) return null;

    state = state.copyWith(
      messages: [...state.messages, ChatMessage.user(text)],
      isLoading: true,
    );

    return _callAI(text: text);
  }

  /// Send an audio recording (Base64 WAV) to the AI service.
  Future<Map<String, dynamic>?> sendAudio(String audioBase64) async {
    if (state.isLoading) return null;

    final transcribingIdx = state.messages.length;
    state = state.copyWith(
      messages: [...state.messages, ChatMessage.transcribing()],
      isLoading: true,
    );

    return _callAI(
      audioBase64: audioBase64,
      transcribingIdx: transcribingIdx,
    );
  }

  Future<Map<String, dynamic>?> _callAI({
    String? text,
    String? audioBase64,
    int transcribingIdx = -1,
  }) async {
    final body = <String, dynamic>{
      'session_id': state.sessionId,
    };
    if (audioBase64 != null) {
      body['audio_base64'] = audioBase64;
    } else if (text != null) {
      body['text'] = text;
    }

    final result = await _api.post('/api/v1/passenger/ai/chat', data: body);

    if (!result.isSuccess || result.data == null) {
      _handleError(text, audioBase64, transcribingIdx);
      return null;
    }

    final data = result.data!['data'] as Map<String, dynamic>?;
    if (data == null) {
      _handleError(text, audioBase64, transcribingIdx);
      return null;
    }

    final responseText = data['response_text'] as String? ?? '';
    final asrText = data['asr_text'] as String?;
    final serverSessionId = data['session_id'] as String?;
    final intentJson = data['intent'] as Map<String, dynamic>?;
    final previewJson = data['order_preview'] as Map<String, dynamic>?;

    RideIntent? rideIntent;
    OrderPreview? orderPreview;
    if (intentJson != null) {
      rideIntent = RideIntent.fromJson(intentJson);
    }
    if (previewJson != null) {
      orderPreview = OrderPreview.fromJson(previewJson);
    }

    final messages = List<ChatMessage>.from(state.messages);

    // For voice: update the transcribing placeholder with the recognized text
    if (transcribingIdx >= 0 && transcribingIdx < messages.length) {
      final userText = (asrText != null && asrText.isNotEmpty) ? asrText : '(语音消息)';
      messages[transcribingIdx] = ChatMessage.user(userText);
    }

    // Add AI response text
    if (responseText.isNotEmpty) {
      messages.add(ChatMessage.assistant(responseText));
    }

    // If intent is complete (no missing fields), add ride confirm card
    if (rideIntent != null &&
        rideIntent.intentType == 'ride_booking' &&
        rideIntent.missingFields.isEmpty &&
        rideIntent.pickup != null &&
        rideIntent.dropoff != null) {
      messages.add(ChatMessage.rideConfirm(
        text: '确认您的行程信息',
        intent: rideIntent,
        orderPreview: orderPreview,
      ));
    }

    state = state.copyWith(
      messages: messages,
      sessionId: serverSessionId?.isNotEmpty == true
          ? serverSessionId!
          : state.sessionId,
      isLoading: false,
    );

    return data;
  }

  void _handleError(String? text, String? audioBase64, int transcribingIdx) {
    final messages = List<ChatMessage>.from(state.messages);

    if (transcribingIdx >= 0 && transcribingIdx < messages.length) {
      messages[transcribingIdx] = ChatMessage.user(text ?? '(语音消息)');
    }

    messages.add(ChatMessage.error('抱歉，AI 助手暂时不可用，您可以尝试安排行程'));

    state = state.copyWith(messages: messages, isLoading: false);
  }

  /// Replace the last ride confirm message with a text message after order created.
  void replaceLastRideConfirm(String text) {
    final messages = List<ChatMessage>.from(state.messages);
    if (messages.isNotEmpty && messages.last.type == ChatMessageType.rideConfirm) {
      messages[messages.length - 1] = ChatMessage.assistant(text);
    }
    state = state.copyWith(messages: messages);
  }

  /// Reset the conversation with a new session.
  void reset() {
    state = AIChatState(sessionId: const Uuid().v4());
  }
}

final aiChatProvider =
    StateNotifierProvider<AIChatNotifier, AIChatState>((ref) {
  return AIChatNotifier(ref.watch(apiServiceProvider));
});
