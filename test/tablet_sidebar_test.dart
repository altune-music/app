import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:altune/services/player_manager.dart';
import 'package:altune/widgets/tablet_sidebar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TabletSidebar', () {
    Widget buildSidebar({
      required ValueChanged<int> onItemSelected,
      PlayerManager? playerManager,
    }) {
      final pm = playerManager ?? PlayerManager();
      return MaterialApp(
        home: Scaffold(
          body: TabletSidebar(
            selectedIndex: 0,
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
  });
}
