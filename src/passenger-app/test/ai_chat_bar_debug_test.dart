import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_hermes_passenger/features/home/widgets/ai_chat_bar.dart';

void main() {
  testWidgets('Mic tap routes to /ai-chat on HomeScreen pattern', (tester) async {
    int callCount = 0;
    // This simulates what HomeScreen does: _onStartRecording = () => context.push('/ai-chat')
    void navigateToAiChat() {
      callCount++;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AIChatBar(
            onSend: (_) {},
            onStartRecording: navigateToAiChat,
            onStopRecording: () {},
            isRecording: false,
          ),
        ),
      ),
    );

    // Tap the mic icon
    final micIconFinder = find.byIcon(Icons.mic_none);
    expect(micIconFinder, findsOneWidget);

    await tester.tap(micIconFinder);
    // Pump to allow microtask queue to process
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(callCount, 1, reason: 'HomeScreen-style VoidCallback should be called on mic tap');
  });

  testWidgets('Mic tap calls async callback on AIChatScreen pattern', (tester) async {
    int callCount = 0;
    // This simulates what AIChatScreen does - Future<void> callback
    void startRecording() {
      // This async work happens but as VoidCallback it won't be awaited
      Future.microtask(() {
        callCount++;
      });
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AIChatBar(
            onSend: (_) {},
            onStartRecording: startRecording,
            onStopRecording: () {},
            isRecording: false,
          ),
        ),
      ),
    );

    final micIconFinder = find.byIcon(Icons.mic_none);
    expect(micIconFinder, findsOneWidget);

    await tester.tap(micIconFinder);
    await tester.pump();
    // Process all microtasks
    await tester.pump(const Duration(milliseconds: 100));

    expect(callCount, 1, reason: 'AIChatScreen-style callback should be called on mic tap');
  });

  testWidgets('Mic tap on home screen triggers navigation via onTapMic', (tester) async {
    int callCount = 0;
    void customOnTap() {
      callCount++;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AIChatBar(
            onSend: (_) {},
            onStartRecording: () => fail('should not call onStartRecording when onTapMic is provided'),
            onStopRecording: () {},
            onTapMic: customOnTap,
            isRecording: false,
          ),
        ),
      ),
    );

    final micIconFinder = find.byIcon(Icons.mic_none);
    await tester.tap(micIconFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(callCount, 1, reason: 'onTapMic should take priority over onStartRecording');
  });
}
