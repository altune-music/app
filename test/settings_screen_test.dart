import 'package:altune/controllers/main_controller.dart';
import 'package:altune/interfaces/theme_color.dart';
import 'package:altune/models/app_update.dart';
import 'package:altune/services/state_service.dart';
import 'package:altune/services/player_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dpad/dpad.dart';
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
    testWidgets('shows Settings title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            showBackButton: false,
            showScaffold: false,
            controller: testController(),
          ),
        ),
      );

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('does not show app version on desktop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            showBackButton: false,
            showScaffold: false,
            controller: testController(),
          ),
        ),
      );

      // App version removed from settings. Battery tile hidden on non-Android.
      expect(find.textContaining('v1.0.0'), findsNothing);
      expect(find.textContaining('Battery'), findsNothing);
    });

    testWidgets('shows back button when showBackButton is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            showBackButton: true,
            showScaffold: true,
            controller: testController(),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    });

    testWidgets('hides back button when showBackButton is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            showBackButton: false,
            showScaffold: false,
            controller: testController(),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_left), findsNothing);
    });

    testWidgets('shows Backup Library button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            showBackButton: false,
            showScaffold: false,
            controller: testController(),
          ),
        ),
      );

      expect(find.text('Backup'), findsOneWidget);
      expect(
        find.text('Back up your library and playlists to a file'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.save), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);
      expect(
        find.text('Restore your library and playlists from a backup file'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.upload_file), findsOneWidget);
    });

    testWidgets('shows about section with app identity', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            showBackButton: false,
            showScaffold: false,
            controller: testController(),
          ),
        ),
      );

      // App name removed from About section. Version is shown via version tile.
      expect(find.textContaining(RegExp(r'Version|Loading…')), findsOneWidget);
    });

    testWidgets('shows about action tiles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            showBackButton: false,
            showScaffold: false,
            controller: testController(),
          ),
        ),
      );

      expect(find.text('View on Github'), findsOneWidget);
    });

    testWidgets('shows about attribution', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            showBackButton: false,
            showScaffold: false,
            controller: testController(),
          ),
        ),
      );

      final year = DateTime.now().year;
      expect(
        find.text(
          '© $year altune · Built with Flutter · Not affiliated with any music streaming service.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('about section has D-pad focusable actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            showBackButton: false,
            showScaffold: false,
            controller: testController(),
          ),
        ),
      );

      expect(find.byType(DpadFocusable), findsWidgets);
    });

    testWidgets('shows up to date message when check succeeds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            showBackButton: false,
            showScaffold: false,
            controller: testController(),
            // Inject a fake update check so the screen makes no network call
            // and the async state resolves deterministically.
            updateCheck: () async => null,
          ),
        ),
      );

      expect(find.text('Checking for updates…'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Checking for updates…'), findsNothing);
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
      expect(find.text('Checking for updates…'), findsNothing);
      expect(find.text('You are up to date'), findsNothing);
      expect(find.textContaining('Update available'), findsNothing);
    });

    testWidgets('shows a theme color tile with the current accent', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            showBackButton: false,
            showScaffold: false,
            controller: testController(),
          ),
        ),
      );

      expect(find.text('Theme color'), findsOneWidget);
      // Default accent is green.
      expect(find.text('Green'), findsOneWidget);
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

      // The bottom sheet lists every preset color.
      expect(find.text('Blue'), findsOneWidget);
      await tester.tap(find.text('Blue'));
      await tester.pumpAndSettle();

      expect(controller.themeColor, ThemeColor.blue);
    });
  });
}
