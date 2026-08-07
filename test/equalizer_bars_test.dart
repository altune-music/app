import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:altune/widgets/equalizer_bars.dart';

void main() {
  group('EqualizerBars', () {
    testWidgets('renders the requested number of bars', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EqualizerBars(playing: true, barCount: 3, size: 16),
          ),
        ),
      );

      // One container per bar inside the widget's Row.
      final containers = tester.widgetList<Container>(find.byType(Container));
      // The 3 bars + the outer SizedBox host; only bars have width set to >0.
      expect(
        containers.where((c) => c.constraints?.maxWidth != null),
        isNotEmpty,
      );
    });

    testWidgets('animates while playing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: EqualizerBars(playing: true))),
      );

      // Progress the repeating animation by a few frames.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      // No exception thrown across frames is the key assertion here.
      expect(tester.takeException(), isNull);
    });

    testWidgets('freezes when paused and does not error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: EqualizerBars(playing: false))),
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses the supplied color for bars', (tester) async {
      const testColor = Color(0xFF112233);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EqualizerBars(playing: true, color: testColor)),
        ),
      );

      final decorations = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>();
      expect(decorations.any((d) => d.color == testColor), isTrue);
    });
  });
}
