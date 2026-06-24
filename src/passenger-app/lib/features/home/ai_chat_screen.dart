import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:ride_hermes_passenger/models/chat_message.dart';
import 'package:ride_hermes_passenger/providers/ai_chat_provider.dart';
import 'package:ride_hermes_passenger/features/home/widgets/ai_chat_bar.dart';
import 'package:ride_hermes_passenger/features/home/widgets/ride_confirm_card.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _scrollController = ScrollController();
  final _recorder = AudioRecorder();

  bool _isRecording = false;
  String? _recordingPath;

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onSendText(String text) async {
    final notifier = ref.read(aiChatProvider.notifier);
    await notifier.sendText(text);
    _scrollToBottom();
  }

  Future<void> _onStartRecording() async {
    debugPrint('[AIChatScreen] _onStartRecording called');
    try {
      final status = await Permission.microphone.request();
      debugPrint('[AIChatScreen] microphone permission: $status');
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请授权麦克风权限以使用语音功能')),
          );
        }
        return;
      }
    } catch (e) {
      debugPrint('[AIChatScreen] permission error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('权限检查失败: $e')),
        );
      }
      return;
    }

    if (await _recorder.isRecording()) {
      debugPrint('[AIChatScreen] already recording, ignoring');
      return;
    }

    setState(() => _isRecording = true);

    try {
      _recordingPath =
          '${Directory.systemTemp.path}/ride_voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      debugPrint('[AIChatScreen] starting recorder, path=$_recordingPath');
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _recordingPath!,
      );
      debugPrint('[AIChatScreen] recorder started successfully');
    } catch (e) {
      debugPrint('[AIChatScreen] recorder start error: $e');
      setState(() => _isRecording = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('录音启动失败: $e')),
        );
      }
    }
  }

  Future<void> _onStopRecording() async {
    debugPrint('[AIChatScreen] _onStopRecording called, isRecording=$_isRecording');
    if (!_isRecording) return;

    setState(() => _isRecording = false);

    String? filePath;
    try {
      filePath = await _recorder.stop();
      debugPrint('[AIChatScreen] recorder stopped, path=$filePath');
    } catch (e) {
      debugPrint('[AIChatScreen] recorder stop error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('录音停止失败: $e')),
        );
      }
      return;
    }

    if (filePath == null) {
      debugPrint('[AIChatScreen] no file path from recorder');
      return;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint('[AIChatScreen] audio file does not exist: $filePath');
      return;
    }

    final audioBytes = await file.readAsBytes();
    debugPrint('[AIChatScreen] audio bytes: ${audioBytes.length}');
    final audioBase64 = base64Encode(audioBytes);
    await file.delete();

    final notifier = ref.read(aiChatProvider.notifier);
    await notifier.sendAudio(audioBase64);
    _scrollToBottom();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatProvider);
    final messages = state.messages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 对话'),
      ),
      body: Column(
        children: [
          if (messages.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.smart_toy, size: 64, color: Colors.teal),
                    SizedBox(height: 16),
                    Text('告诉我你想去哪里',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    SizedBox(height: 8),
                    Text('例如：我要从望京SOHO去中关村软件园',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  if (msg.type == ChatMessageType.rideConfirm &&
                      msg.intent != null) {
                    return RideConfirmCard(
                      intent: msg.intent!,
                      preview: msg.orderPreview,
                    );
                  }
                  return _ChatBubble(data: msg);
                },
              ),
            ),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          AIChatBar(
            onSend: _onSendText,
            onStartRecording: _onStartRecording,
            onStopRecording: _onStopRecording,
            isRecording: _isRecording,
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage data;
  const _ChatBubble({required this.data});

  Color _bubbleColor(BuildContext context) {
    switch (data.type) {
      case ChatMessageType.error:
      case ChatMessageType.fallback:
        return Colors.orange[50]!;
      default:
        return data.isUser
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[100]!;
    }
  }

  Color _textColor(BuildContext context) {
    switch (data.type) {
      case ChatMessageType.error:
      case ChatMessageType.fallback:
        return Colors.orange[900]!;
      default:
        return data.isUser ? Colors.white : Colors.black87;
    }
  }

  IconData? _leadingIcon() {
    switch (data.type) {
      case ChatMessageType.error:
      case ChatMessageType.fallback:
        return Icons.error_outline;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final leadingIcon = _leadingIcon();
    final bubbleColor = _bubbleColor(context);
    final textColor = _textColor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            data.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!data.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: data.type == ChatMessageType.error ||
                        data.type == ChatMessageType.fallback
                    ? Colors.orange
                    : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                leadingIcon ?? Icons.smart_toy,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(data.isUser ? 18 : 4),
                  bottomRight: Radius.circular(data.isUser ? 4 : 18),
                ),
              ),
              child: data.type == ChatMessageType.transcribing
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(data.text,
                            style: TextStyle(
                                color: textColor, fontSize: 14)),
                        const SizedBox(width: 8),
                        const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    )
                  : Text(
                      data.text,
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
            ),
          ),
          if (data.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
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
