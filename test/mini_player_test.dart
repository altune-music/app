import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:altune/services/player_manager.dart';
import 'package:altune/models/song.dart';
import 'package:altune/widgets/mini_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MiniPlayer', () {
    Widget buildMiniPlayer({
      required PlayerManager playerManager,
      VoidCallback? onPlayPause,
      VoidCallback? onSkipNext,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: MiniPlayer(
            playerManager: playerManager,
            onPlayPause: onPlayPause ?? () {},
            onSkipNext: onSkipNext ?? () {},
            onTap: onTap ?? () {},
          ),
        ),
      );
    }

    testWidgets('calls onPlayPause when play/pause button is tapped', (
      tester,
    ) async {
      final playerManager = PlayerManager();
      final song = Song(
        id: '1',
        name: 'Test Song',
        primaryArtists: 'Test Artist',
      );
      playerManager.updateCurrentPlaying(song);

      bool toggled = false;
      await tester.pumpWidget(
        buildMiniPlayer(
          playerManager: playerManager,
          onPlayPause: () => toggled = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.play_arrow));
      expect(toggled, isTrue);

      playerManager.dispose();
    });

    testWidgets('calls onSkipNext when skip next button is tapped', (
      tester,
    ) async {
      final playerManager = PlayerManager();
      final song = Song(
        id: '1',
        name: 'Test Song',
        primaryArtists: 'Test Artist',
      );
      playerManager.updateCurrentPlaying(song);

      bool skipped = false;
      await tester.pumpWidget(
        buildMiniPlayer(
          playerManager: playerManager,
          onSkipNext: () => skipped = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.skip_next));
      expect(skipped, isTrue);

      playerManager.dispose();
    });

    testWidgets('calls onTap when mini player is tapped', (tester) async {
      final playerManager = PlayerManager();
      final song = Song(
        id: '1',
        name: 'Test Song',
        primaryArtists: 'Test Artist',
      );
      playerManager.updateCurrentPlaying(song);

      bool tapped = false;
      await tester.pumpWidget(
        buildMiniPlayer(
          playerManager: playerManager,
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.text('Test Song'));
      expect(tapped, isTrue);

      playerManager.dispose();
    });
  });
}
