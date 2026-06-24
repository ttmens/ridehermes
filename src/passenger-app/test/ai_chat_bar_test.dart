import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_hermes_passenger/features/home/widgets/ai_chat_bar.dart';

void main() {
  testWidgets('Mic tap calls onStartRecording when not recording', (tester) async {
    bool started = false;
    bool stopped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AIChatBar(
            onSend: (_) {},
            onStartRecording: () => started = true,
            onStopRecording: () => stopped = true,
            isRecording: false,
          ),
        ),
      ),
    );

    final micIcon = find.byIcon(Icons.mic_none);
    expect(micIcon, findsOneWidget);

    await tester.tap(micIcon);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(started, isTrue, reason: 'onStartRecording should be called on mic tap');
    expect(stopped, isFalse);
  });

  testWidgets('Mic tap calls onStopRecording when recording', (tester) async {
    bool started = false;
    bool stopped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AIChatBar(
            onSend: (_) {},
            onStartRecording: () => started = true,
            onStopRecording: () => stopped = true,
            isRecording: true,
          ),
        ),
      ),
    );

    final micIcon = find.byIcon(Icons.mic);
    expect(micIcon, findsOneWidget);

    await tester.tap(micIcon);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(stopped, isTrue, reason: 'onStopRecording should be called when recording');
    expect(started, isFalse);
  });

  testWidgets('onTapMic takes priority over onStartRecording', (tester) async {
    int onTapMicCount = 0;
    bool onStartCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AIChatBar(
            onSend: (_) {},
            onStartRecording: () => onStartCalled = true,
            onStopRecording: () {},
            onTapMic: () => onTapMicCount++,
            isRecording: false,
          ),
        ),
      ),
    );

    final micIcon = find.byIcon(Icons.mic_none);
    await tester.tap(micIcon);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(onTapMicCount, 1, reason: 'onTapMic should be called');
    expect(onStartCalled, isFalse, reason: 'onStartRecording should NOT be called when onTapMic is set');
  });

  testWidgets('Long press calls onStartRecording', (tester) async {
    bool started = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AIChatBar(
            onSend: (_) {},
            onStartRecording: () => started = true,
            onStopRecording: () {},
            isRecording: false,
          ),
        ),
      ),
    );

    final micIcon = find.byIcon(Icons.mic_none);
    final gesture = await tester.startGesture(tester.getCenter(micIcon));
    // Hold for long press duration
    await tester.pump(const Duration(milliseconds: 600));

    expect(started, isTrue, reason: 'onStartRecording should be called on long press');

    await gesture.up();
  });
}
