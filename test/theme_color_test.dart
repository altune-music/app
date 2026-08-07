import 'dart:io';

import 'package:altune/controllers/main_controller.dart';
import 'package:altune/interfaces/theme_color.dart';
import 'package:altune/services/player_manager.dart';
import 'package:altune/services/state_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:jiosaavn/jiosaavn.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

// Points getApplicationSupportDirectory at a real temp dir so saveState() can
// write a file we assert on, instead of the silent catch that runs without a
// path_provider platform.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.supportDir);
  final String supportDir;

  @override
  Future<String?> getApplicationSupportPath() async => supportDir;

  @override
  Future<String?> getTemporaryPath() async => supportDir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('altune_theme_test');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  JioSaavnClient deadClient() =>
      JioSaavnClient(BaseOptions(baseUrl: 'http://127.0.0.1:1'));

  MainController makeController() => MainController(
    stateService: StateService(),
    client: deadClient(),
    playerManager: PlayerManager(),
    localSongs: [],
  );

  group('ThemeColor enum', () {
    test('green is the default first value', () {
      expect(ThemeColor.values.first, ThemeColor.green);
      expect(ThemeColor.green.label, 'Green');
    });

    test('each option has a label and a seed color', () {
      for (final c in ThemeColor.values) {
        expect(c.label, isNotEmpty);
        expect(c.seedColor, isNotNull);
      }
      // Distinct labels so the picker never shows two identical entries.
      final labels = ThemeColor.values.map((c) => c.label).toSet();
      expect(labels.length, ThemeColor.values.length);
    });

    test('index maps back to the same enum value (persistence safety)', () {
      for (final c in ThemeColor.values) {
        expect(ThemeColor.values[c.index], c);
      }
    });
  });

  group('MainController themeColor', () {
    test('defaults to green', () {
      final controller = makeController();
      addTearDown(() => controller.playerManager.dispose());
      expect(controller.themeColor, ThemeColor.green);
    });

    test('setThemeColor updates the value and fires onThemeChanged', () async {
      final controller = makeController();
      addTearDown(() => controller.playerManager.dispose());

      var notified = false;
      controller.onThemeChanged = () => notified = true;

      await controller.setThemeColor(ThemeColor.blue);

      expect(controller.themeColor, ThemeColor.blue);
      expect(notified, isTrue);
    });

    test(
      'theme color persists in state and restores across loadState',
      () async {
        final writer = makeController();
        addTearDown(() => writer.playerManager.dispose());

        await writer.setThemeColor(ThemeColor.purple);
        await writer.saveState();

        final reader = makeController();
        addTearDown(() => reader.playerManager.dispose());
        await reader.loadState();

        expect(reader.themeColor, ThemeColor.purple);
      },
    );

    test(
      'loadState notifies the shell so the persisted theme is applied',
      () async {
        final writer = makeController();
        addTearDown(() => writer.playerManager.dispose());
        await writer.setThemeColor(ThemeColor.teal);
        await writer.saveState();

        final reader = makeController();
        addTearDown(() => reader.playerManager.dispose());
        var themeNotified = false;
        reader.onThemeChanged = () => themeNotified = true;

        await reader.loadState();

        expect(reader.themeColor, ThemeColor.teal);
        expect(themeNotified, isTrue);
      },
    );

    test('an unknown stored index falls back to green', () async {
      final controller = makeController();
      addTearDown(() => controller.playerManager.dispose());

      // Load a hand-crafted state whose uiSettings holds an out-of-range
      // themeColor index (e.g. written by an older/newer build). Theme building
      // must not crash and must fall back to the brand default.
      File('${tempDir.path}/altune_state.json').writeAsStringSync(
        '{"v":1,"songs":[],"playlists":[],"queue":{},'
        '"uiSettings":{"themeColor":99}}',
      );
      await controller.loadState();
      expect(controller.themeColor, ThemeColor.green);
    });
  });
}
