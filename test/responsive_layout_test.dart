import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:altune/services/player_manager.dart';
import 'package:altune/models/song.dart';
import 'package:altune/screens/player_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {});

  group('Edge-to-edge layout', () {
    group('PlayerScreen', () {
      testWidgets('PlayerScreen is wrapped in SafeArea', (tester) async {
        final playerManager = PlayerManager();
        addTearDown(() => playerManager.dispose());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlayerScreen(
                playerManager: playerManager,
                onOpenQueue: () {},
                onSkipPrevious: () {},
                onSkipNext: () {},
              ),
            ),
          ),
        );

        expect(find.byType(SafeArea), findsOneWidget);
      });

      testWidgets('SafeArea defaults to bottom and top insets', (tester) async {
        final playerManager = PlayerManager();
        addTearDown(() => playerManager.dispose());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlayerScreen(
                playerManager: playerManager,
                onOpenQueue: () {},
                onSkipPrevious: () {},
                onSkipNext: () {},
              ),
            ),
          ),
        );

        final safeArea = tester.widget<SafeArea>(find.byType(SafeArea));
        expect(safeArea.bottom, isTrue);
        expect(safeArea.top, isTrue);
      });

      testWidgets('PlayerScreen renders at tablet size', (tester) async {
        final playerManager = PlayerManager();
        addTearDown(() => playerManager.dispose());
        final song = Song(id: '1', name: 'Song', primaryArtists: 'Artist');
        playerManager.updateCurrentPlaying(song);

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(1080, 1920),
                padding: EdgeInsets.zero,
                viewPadding: EdgeInsets.zero,
              ),
              child: Scaffold(
                body: PlayerScreen(
                  playerManager: playerManager,
                  onOpenQueue: () {},
                  onSkipPrevious: () {},
                  onSkipNext: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('Song'), findsOneWidget);
        expect(find.text('Artist'), findsOneWidget);
        expect(find.byType(SafeArea), findsOneWidget);
      });
    });
  });
}
