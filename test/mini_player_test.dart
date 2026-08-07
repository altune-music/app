import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:altune/services/player_manager.dart';
import 'package:altune/models/song.dart';
import 'package:altune/widgets/mini_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {});

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

    testWidgets('shows nothing when no song is active', (tester) async {
      final playerManager = PlayerManager();
      await tester.pumpWidget(buildMiniPlayer(playerManager: playerManager));

      expect(find.byType(SizedBox), findsWidgets);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.skip_next), findsNothing);

      playerManager.dispose();
    });

    testWidgets('shows song info when currentPlaying is set', (tester) async {
      final playerManager = PlayerManager();
      final song = Song(
        id: '1',
        name: 'Test Song',
        primaryArtists: 'Test Artist',
      );
      playerManager.updateCurrentPlaying(song);

      await tester.pumpWidget(buildMiniPlayer(playerManager: playerManager));

      expect(find.text('Test Song'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);

      playerManager.dispose();
    });

    testWidgets('updates when currentPlaying changes', (tester) async {
      final playerManager = PlayerManager();
      final song1 = Song(
        id: '1',
        name: 'Song One',
        primaryArtists: 'Artist One',
      );
      playerManager.updateCurrentPlaying(song1);

      await tester.pumpWidget(buildMiniPlayer(playerManager: playerManager));
      expect(find.text('Song One'), findsOneWidget);

      final song2 = Song(
        id: '2',
        name: 'Song Two',
        primaryArtists: 'Artist Two',
      );
      playerManager.updateCurrentPlaying(song2);
      await tester.pump();

      expect(find.text('Song Two'), findsOneWidget);
      expect(find.text('Song One'), findsNothing);

      playerManager.dispose();
    });

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

    testWidgets('shows pause icon when playing', (tester) async {
      final playerManager = PlayerManager();
      final song = Song(
        id: '1',
        name: 'Test Song',
        primaryArtists: 'Test Artist',
      );
      playerManager.updateCurrentPlaying(song);

      await tester.pumpWidget(buildMiniPlayer(playerManager: playerManager));

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);

      playerManager.dispose();
    });

    testWidgets('shows last played song when currentPlaying is cleared', (
      tester,
    ) async {
      final playerManager = PlayerManager();
      final song = Song(
        id: '1',
        name: 'Last Song',
        primaryArtists: 'Last Artist',
      );
      playerManager.updateCurrentPlaying(song);
      playerManager.setQueue(
        [],
        songId: null,
      ); // clears currentPlaying, keeps lastPlayedSong

      await tester.pumpWidget(buildMiniPlayer(playerManager: playerManager));

      expect(find.text('Last Song'), findsOneWidget);
      expect(find.text('Last Artist'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      playerManager.dispose();
    });
  });
}
