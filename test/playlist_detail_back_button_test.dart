import 'package:flutter/material.dart';
import 'package:altune/services/state_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiosaavn/jiosaavn.dart';
import 'package:altune/models/saved_playlist.dart';
import 'package:altune/controllers/main_controller.dart';
import 'package:altune/services/player_manager.dart';
import 'package:altune/screens/playlist_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {});

  // Simulates the large-screen layout where PlaylistDetailScreen lives inside
  // the root route's IndexedStack behind a PopScope(canPop: false). A direct
  // Navigator.pop() would remove the root route and blank the screen.
  testWidgets('back button on blocked PopScope does not blank the screen', (
    tester,
  ) async {
    final controller = MainController(
      stateService: StateService(),
      client: JioSaavnClient(),
      playerManager: PlayerManager(),
      localSongs: [],
    );
    addTearDown(() => controller.playerManager.dispose());

    final recent = SavedPlaylist(
      id: 'recent_songs',
      name: 'Recent Songs',
      songIds: [],
      isSystem: true,
    );

    bool backHandled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => PopScope(
            // Mirrors the layout's canPop: _screen == library (blocked here).
            canPop: false,
            onPopInvokedWithResult: (didPop, _) => backHandled = true,
            child: Scaffold(
              body: PlaylistDetailScreen(
                controller: controller,
                playlist: recent,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    // Screen must stay mounted — no blank screen.
    expect(find.byType(PlaylistDetailScreen), findsOneWidget);
    // maybePop consulted the PopScope instead of force-popping the route.
    expect(backHandled, isTrue);
  });

  // Mobile: playlist detail is a pushed route, so back pops normally.
  testWidgets('back button pops a pushed route', (tester) async {
    final controller = MainController(
      stateService: StateService(),
      client: JioSaavnClient(),
      playerManager: PlayerManager(),
      localSongs: [],
    );
    addTearDown(() => controller.playerManager.dispose());

    final recent = SavedPlaylist(
      id: 'recent_songs',
      name: 'Recent Songs',
      songIds: [],
      isSystem: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlaylistDetailScreen(
                      controller: controller,
                      playlist: recent,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaylistDetailScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    // Pushed route popped back to home.
    expect(find.byType(PlaylistDetailScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
