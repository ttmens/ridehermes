import 'package:ride_hermes_passenger/models/ai_chat.dart';

enum ChatMessageType { text, rideConfirm, error, fallback, transcribing }

class ChatMessage {
  final String text;
  final bool isUser;
  final ChatMessageType type;
  final RideIntent? intent;
  final OrderPreview? orderPreview;
  final bool isLoading;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.type = ChatMessageType.text,
    this.intent,
    this.orderPreview,
    this.isLoading = false,
  });

  factory ChatMessage.user(String text) => ChatMessage(
        text: text,
        isUser: true,
        type: ChatMessageType.text,
      );

  factory ChatMessage.assistant(String text) => ChatMessage(
        text: text,
        isUser: false,
        type: ChatMessageType.text,
      );

  factory ChatMessage.transcribing() => const ChatMessage(
        text: '识别中...',
        isUser: true,
        type: ChatMessageType.transcribing,
      );

  factory ChatMessage.rideConfirm({
    required String text,
    required RideIntent intent,
    OrderPreview? orderPreview,
  }) =>
      ChatMessage(
        text: text,
        isUser: false,
        type: ChatMessageType.rideConfirm,
        intent: intent,
        orderPreview: orderPreview,
      );

  factory ChatMessage.error(String text) => ChatMessage(
        text: text,
        isUser: false,
        type: ChatMessageType.error,
      );

  factory ChatMessage.fallback(String text) => ChatMessage(
        text: text,
        isUser: false,
        type: ChatMessageType.fallback,
      );

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    ChatMessageType? type,
    RideIntent? intent,
    OrderPreview? orderPreview,
    bool? isLoading,
    bool clearIntent = false,
    bool clearOrderPreview = false,
  }) =>
      ChatMessage(
        text: text ?? this.text,
        isUser: isUser ?? this.isUser,
        type: type ?? this.type,
        intent: clearIntent ? null : (intent ?? this.intent),
        orderPreview:
            clearOrderPreview ? null : (orderPreview ?? this.orderPreview),
        isLoading: isLoading ?? this.isLoading,
      );
}
