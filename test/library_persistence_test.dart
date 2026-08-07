import 'dart:convert';
import 'package:altune/services/state_service.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:jiosaavn/jiosaavn.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:altune/models/song.dart';
import 'package:altune/controllers/main_controller.dart';
import 'package:altune/services/player_manager.dart';
import 'package:altune/services/library_export_service.dart';

// Points getApplicationSupportDirectory at a real temp dir so saveState() and
// exportLibrary() write files we can assert on, instead of the silent catch
// that runs without a path_provider platform.
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
    tempDir = await Directory.systemTemp.createTemp('altune_state_test');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  // Pinned to a dead local port so the fire-and-forget _backgroundSaveById
  // fails fast instead of hitting the network in tests.
  JioSaavnClient deadClient() =>
      JioSaavnClient(BaseOptions(baseUrl: 'http://127.0.0.1:1'));

  SongResponse makeSongResponse(String id) => SongResponse(
    id: id,
    name: 'Song $id',
    type: 'song',
    album: SongResponseAlbum(id: 'al', name: 'Album', url: ''),
    year: '2024',
    releaseDate: '',
    duration: '0:30',
    label: '',
    primaryArtists: 'Artist',
    primaryArtistsId: '',
    featuredArtists: '',
    featuredArtistsId: '',
    explicitContent: 0,
    language: '',
    hasLyrics: '',
    url: '',
    copyright: '',
    image: [],
    downloadUrl: [],
  );

  Future<void> waitFor(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Timed out waiting for condition');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  test(
    'single state file holds a recently played song but the export does not',
    () async {
      final controller = MainController(
        stateService: StateService(),
        client: deadClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      // Playing a song adds it to Recent Songs (persisted in altune_state.json).
      controller.playerManager.updateCurrentPlaying(
        Song(id: 'recent1', name: 'Played', primaryArtists: 'Artist'),
      );

      final state = File('${tempDir.path}/altune_state.json');
      await waitFor(
        () =>
            state.existsSync() && state.readAsStringSync().contains('recent1'),
      );

      // State file has it.
      expect(state.readAsStringSync(), contains('recent1'));

      // Backup excludes recent-only songs.
      final backupFile = await LibraryExportService.exportLibrary(controller);
      expect(backupFile, isNotNull);
      final exportJson =
          json.decode(await backupFile.readAsString()) as Map<String, dynamic>;
      expect(
        exportJson['songs'],
        isNot(contains(predicate((e) => (e as Map)['id'] == 'recent1'))),
      );
      expect(exportJson['playlists'], isNotNull);
    },
  );

  test(
    'backup includes library songs and user playlists with minimal fields',
    () async {
      final controller = MainController(
        stateService: StateService(),
        client: deadClient(),
        playerManager: PlayerManager(),
        localSongs: [
          Song(id: 's1', name: 'A', primaryArtists: 'X', album: 'Al1'),
          Song(id: 's2', name: 'B', primaryArtists: 'Y', album: 'Al2'),
          Song(id: 's3', name: 'C', primaryArtists: 'Z', album: 'Al3'),
        ],
      );
      addTearDown(() => controller.playerManager.dispose());

      await controller.toggleSongInLibrary(makeSongResponse('s1'));
      await controller.createPlaylist('My Mix');
      final playlist = controller.playlists.firstWhere((p) => !p.isSystem);
      await controller.addToPlaylist(
        Song(id: 's2', name: 'B', primaryArtists: 'Y', album: 'Al2'),
        playlist,
      );
      await controller.addToPlaylist(
        Song(id: 's3', name: 'C', primaryArtists: 'Z', album: 'Al3'),
        playlist,
      );

      // Backup includes library songs and user playlists with minimal fields.
      final backupFile = await LibraryExportService.exportLibrary(controller);
      expect(backupFile, isNotNull);
      final exportJson =
          json.decode(await backupFile.readAsString()) as Map<String, dynamic>;

      final songs = (exportJson['songs'] as List).cast<Map<String, dynamic>>();
      expect(songs.map((s) => s['id']), containsAll(['s1', 's2', 's3']));
      for (final s in songs) {
        expect(s.keys, containsAll(['id', 'name', 'primaryArtists', 'album']));
        expect(s.containsKey('imageUrl'), isFalse);
      }

      final playlists = (exportJson['playlists'] as List)
          .cast<Map<String, dynamic>>();
      expect(playlists.map((p) => p['id']), contains(playlist.id));
      expect(playlists.firstWhere((p) => p['id'] == playlist.id)['songIds'], [
        's2',
        's3',
      ]);
    },
  );

  test('queue and current playing song persist in state and restore', () async {
    final controller = MainController(
      stateService: StateService(),
      client: deadClient(),
      playerManager: PlayerManager(),
      localSongs: [],
    );
    addTearDown(() => controller.playerManager.dispose());

    controller.playerManager.setQueue([
      Song(id: 'q1', name: 'Q1', filePath: ''),
      Song(id: 'q2', name: 'Q2', filePath: ''),
    ], songId: 'q1');
    controller.playerManager.updateCurrentPlaying(
      Song(id: 'q1', name: 'Q1', filePath: ''),
    );

    final state = File('${tempDir.path}/altune_state.json');
    await waitFor(() {
      if (!state.existsSync()) return false;
      try {
        final data =
            json.decode(state.readAsStringSync()) as Map<String, dynamic>;
        return data.containsKey('queue');
      } on FormatException {
        return false;
      }
    });
    final data = json.decode(state.readAsStringSync()) as Map<String, dynamic>;

    final queueIds = (data['queue'] as Map<String, dynamic>)['ids'] as List;
    expect(queueIds, contains('q2'));
    expect(data['currentSongId'], 'q1');
    expect(controller.queueManager.queue.length, 2);
  });

  test('orphaned queue songs persist as transient entries', () async {
    final writer = MainController(
      stateService: StateService(),
      client: deadClient(),
      playerManager: PlayerManager(),
      localSongs: [
        Song(id: 'lib1', name: 'Library', primaryArtists: 'A', album: 'Al'),
      ],
    );
    addTearDown(() => writer.playerManager.dispose());

    writer.playerManager.setQueue([
      Song(id: 'lib1', name: 'Library', primaryArtists: 'A', album: 'Al'),
      Song(id: 'orphan1', name: 'Orphan', primaryArtists: 'B', album: 'Al2'),
    ], songId: 'orphan1');
    await writer.saveState();

    final state = File('${tempDir.path}/altune_state.json');
    final raw = state.readAsStringSync();
    expect(raw, contains('orphan1'));

    final reader = MainController(
      stateService: StateService(),
      client: deadClient(),
      playerManager: PlayerManager(),
      localSongs: [
        Song(id: 'lib1', name: 'Library', primaryArtists: 'A', album: 'Al'),
      ],
    );
    addTearDown(() => reader.playerManager.dispose());
    await reader.loadState();

    expect(reader.queueManager.queue.map((s) => s.id), ['lib1', 'orphan1']);
    expect(reader.queueManager.currentIndex, 1);
    expect(reader.currentPlaying?.id, 'orphan1');
  });

  test(
    'a fresh controller restores the queue and current song via loadState',
    () async {
      final writer = MainController(
        stateService: StateService(),
        client: deadClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => writer.playerManager.dispose());

      writer.playerManager.setQueue([
        Song(id: 'q1', name: 'Q1', filePath: ''),
        Song(id: 'q2', name: 'Q2', filePath: ''),
      ], songId: 'q2');
      writer.playerManager.updateCurrentPlaying(
        Song(id: 'q2', name: 'Q2', filePath: ''),
      );
      await writer.saveState();

      // Simulate an app restart: a brand-new controller loads the persisted state.
      final reader = MainController(
        stateService: StateService(),
        client: deadClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => reader.playerManager.dispose());
      await reader.loadState();

      expect(reader.queueManager.queue.map((s) => s.id), ['q1', 'q2']);
      expect(reader.queueManager.currentIndex, 1);
      expect(reader.currentPlaying?.id, 'q2');
    },
  );

  test('streamSongAndQueueAlbum sets queue to album songs', () async {
    final controller = MainController(
      stateService: StateService(),
      client: deadClient(),
      playerManager: PlayerManager(),
      localSongs: [],
    );
    addTearDown(() => controller.playerManager.dispose());

    final albumSongs = [
      makeSongResponse('a1'),
      makeSongResponse('a2'),
      makeSongResponse('a3'),
    ];
    await controller.streamSongAndQueueAlbum(albumSongs.first, albumSongs);

    expect(controller.queueManager.queue.length, 3);
    expect(controller.queueManager.queue.map((s) => s.id), ['a1', 'a2', 'a3']);
    expect(controller.queueManager.currentSong?.id, 'a1');
  });

  test('sort modes persist in state and restore across loadState', () async {
    final writer = MainController(
      stateService: StateService(),
      client: deadClient(),
      playerManager: PlayerManager(),
      localSongs: [],
    );
    addTearDown(() => writer.playerManager.dispose());

    await writer.setLibrarySortMode(1);
    await writer.setPlaylistSortMode(2);
    await writer.saveState();

    final reader = MainController(
      stateService: StateService(),
      client: deadClient(),
      playerManager: PlayerManager(),
      localSongs: [],
    );
    addTearDown(() => reader.playerManager.dispose());
    await reader.loadState();

    expect(reader.librarySortMode, 1);
    expect(reader.playlistSortMode, 2);
  });

  test('restore library merges songs and playlists from backup', () async {
    final controller = MainController(
      stateService: StateService(),
      client: deadClient(),
      playerManager: PlayerManager(),
      localSongs: [
        Song(id: 'existing', name: 'Keep', primaryArtists: 'A', album: 'Al'),
      ],
    );
    addTearDown(() => controller.playerManager.dispose());

    await controller.createPlaylist('Existing');
    await controller.saveState();

    final backupData = {
      'songs': [
        {'id': 'new1', 'name': 'New 1', 'primaryArtists': 'B', 'album': 'Al2'},
        {
          'id': 'existing',
          'name': 'Keep',
          'primaryArtists': 'A',
          'album': 'Al',
        },
      ],
      'playlists': [
        {
          'id': 'pl1',
          'name': 'Imported',
          'songIds': ['new1'],
        },
      ],
    };

    final result = await LibraryExportService.importData(
      controller,
      backupData,
    );
    expect(result.songs, 1);
    expect(result.playlists, 1);
    expect(controller.localSongs.map((s) => s.id), contains('new1'));
    expect(controller.localSongs.map((s) => s.id), contains('existing'));
    expect(
      controller.playlists.any((p) => p.id == 'pl1' && p.name == 'Imported'),
      isTrue,
    );
  });

  test('saveState creates parent directories when missing', () async {
    final nestedDir = Directory('${tempDir.path}/nested/deep');
    PathProviderPlatform.instance = _FakePathProvider(nestedDir.path);

    final controller = MainController(
      stateService: StateService(),
      client: deadClient(),
      playerManager: PlayerManager(),
      localSongs: [],
    );
    addTearDown(() => controller.playerManager.dispose());

    await controller.saveState();

    final stateFile = File('${nestedDir.path}/altune_state.json');
    expect(await stateFile.exists(), isTrue);
  });

  test('restoreSongs skips already offline songs', () async {
    final controller = MainController(
      stateService: StateService(),
      client: deadClient(),
      playerManager: PlayerManager(),
      localSongs: [
        Song(
          id: 'offline1',
          name: 'Offline',
          primaryArtists: 'A',
          album: 'Al',
          filePath: '/tmp/offline1.mp3',
        ),
        Song(
          id: 'streaming1',
          name: 'Streaming',
          primaryArtists: 'B',
          album: 'Al2',
        ),
      ],
    );
    addTearDown(() => controller.playerManager.dispose());

    // restoreSongs should skip 'offline1' (already has filePath) and
    // attempt to download 'streaming1' (which will fail fast with deadClient).
    await controller.restoreSongs(['offline1', 'streaming1']);

    // Both songs remain in localSongs; offline1 unchanged, streaming1
    // still has no filePath since the dead client download failed.
    expect(
      controller.localSongs.where((s) => s.id == 'offline1').first.filePath,
      '/tmp/offline1.mp3',
    );
    expect(
      controller.localSongs.where((s) => s.id == 'streaming1').first.filePath,
      isNull,
    );
  });

  group('restore from the Restore folder', () {
    test(
      'restoreDirectoryPath points at the Restore folder in app support',
      () async {
        expect(
          await LibraryExportService.restoreDirectoryPath(),
          '${tempDir.path}/${LibraryExportService.restoreFolderName}',
        );
      },
    );

    test(
      'findRestoreFile returns null when the Restore folder has no JSON',
      () async {
        expect(await LibraryExportService.findRestoreFile(), isNull);
      },
    );

    // The error deliberately does NOT embed the folder path — the dialog
    // resolves and displays that path separately (see restore_dialog.dart).
    // The message only needs to name the Restore folder so the user knows
    // where to drop a file.
    test(
      'prepareRestore names the Restore folder in its error (path shown by dialog)',
      () async {
        Object? caught;
        try {
          await LibraryExportService.prepareRestore();
        } on FormatException catch (e) {
          caught = e;
          expect(e.message, contains('Restore folder'));
        }
        expect(caught, isA<FormatException>());
      },
    );

    test(
      'prepareRestore accepts a backup JSON of any name and reports counts',
      () async {
        final dir = await LibraryExportService.restoreDirectoryPath();
        await Directory(dir).create(recursive: true);
        // Non-standard filename — the app must still pick it up.
        final path = '$dir/my_library_backup.json';
        await File(path).writeAsString(
          json.encode({
            'songs': [
              {
                'id': 'r1',
                'name': 'Restored',
                'primaryArtists': 'A',
                'album': 'Al',
              },
              {
                'id': 'r2',
                'name': 'Restored 2',
                'primaryArtists': 'B',
                'album': 'Al',
              },
            ],
            'playlists': [
              {
                'id': 'rp',
                'name': 'Restored',
                'songIds': ['r1'],
              },
            ],
          }),
        );

        final preview = await LibraryExportService.prepareRestore();
        expect(preview.file.path, path);
        expect(preview.songCount, 2);
        expect(preview.playlistCount, 1);
      },
    );

    test(
      'prepareRestore picks the most recently modified JSON when several',
      () async {
        final dir = await LibraryExportService.restoreDirectoryPath();
        await Directory(dir).create(recursive: true);
        final older = File('$dir/older.json');
        await older.writeAsString(
          json.encode({
            'songs': [
              {
                'id': 'old',
                'name': 'Old',
                'primaryArtists': 'A',
                'album': 'Al',
              },
            ],
            'playlists': [],
          }),
        );
        // Ensure a distinguishable mtime before writing the newer file.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final newer = File('$dir/newer.json');
        await newer.writeAsString(
          json.encode({
            'songs': [
              {
                'id': 'new',
                'name': 'New',
                'primaryArtists': 'B',
                'album': 'Al',
              },
            ],
            'playlists': [],
          }),
        );

        final preview = await LibraryExportService.prepareRestore();
        expect(preview.file.path, newer.path);
        expect(preview.songCount, 1);
      },
    );

    test('prepareRestore rejects a malformed restore file', () async {
      final dir = await LibraryExportService.restoreDirectoryPath();
      await Directory(dir).create(recursive: true);
      await File('$dir/broken.json').writeAsString('{"foo": 1}');

      expect(
        () => LibraryExportService.prepareRestore(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
