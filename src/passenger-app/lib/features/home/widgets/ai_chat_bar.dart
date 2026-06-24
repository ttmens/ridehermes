import 'package:flutter/material.dart';

class AIChatBar extends StatefulWidget {
  final Function(String) onSend;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback? onTapMic;
  final bool isRecording;

  const AIChatBar({
    super.key,
    required this.onSend,
    required this.onStartRecording,
    required this.onStopRecording,
    this.onTapMic,
    this.isRecording = false,
  });

  @override
  State<AIChatBar> createState() => _AIChatBarState();
}

class _AIChatBarState extends State<AIChatBar> {
  final _controller = TextEditingController();
  bool _longPressing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startRecording() {
    debugPrint('[AIChatBar] _startRecording called');
    (widget.onTapMic ?? widget.onStartRecording)();
  }

  void _stopRecording() {
    debugPrint('[AIChatBar] _stopRecording called');
    widget.onStopRecording();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final micColor =
        widget.isRecording ? Colors.red : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText:
                    widget.isRecording ? '正在录音...' : '说一声，马上出发...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              enabled: !widget.isRecording,
              onSubmitted: (text) {
                if (text.isNotEmpty) {
                  widget.onSend(text);
                  _controller.clear();
                }
              },
            ),
          ),
          Material(
            color: micColor.withOpacity(
                widget.isRecording ? 1.0 : 0.1),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              splashColor: micColor.withOpacity(0.3),
              highlightColor: micColor.withOpacity(0.15),
              onTap: () {
                debugPrint('[AIChatBar] onTap, isRecording=${widget.isRecording}');
                if (widget.isRecording) {
                  _stopRecording();
                } else {
                  _startRecording();
                }
              },
              onLongPress: () {
                debugPrint('[AIChatBar] onLongPress');
                _longPressing = true;
                widget.onStartRecording();
              },
              onTapUp: (_) {
                debugPrint('[AIChatBar] onTapUp, longPressing=$_longPressing');
                if (_longPressing) {
                  _longPressing = false;
                  if (widget.isRecording) {
                    widget.onStopRecording();
                  }
                }
              },
              onTapCancel: () {
                debugPrint('[AIChatBar] onTapCancel');
                if (_longPressing) {
                  _longPressing = false;
                  if (widget.isRecording) {
                    widget.onStopRecording();
                  }
                }
              },
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Icon(
                  widget.isRecording ? Icons.mic : Icons.mic_none,
                  color: widget.isRecording ? Colors.white : micColor,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            color: theme.colorScheme.primary,
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                widget.onSend(_controller.text);
                _controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
