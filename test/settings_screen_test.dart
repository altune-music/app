import 'package:flutter_test/flutter_test.dart';
import 'package:altune/controllers/main_controller.dart';
import 'package:altune/interfaces/theme_color.dart';
import 'package:altune/models/app_update.dart';
import 'package:altune/services/state_service.dart';
import 'package:altune/services/player_manager.dart';
import 'package:flutter/material.dart';
import 'package:altune/screens/settings_screen.dart';
import 'package:jiosaavn/jiosaavn.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MainController testController() => MainController(
    stateService: StateService(),
    client: JioSaavnClient(),
    playerManager: PlayerManager(),
    localSongs: [],
  );

  group('SettingsScreen', () {
    testWidgets('shows up to date message when check succeeds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            showBackButton: false,
            showScaffold: false,
            controller: testController(),
            updateCheck: () async => null,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('You are up to date'), findsOneWidget);
    });

    testWidgets('shows update status in version tile when a release is newer', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            showBackButton: false,
            showScaffold: false,
            controller: testController(),
            updateCheck: () async => AppUpdate(
              version: 'v2.0.0',
              name: 'v2.0.0',
              body: '',
              htmlUrl:
                  'https://github.com/altune-music/app/releases/tag/v2.0.0',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Update available: v2.0.0'), findsOneWidget);
    });

    testWidgets('shows no update status when check fails', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            showBackButton: false,
            showScaffold: false,
            controller: testController(),
            updateCheck: () async => throw Exception('network down'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('Update available'), findsNothing);
    });

    testWidgets('selecting a theme color persists it on the controller', (
      tester,
    ) async {
      final controller = testController();
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            showBackButton: false,
            showScaffold: false,
            controller: controller,
          ),
        ),
      );

      await tester.tap(find.text('Theme color'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Blue'));
      await tester.pumpAndSettle();

      expect(controller.themeColor, ThemeColor.blue);
    });
  });
}
