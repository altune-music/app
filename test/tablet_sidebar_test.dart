import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dpad/dpad.dart';
import 'package:altune/services/player_manager.dart';
import 'package:altune/models/song.dart';
import 'package:altune/widgets/tablet_sidebar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {});

  group('TabletSidebar', () {
    Widget buildSidebar({
      int selectedIndex = 0,
      required ValueChanged<int> onItemSelected,
      PlayerManager? playerManager,
    }) {
      final pm = playerManager ?? PlayerManager();
      return MaterialApp(
        home: Scaffold(
          body: TabletSidebar(
            selectedIndex: selectedIndex,
            onItemSelected: onItemSelected,
            playerManager: pm,
          ),
        ),
      );
    }

    testWidgets('tapping Library triggers onItemSelected with 0', (
      tester,
    ) async {
      final playerManager = PlayerManager();
      int? selected;
      await tester.pumpWidget(
        buildSidebar(
          playerManager: playerManager,
          onItemSelected: (index) => selected = index,
        ),
      );

      await tester.tap(find.byIcon(Icons.library_music));
      expect(selected, equals(0));

      playerManager.dispose();
    });

    testWidgets('tapping Search triggers onItemSelected with 1', (
      tester,
    ) async {
      final playerManager = PlayerManager();
      int? selected;
      await tester.pumpWidget(
        buildSidebar(
          playerManager: playerManager,
          onItemSelected: (index) => selected = index,
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      expect(selected, equals(1));

      playerManager.dispose();
    });

    testWidgets('shows Library as selected when selectedIndex is 0', (
      tester,
    ) async {
      final playerManager = PlayerManager();
      await tester.pumpWidget(
        buildSidebar(
          playerManager: playerManager,
          selectedIndex: 0,
          onItemSelected: (_) {},
        ),
      );

      final cs = Theme.of(
        tester.element(find.byIcon(Icons.library_music)),
      ).colorScheme;
      final libraryButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.library_music),
          matching: find.byType(IconButton),
        ),
      );
      expect(libraryButton.color, cs.primary);

      final searchButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.search),
          matching: find.byType(IconButton),
        ),
      );
      expect(searchButton.color, cs.onSurfaceVariant);

      playerManager.dispose();
    });

    testWidgets('shows Search as selected when selectedIndex is 1', (
      tester,
    ) async {
      final playerManager = PlayerManager();
      await tester.pumpWidget(
        buildSidebar(
          playerManager: playerManager,
          selectedIndex: 1,
          onItemSelected: (_) {},
        ),
      );

      final cs = Theme.of(
        tester.element(find.byIcon(Icons.library_music)),
      ).colorScheme;
      final libraryButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.library_music),
          matching: find.byType(IconButton),
        ),
      );
      expect(libraryButton.color, cs.onSurfaceVariant);

      final searchButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.search),
          matching: find.byType(IconButton),
        ),
      );
      expect(searchButton.color, cs.primary);

      playerManager.dispose();
    });

    testWidgets('tapping Settings triggers onItemSelected with 2', (
      tester,
    ) async {
      final playerManager = PlayerManager();
      int? selected;
      await tester.pumpWidget(
        buildSidebar(
          playerManager: playerManager,
          onItemSelected: (index) => selected = index,
        ),
      );

      await tester.tap(find.byIcon(Icons.settings));
      expect(selected, equals(2));

      playerManager.dispose();
    });

    testWidgets('shows Settings as selected when selectedIndex is 2', (
      tester,
    ) async {
      final playerManager = PlayerManager();
      await tester.pumpWidget(
        buildSidebar(
          playerManager: playerManager,
          selectedIndex: 2,
          onItemSelected: (_) {},
        ),
      );

      final cs = Theme.of(
        tester.element(find.byIcon(Icons.settings)),
      ).colorScheme;
      final settingsButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.settings),
          matching: find.byType(IconButton),
        ),
      );
      expect(settingsButton.color, cs.primary);

      playerManager.dispose();
    });

    testWidgets('all navigation items are present', (tester) async {
      final playerManager = PlayerManager();
      await tester.pumpWidget(
        buildSidebar(playerManager: playerManager, onItemSelected: (_) {}),
      );

      expect(find.byIcon(Icons.library_music), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      playerManager.dispose();
    });

    testWidgets('has DpadRegion for nav links', (tester) async {
      final playerManager = PlayerManager();
      await tester.pumpWidget(
        buildSidebar(playerManager: playerManager, onItemSelected: (_) {}),
      );

      expect(find.byType(DpadRegion), findsWidgets);

      playerManager.dispose();
    });

    testWidgets('has DpadRegion for sidebar player', (tester) async {
      final playerManager = PlayerManager();
      playerManager.updateCurrentPlaying(
        Song(id: '1', name: 'Test', primaryArtists: 'Artist'),
      );
      await tester.pumpWidget(
        buildSidebar(playerManager: playerManager, onItemSelected: (_) {}),
      );

      expect(find.byType(DpadRegion), findsWidgets);

      playerManager.dispose();
    });
  });
}
