import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:altune/services/player_manager.dart';
import 'package:altune/interfaces/queue_repeat_mode.dart';
import 'package:altune/screens/player_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerScreen', () {
    Widget buildPlayerScreen({
      required PlayerManager playerManager,
      VoidCallback? onOpenQueue,
      VoidCallback? onSkipPrevious,
      VoidCallback? onSkipNext,
    }) {
      return MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: PlayerScreen(
              playerManager: playerManager,
              onOpenQueue: onOpenQueue ?? () {},
              onSkipPrevious: onSkipPrevious ?? () {},
              onSkipNext: onSkipNext ?? () {},
            ),
          ),
        ),
      );
    }

    testWidgets('calls onOpenQueue when queue button is tapped', (
      tester,
    ) async {
      final playerManager = PlayerManager();
      bool opened = false;
      await tester.pumpWidget(
        buildPlayerScreen(
          playerManager: playerManager,
          onOpenQueue: () => opened = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.queue_music));
      expect(opened, isTrue);

      playerManager.dispose();
    });

    testWidgets('calls onSkipPrevious when skip previous button is tapped', (
      tester,
    ) async {
      final playerManager = PlayerManager();
      bool skipped = false;
      await tester.pumpWidget(
        buildPlayerScreen(
          playerManager: playerManager,
          onSkipPrevious: () => skipped = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.skip_previous));
      expect(skipped, isTrue);

      playerManager.dispose();
    });

    testWidgets('calls onSkipNext when skip next button is tapped', (
      tester,
    ) async {
      final playerManager = PlayerManager();
      bool skipped = false;
      await tester.pumpWidget(
        buildPlayerScreen(
          playerManager: playerManager,
          onSkipNext: () => skipped = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.skip_next));
      expect(skipped, isTrue);

      playerManager.dispose();
    });

    testWidgets('toggles shuffle when shuffle button is tapped', (
      tester,
    ) async {
      final playerManager = PlayerManager();
      await tester.pumpWidget(buildPlayerScreen(playerManager: playerManager));

      expect(playerManager.isShuffled, isFalse);
      await tester.tap(find.byIcon(Icons.shuffle_outlined));
      expect(playerManager.isShuffled, isTrue);

      playerManager.dispose();
    });

    testWidgets('cycles repeat mode when repeat button is tapped', (
      tester,
    ) async {
      final playerManager = PlayerManager();
      await tester.pumpWidget(buildPlayerScreen(playerManager: playerManager));

      expect(playerManager.repeatMode, equals(QueueRepeatMode.off));
      await tester.tap(find.byIcon(Icons.repeat));
      await tester.pump();
      expect(playerManager.repeatMode, isNot(equals(0)));

      playerManager.dispose();
    });
  });
}
