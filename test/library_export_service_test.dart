import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:altune/controllers/main_controller.dart';
import 'package:altune/models/saved_playlist.dart';
import 'package:altune/models/song.dart';
import 'package:altune/services/library_export_service.dart';
import 'package:altune/services/player_manager.dart';
import 'package:altune/services/state_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiosaavn/jiosaavn.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MainController buildController({
    required List<Song> songs,
    required List<SavedPlaylist> playlists,
  }) => MainController(
    stateService: StateService(),
    client: JioSaavnClient(),
    playerManager: PlayerManager(),
    localSongs: songs,
    playlists: playlists,
  );

  test(
    'backupSummary counts library and user-playlist songs and playlists',
    () {
      final library = SavedPlaylist(
        id: 'library',
        name: 'Library',
        isSystem: true,
        songIds: ['s1', 's2'],
      );
      final userPlaylist = SavedPlaylist(
        id: 'p1',
        name: 'Favorites',
        songIds: ['s3'],
      );
      // s4 is in the local pool but not referenced by any playlist, so it is
      // excluded from the backup (matches buildBackupPayload behavior).
      final songs = [
        Song(id: 's1'),
        Song(id: 's2'),
        Song(id: 's3'),
        Song(id: 's4'),
      ];
      final controller = buildController(
        songs: songs,
        playlists: [library, userPlaylist],
      );

      final summary = LibraryExportService.backupSummary(controller);

      expect(summary.songCount, 3);
      expect(summary.playlistCount, 1);
    },
  );

  test('backupSummary excludes system playlists other than Library', () {
    final library = SavedPlaylist(
      id: 'library',
      name: 'Library',
      isSystem: true,
      songIds: ['s1'],
    );
    final recent = SavedPlaylist(
      id: 'recent_songs',
      name: 'Recent Songs',
      isSystem: true,
      songIds: ['s2'],
    );
    final controller = buildController(
      songs: [
        Song(id: 's1'),
        Song(id: 's2'),
      ],
      playlists: [library, recent],
    );

    final summary = LibraryExportService.backupSummary(controller);

    // Recent Songs is system, so it is not counted as a backed-up playlist.
    expect(summary.playlistCount, 0);
    expect(summary.songCount, 1);
  });

  test('backupSummary matches buildBackupPayload counts', () {
    final library = SavedPlaylist(
      id: 'library',
      name: 'Library',
      isSystem: true,
      songIds: ['s1', 's2'],
    );
    final userPlaylist = SavedPlaylist(
      id: 'p1',
      name: 'Favorites',
      songIds: ['s3'],
    );
    final songs = [
      Song(id: 's1'),
      Song(id: 's2'),
      Song(id: 's3'),
      Song(id: 's4'),
    ];
    final controller = buildController(
      songs: songs,
      playlists: [library, userPlaylist],
    );

    final summary = LibraryExportService.backupSummary(controller);
    final payload = LibraryExportService.buildBackupPayload(controller);
    final decoded = json.decode(payload) as Map<String, dynamic>;

    // The summary must agree with the actual file contents.
    expect(summary.songCount, (decoded['songs'] as List).length);
    expect(summary.playlistCount, (decoded['playlists'] as List).length);
  });

  test('exportLibrary writes the backup JSON to the Backups folder', () async {
    // path_provider has no platform channel in `flutter test`; mock so the
    // backup lands in a known temp location.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async {
            switch (call.method) {
              case 'getApplicationSupportDirectory':
              case 'getTemporaryDirectory':
              case 'getApplicationDocumentsDirectory':
              case 'getLibraryDirectory':
              case 'getApplicationCacheDirectory':
                return '/tmp/altune_export_test';
            }
            return null;
          },
        );

    final library = SavedPlaylist(
      id: 'library',
      name: 'Library',
      isSystem: true,
      songIds: ['s1'],
    );
    final controller = buildController(
      songs: [Song(id: 's1', name: 'Song One')],
      playlists: [library],
    );

    final file = await LibraryExportService.exportLibrary(controller);

    expect(file.existsSync(), isTrue);
    expect(file.path, contains('Backups'));
    final decoded =
        json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    expect((decoded['songs'] as List).length, 1);
    expect((decoded['playlists'] as List).length, 0);
  });
}
