import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:record/record.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _lastError;

  Future<bool> hasPermission() => _recorder.hasPermission();

  String? get lastError => _lastError;
  bool get isRecording => _isRecording;

  Future<bool> startRecording() async {
    _lastError = null;
    try {
      final hasPerm = await _recorder.hasPermission();
      if (!hasPerm) {
        _lastError = '麦克风权限未授予';
        return false;
      }

      final dir = Directory('${Directory.systemTemp.path}/ride_audio');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 256000,
        ),
        path: '${dir.path}/ride_audio_${DateTime.now().millisecondsSinceEpoch}.wav',
      );
      _isRecording = true;
      return true;
    } catch (e) {
      _lastError = '录音启动失败: $e';
      _isRecording = false;
      return false;
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) {
            return base64Encode(bytes);
          }
        }
      }
      _lastError = '录音文件为空';
      return null;
    } catch (e) {
      _lastError = '录音停止失败: $e';
      _isRecording = false;
      return null;
    }
  }

  void dispose() => _recorder.dispose();
}
