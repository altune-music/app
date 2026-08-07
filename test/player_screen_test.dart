import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:altune/services/player_manager.dart';
import 'package:altune/models/song.dart';
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

    testWidgets('shows close and queue icons', (tester) async {
      final playerManager = PlayerManager();
      await tester.pumpWidget(buildPlayerScreen(playerManager: playerManager));

      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.byIcon(Icons.queue_music), findsOneWidget);

      playerManager.dispose();
    });

    testWidgets('shows song title and artist when playing', (tester) async {
      final playerManager = PlayerManager();
      final song = Song(
        id: '1',
        name: 'Test Song',
        primaryArtists: 'Test Artist',
      );
      playerManager.updateCurrentPlaying(song);

      await tester.pumpWidget(buildPlayerScreen(playerManager: playerManager));

      expect(find.text('Test Song'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);

      playerManager.dispose();
    });

    testWidgets('shows playback control buttons', (tester) async {
      final playerManager = PlayerManager();
      await tester.pumpWidget(buildPlayerScreen(playerManager: playerManager));

      expect(find.byIcon(Icons.shuffle_outlined), findsOneWidget);
      expect(find.byIcon(Icons.skip_previous), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsOneWidget);
      expect(find.byIcon(Icons.repeat), findsOneWidget);

      playerManager.dispose();
    });

    testWidgets('shows position and duration text', (tester) async {
      final playerManager = PlayerManager();
      await tester.pumpWidget(buildPlayerScreen(playerManager: playerManager));

      expect(find.text('00:00'), findsNWidgets(2));

      playerManager.dispose();
    });

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

    testWidgets('shows play button', (tester) async {
      final playerManager = PlayerManager();
      await tester.pumpWidget(buildPlayerScreen(playerManager: playerManager));

      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);

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

      await tester.tap(find.byIcon(Icons.repeat));
      await tester.pump();
      // After tap, verify repeat mode changed
      expect(playerManager.repeatMode, isNot(0));

      playerManager.dispose();
    });

    testWidgets('shows seek bar slider', (tester) async {
      final playerManager = PlayerManager();
      await tester.pumpWidget(buildPlayerScreen(playerManager: playerManager));

      expect(find.byType(Slider), findsOneWidget);

      playerManager.dispose();
    });

    testWidgets('shows shuffle filled icon when shuffled', (tester) async {
      final playerManager = PlayerManager();
      await tester.pumpWidget(buildPlayerScreen(playerManager: playerManager));

      playerManager.toggleShuffle();
      await tester.pump();

      expect(find.byIcon(Icons.shuffle), findsOneWidget);
      expect(find.byIcon(Icons.shuffle_outlined), findsNothing);

      playerManager.dispose();
    });

    testWidgets('shows repeat one icon in repeat one mode', (tester) async {
      final playerManager = PlayerManager();
      await tester.pumpWidget(buildPlayerScreen(playerManager: playerManager));

      playerManager.cycleRepeatMode();
      playerManager.cycleRepeatMode();
      await tester.pump();

      expect(find.byIcon(Icons.repeat_one), findsOneWidget);

      playerManager.dispose();
    });
  });
}
