import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:altune/services/state_service.dart';
import 'package:dio/dio.dart';
import 'package:jiosaavn/jiosaavn.dart';
import 'package:altune/models/saved_playlist.dart';
import 'package:altune/models/song.dart';
import 'package:altune/controllers/main_controller.dart';
import 'package:altune/services/player_manager.dart';

class _MockAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = json.encode({
      'id': options.path.split('/').last,
      'name': 'Mock Song',
      'type': 'song',
      'album': {'id': 'al', 'name': 'Album', 'url': ''},
      'year': '2024',
      'releaseDate': '',
      'duration': '0:30',
      'label': '',
      'primaryArtists': 'Artist',
      'primaryArtistsId': '',
      'featuredArtists': '',
      'featuredArtistsId': '',
      'explicitContent': 0,
      'language': '',
      'hasLyrics': '',
      'url': '',
      'copyright': '',
      'image': [],
      'downloadUrl': [],
    });
    return ResponseBody.fromBytes(
      utf8.encode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  JioSaavnClient mockClient() {
    final client = JioSaavnClient();
    client.albums.dio.httpClientAdapter = _MockAdapter();
    return client;
  }

  group('SavedPlaylist', () {
    test('fromJson creates correct instance with all fields', () {
      final json = {
        'id': '123',
        'name': 'My Playlist',
        'songIds': ['s1', 's2', 's3'],
        'coverImageUrl': 'https://example.com/cover.jpg',
        'isSystem': true,
      };

      final playlist = SavedPlaylist.fromJson(json);

      expect(playlist.id, '123');
      expect(playlist.name, 'My Playlist');
      expect(playlist.songIds, ['s1', 's2', 's3']);
      expect(playlist.coverImageUrl, 'https://example.com/cover.jpg');
      expect(playlist.isSystem, isTrue);
    });

    test('fromJson handles null songIds', () {
      final json = {'id': '123', 'name': 'My Playlist'};

      final playlist = SavedPlaylist.fromJson(json);

      expect(playlist.id, '123');
      expect(playlist.name, 'My Playlist');
      expect(playlist.songIds, []);
      expect(playlist.coverImageUrl, isNull);
      expect(playlist.isSystem, isFalse);
    });

    test('fromJson handles missing isSystem', () {
      final json = {'id': '123', 'name': 'My Playlist'};

      final playlist = SavedPlaylist.fromJson(json);

      expect(playlist.isSystem, isFalse);
    });

    test('toJson returns correct map', () {
      final playlist = SavedPlaylist(
        id: '123',
        name: 'My Playlist',
        songIds: ['s1', 's2'],
        coverImageUrl: 'https://example.com/cover.jpg',
        isSystem: true,
      );

      final json = playlist.toJson();

      expect(json['id'], '123');
      expect(json['name'], 'My Playlist');
      expect(json['songIds'], ['s1', 's2']);
      expect(json['coverImageUrl'], 'https://example.com/cover.jpg');
      expect(json['isSystem'], isTrue);
    });

    test('roundtrip fromJson toJson preserves data', () {
      final original = SavedPlaylist(
        id: '456',
        name: 'Test Playlist',
        songIds: ['a', 'b', 'c'],
        coverImageUrl: 'https://example.com/img.png',
        isSystem: true,
      );

      final restored = SavedPlaylist.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.songIds, original.songIds);
      expect(restored.coverImageUrl, original.coverImageUrl);
      expect(restored.isSystem, original.isSystem);
    });
  });

  group('Song', () {
    test('fromJson creates instance correctly', () {
      final now = DateTime(2024, 1, 15);
      final json = {
        'id': 'song1',
        'name': 'Test Song',
        'primaryArtists': 'Artist Name',
        'album': 'Test Album',
        'filePath': '/path/to/song.mp3',
        'imageUrl': 'https://example.com/image.jpg',
        'localArtworkPath': '/path/to/artwork.jpg',
        'bitrate': '320',
        'dateAdded': now.toIso8601String(),
      };

      final song = Song.fromJson(json);

      expect(song.id, 'song1');
      expect(song.name, 'Test Song');
      expect(song.primaryArtists, 'Artist Name');
      expect(song.album, 'Test Album');
      expect(song.filePath, '/path/to/song.mp3');
      expect(song.imageUrl, 'https://example.com/image.jpg');
      expect(song.localArtworkPath, '/path/to/artwork.jpg');
      expect(song.bitrate, '320');
      expect(song.dateAdded, now);
    });

    test('toJson returns correct map', () {
      final now = DateTime(2024, 6, 1, 12, 30);
      final song = Song(
        id: 'song1',
        name: 'Test Song',
        primaryArtists: 'Artist',
        album: 'Album',
        filePath: '/path/to/song.mp3',
        imageUrl: 'https://example.com/image.jpg',
        dateAdded: now,
      );

      final json = song.toJson();

      expect(json['id'], 'song1');
      expect(json['name'], 'Test Song');
      expect(json['primaryArtists'], 'Artist');
      expect(json['album'], 'Album');
      expect(json['filePath'], '/path/to/song.mp3');
      expect(json['imageUrl'], 'https://example.com/image.jpg');
      expect(json['dateAdded'], now.toIso8601String());
    });

    test('decodes HTML entities in name', () {
      final json = {
        'id': 'song1',
        'name': 'Song &amp; Title',
        'filePath': '/path/to/song.mp3',
      };

      final song = Song.fromJson(json);

      expect(song.name, 'Song & Title');
    });

    test('dateAdded defaults to non-null when not provided', () {
      final song = Song(id: 'song1', filePath: '/path/to/song.mp3');

      expect(song.dateAdded, isNotNull);
    });
  });

  group('System playlists', () {
    setUp(() {});

    test('libraryPlaylist getter creates Library if missing', () {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      final lib = controller.libraryPlaylist;

      expect(lib.name, 'Library');
      expect(lib.isSystem, isTrue);
      expect(controller.playlists.any((p) => p.id == 'library'), isTrue);
    });

    test('recentSongsPlaylist getter creates Recent Songs if missing', () {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      final recent = controller.recentSongsPlaylist;

      expect(recent.name, 'Recent Songs');
      expect(recent.isSystem, isTrue);
      expect(controller.playlists.any((p) => p.id == 'recent_songs'), isTrue);
    });

    test('getPlaylistById finds system playlists', () {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      // Trigger creation
      controller.libraryPlaylist;

      final found = controller.getPlaylistById('library');
      expect(found, isNotNull);
      expect(found!.name, 'Library');
    });

    test('getPlaylistById returns null for unknown id', () {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      expect(controller.getPlaylistById('nonexistent'), isNull);
    });
  });

  group('isSongInLibrary', () {
    setUp(() {});

    test('returns false when song not in Library playlist', () {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [Song(id: 's1', filePath: '')],
      );
      addTearDown(() => controller.playerManager.dispose());

      expect(controller.isSongInLibrary('s1'), isFalse);
    });

    test('returns true when song is in Library playlist', () {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      // Directly add to Library playlist
      final lib = controller.libraryPlaylist;
      final newIds = [...lib.songIds, 's1'];
      controller.playlists[controller.playlists.indexOf(lib)] = SavedPlaylist(
        id: lib.id,
        name: lib.name,
        songIds: newIds,
        isSystem: true,
      );

      expect(controller.isSongInLibrary('s1'), isTrue);
    });
  });

  group('MainController playlist CRUD', () {
    setUp(() {});

    Song makeSong(String id) => Song(id: id, filePath: '');

    test(
      'createPlaylist adds a new playlist with given name and non-empty ID',
      () async {
        final controller = MainController(
          stateService: StateService(),
          client: mockClient(),
          playerManager: PlayerManager(),
          localSongs: [],
        );
        addTearDown(() => controller.playerManager.dispose());

        await controller.createPlaylist('My Mix');
        final user = controller.playlists.where((p) => !p.isSystem).toList();

        expect(user.length, 1);
        expect(user[0].name, 'My Mix');
        expect(user[0].id.isNotEmpty, isTrue);
      },
    );

    test('deletePlaylist removes a user playlist', () async {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      await controller.createPlaylist('Test');
      final id = controller.playlists.firstWhere((p) => !p.isSystem).id;

      await controller.deletePlaylist(id);
      expect(controller.getPlaylistById(id), isNull);
    });

    test('deletePlaylist does nothing for system playlist', () async {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      controller.libraryPlaylist; // ensure created
      await controller.deletePlaylist('library');
      expect(controller.playlists.any((p) => p.id == 'library'), isTrue);
    });

    test('deletePlaylist does nothing when ID does not exist', () async {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      final before = controller.playlists.length;
      await controller.deletePlaylist('nonexistent');
      expect(controller.playlists.length, before);
    });

    test('addToPlaylist adds a song ID to a user playlist', () async {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [makeSong('s1'), makeSong('s2')],
      );
      addTearDown(() => controller.playerManager.dispose());

      await controller.createPlaylist('Test');
      final pid = controller.playlists.firstWhere((p) => !p.isSystem).id;

      await controller.addToPlaylist(
        makeSong('s1'),
        controller.getPlaylistById(pid)!,
      );
      expect(controller.getPlaylistById(pid)!.songIds, ['s1']);
    });

    test('addToPlaylist does not add duplicates', () async {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [makeSong('s1')],
      );
      addTearDown(() => controller.playerManager.dispose());

      await controller.createPlaylist('Test');
      final pid = controller.playlists.firstWhere((p) => !p.isSystem).id;

      await controller.addToPlaylist(
        makeSong('s1'),
        controller.getPlaylistById(pid)!,
      );
      await controller.addToPlaylist(
        makeSong('s1'),
        controller.getPlaylistById(pid)!,
      );
      expect(controller.getPlaylistById(pid)!.songIds, ['s1']);
    });

    test(
      'addToPlaylist does nothing for system playlist (Recent Songs)',
      () async {
        final controller = MainController(
          stateService: StateService(),
          client: mockClient(),
          playerManager: PlayerManager(),
          localSongs: [makeSong('s1')],
        );
        addTearDown(() => controller.playerManager.dispose());

        final recent = controller.recentSongsPlaylist;
        await controller.addToPlaylist(makeSong('s1'), recent);
        // Must still be empty — Recent Songs is auto-managed
        expect(controller.recentSongsPlaylist.songIds, isEmpty);
      },
    );

    test('removeFromPlaylist removes a song from a user playlist', () async {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [makeSong('s1'), makeSong('s2')],
      );
      addTearDown(() => controller.playerManager.dispose());

      await controller.createPlaylist('Test');
      final pid = controller.playlists.firstWhere((p) => !p.isSystem).id;
      await controller.addToPlaylist(
        makeSong('s1'),
        controller.getPlaylistById(pid)!,
      );
      await controller.addToPlaylist(
        makeSong('s2'),
        controller.getPlaylistById(pid)!,
      );

      await controller.removeFromPlaylist(
        makeSong('s1'),
        controller.getPlaylistById(pid)!,
      );
      expect(controller.getPlaylistById(pid)!.songIds, ['s2']);
    });

    test('removeFromPlaylist does nothing when song not in playlist', () async {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [makeSong('s1'), makeSong('s2')],
      );
      addTearDown(() => controller.playerManager.dispose());

      await controller.createPlaylist('Test');
      final pid = controller.playlists.firstWhere((p) => !p.isSystem).id;
      await controller.addToPlaylist(
        makeSong('s1'),
        controller.getPlaylistById(pid)!,
      );

      await controller.removeFromPlaylist(
        makeSong('s2'),
        controller.getPlaylistById(pid)!,
      );
      expect(controller.getPlaylistById(pid)!.songIds, ['s1']);
    });

    test(
      'removeFromPlaylist does nothing for system playlist (Recent Songs)',
      () async {
        final controller = MainController(
          stateService: StateService(),
          client: mockClient(),
          playerManager: PlayerManager(),
          localSongs: [makeSong('s1')],
        );
        addTearDown(() => controller.playerManager.dispose());

        final recent = controller.recentSongsPlaylist;
        // Directly add to Recent Songs to simulate tracked state
        // (normally only _addToRecentSongs does this)
        final idx = controller.playlists.indexOf(recent);
        controller.playlists[idx] = SavedPlaylist(
          id: recent.id,
          name: recent.name,
          songIds: ['s1'],
          isSystem: true,
        );

        await controller.removeFromPlaylist(
          makeSong('s1'),
          controller.recentSongsPlaylist,
        );
        expect(controller.recentSongsPlaylist.songIds, ['s1']); // unchanged
      },
    );

    test('renamePlaylist renames a user playlist', () async {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      await controller.createPlaylist('Old Name');
      final pid = controller.playlists.firstWhere((p) => !p.isSystem).id;

      await controller.renamePlaylist(pid, 'New Name');
      expect(controller.getPlaylistById(pid)!.name, 'New Name');
    });

    test('renamePlaylist does nothing for system playlist', () async {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      controller.libraryPlaylist; // ensure created
      await controller.renamePlaylist('library', 'My Music');
      expect(controller.libraryPlaylist.name, 'Library'); // unchanged
    });

    test('addToPlaylist uses live playlist not stale arg', () async {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [makeSong('a'), makeSong('b'), makeSong('c')],
      );
      addTearDown(() => controller.playerManager.dispose());

      await controller.createPlaylist('Test');
      final pid = controller.playlists.firstWhere((p) => !p.isSystem).id;
      final stale = SavedPlaylist(id: pid, name: 'Test', songIds: []);

      await controller.addToPlaylist(makeSong('a'), stale);
      expect(controller.getPlaylistById(pid)!.songIds, ['a']);

      await controller.addToPlaylist(makeSong('b'), stale);
      expect(controller.getPlaylistById(pid)!.songIds, ['a', 'b']);
    });

    test('removeFromPlaylist uses live playlist not stale arg', () async {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [makeSong('a'), makeSong('b'), makeSong('c')],
      );
      addTearDown(() => controller.playerManager.dispose());

      await controller.createPlaylist('Test');
      final pid = controller.playlists.firstWhere((p) => !p.isSystem).id;
      // Seed directly
      final idx = controller.playlists.indexWhere((p) => p.id == pid);
      controller.playlists[idx] = SavedPlaylist(
        id: pid,
        name: 'Test',
        songIds: ['a', 'b', 'c'],
      );
      final stale = SavedPlaylist(
        id: pid,
        name: 'Test',
        songIds: ['a', 'b', 'c'],
      );

      await controller.removeFromPlaylist(makeSong('a'), stale);
      expect(controller.getPlaylistById(pid)!.songIds, ['b', 'c']);

      await controller.removeFromPlaylist(makeSong('b'), stale);
      expect(controller.getPlaylistById(pid)!.songIds, ['c']);
    });

    test(
      'removeFromPlaylist does not resurrect previously removed songs',
      () async {
        final controller = MainController(
          stateService: StateService(),
          client: mockClient(),
          playerManager: PlayerManager(),
          localSongs: [makeSong('a'), makeSong('b'), makeSong('c')],
        );
        addTearDown(() => controller.playerManager.dispose());

        await controller.createPlaylist('Test');
        final pid = controller.playlists.firstWhere((p) => !p.isSystem).id;
        final idx = controller.playlists.indexWhere((p) => p.id == pid);
        controller.playlists[idx] = SavedPlaylist(
          id: pid,
          name: 'Test',
          songIds: ['a', 'b', 'c'],
        );
        final stale = SavedPlaylist(
          id: pid,
          name: 'Test',
          songIds: ['a', 'b', 'c'],
        );

        await controller.removeFromPlaylist(makeSong('a'), stale);
        await controller.removeFromPlaylist(makeSong('b'), stale);
        expect(controller.getPlaylistById(pid)!.songIds, ['c']);
        expect(controller.getPlaylistById(pid)!.songIds.contains('a'), isFalse);
      },
    );
  });

  group('MainController toggleSongInLibrary', () {
    setUp(() {});

    // Use a real SongResponse-like minimal stub
    // We'll test logic via toggleCurrentInLibrary which uses Song
  });

  group('MainController toggleCurrentInLibrary', () {
    setUp(() {});

    test(
      'removes from library and queue when playing with more songs',
      () async {
        final controller = MainController(
          stateService: StateService(),
          client: mockClient(),
          playerManager: PlayerManager(),
          localSongs: [Song(id: '1', name: 'Song A', filePath: '')],
        );
        addTearDown(() => controller.playerManager.dispose());

        // Seed into Library playlist
        final lib = controller.libraryPlaylist;
        controller.playlists[controller.playlists.indexOf(lib)] = SavedPlaylist(
          id: lib.id,
          name: lib.name,
          songIds: ['1'],
          isSystem: true,
        );

        controller.playerManager.setQueue([
          Song(id: '1', name: 'Song A', filePath: ''),
          Song(id: '2', name: 'Song B', filePath: ''),
        ], songId: '1');

        await controller.toggleCurrentInLibrary();

        expect(controller.isSongInLibrary('1'), isFalse);
        expect(controller.playerManager.queueManager.getIndexById('1'), -1);
      },
    );

    test('removes from library but does not advance when paused', () async {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [Song(id: '1', name: 'Song A', filePath: '')],
      );
      addTearDown(() => controller.playerManager.dispose());

      final lib = controller.libraryPlaylist;
      controller.playlists[controller.playlists.indexOf(lib)] = SavedPlaylist(
        id: lib.id,
        name: lib.name,
        songIds: ['1'],
        isSystem: true,
      );

      controller.playerManager.setQueue([
        Song(id: '1', name: 'Song A', filePath: ''),
        Song(id: '2', name: 'Song B', filePath: ''),
      ], songId: '1');
      expect(controller.playerManager.isPlaying, isFalse);

      await controller.toggleCurrentInLibrary();

      expect(controller.isSongInLibrary('1'), isFalse);
      expect(controller.playerManager.queueManager.getIndexById('1'), -1);
      expect(controller.playerManager.currentPlaying, isNull);
    });

    test('removes from library and stops when last song in queue', () async {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [Song(id: '1', name: 'Song A', filePath: '')],
      );
      addTearDown(() => controller.playerManager.dispose());

      final lib = controller.libraryPlaylist;
      controller.playlists[controller.playlists.indexOf(lib)] = SavedPlaylist(
        id: lib.id,
        name: lib.name,
        songIds: ['1'],
        isSystem: true,
      );

      controller.playerManager.setQueue([
        Song(id: '1', name: 'Song A', filePath: ''),
      ], songId: '1');

      await controller.toggleCurrentInLibrary();

      expect(controller.isSongInLibrary('1'), isFalse);
      expect(controller.playerManager.currentPlaying, isNull);
      expect(controller.playerManager.queueManager.length, 0);
    });

    test('does nothing when no song is playing', () async {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      await controller.toggleCurrentInLibrary();
      // No crash — test passes
    });

    test('adds song to library when not already there', () async {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      controller.playerManager.updateCurrentPlaying(
        Song(
          id: 'newSong',
          name: 'New Song',
          primaryArtists: 'Artist',
          filePath: '',
        ),
      );

      await controller.toggleCurrentInLibrary();

      expect(controller.isSongInLibrary('newSong'), isTrue);
      expect(controller.localSongs.any((d) => d.id == 'newSong'), isTrue);
    });
  });

  group('MainController toggleLocalSongInLibrary', () {
    setUp(() {});

    test('adds local song to library when not already there', () async {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [Song(id: 's1', name: 'S1', filePath: '')],
      );
      addTearDown(() => controller.playerManager.dispose());

      await controller.toggleLocalSongInLibrary(
        Song(id: 's2', name: 'S2', filePath: ''),
      );

      expect(controller.isSongInLibrary('s2'), isTrue);
      expect(controller.localSongs.any((d) => d.id == 's2'), isTrue);
    });

    test('removes local song from library when already there', () async {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [Song(id: 's1', name: 'S1', filePath: '')],
      );
      addTearDown(() => controller.playerManager.dispose());

      final lib = controller.libraryPlaylist;
      controller.playlists[controller.playlists.indexOf(lib)] = SavedPlaylist(
        id: lib.id,
        name: lib.name,
        songIds: ['s1'],
        isSystem: true,
      );

      await controller.toggleLocalSongInLibrary(
        Song(id: 's1', name: 'S1', filePath: ''),
      );

      expect(controller.isSongInLibrary('s1'), isFalse);
    });

    test('no-ops for null-like song without crashing', () async {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      await controller.toggleLocalSongInLibrary(
        Song(id: '', name: '', filePath: ''),
      );
      // passes if no exception thrown
    });
  });

  group('Recent Songs tracking', () {
    setUp(() {});

    /// Trigger Recent Songs tracking via onSongChanged callback.
    void playSong(
      MainController controller,
      String id,
      String title,
      String artist,
    ) {
      final info = Song(id: id, name: title, primaryArtists: artist);
      controller.playerManager.updateCurrentPlaying(info);
    }

    test('plays song appears in Recent Songs', () {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      playSong(controller, 's1', 'Song 1', 'Artist 1');

      final recent = controller.recentSongsPlaylist;
      expect(recent.songIds, ['s1']);
      // Song metadata added to localSongs for display
      expect(controller.localSongs.any((d) => d.id == 's1'), isTrue);
    });

    test('replaying song moves it to front of Recent Songs', () {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      playSong(controller, 's1', 'Song 1', 'A');
      playSong(controller, 's2', 'Song 2', 'B');
      playSong(controller, 's1', 'Song 1', 'A');

      final recent = controller.recentSongsPlaylist;
      expect(recent.songIds, ['s1', 's2']); // s1 moved to front
    });

    test('Recent Songs evicts oldest when over cap', () {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      // Fill to cap (50) then add one more
      for (var i = 0; i < 51; i++) {
        playSong(controller, 's$i', 'Song $i', 'Artist');
      }

      final recent = controller.recentSongsPlaylist;
      expect(recent.songIds.length, 50);
      expect(recent.songIds[0], 's50'); // newest at front
      expect(recent.songIds.contains('s0'), isFalse); // oldest evicted
    });
  });

  group('MainController searchPlaylist', () {
    setUp(() {});

    test('filters songs by name', () {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [
          Song(
            id: '1',
            name: 'Alpha',
            primaryArtists: 'A',
            album: 'X',
            filePath: '',
          ),
          Song(
            id: '2',
            name: 'Beta',
            primaryArtists: 'B',
            album: 'Y',
            filePath: '',
          ),
        ],
      );
      addTearDown(() => controller.playerManager.dispose());

      final playlist = SavedPlaylist(
        id: 'pl1',
        name: 'Test',
        songIds: ['1', '2'],
      );

      final result = controller.searchPlaylist(playlist, 'alp');
      expect(result.map((s) => s.id), ['1']);
    });

    test('matches artist and album', () {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [
          Song(
            id: '1',
            name: 'Song',
            primaryArtists: 'Beatles',
            album: 'Abbey',
            filePath: '',
          ),
          Song(
            id: '2',
            name: 'Song',
            primaryArtists: 'Elvis',
            album: 'Hall',
            filePath: '',
          ),
        ],
      );
      addTearDown(() => controller.playerManager.dispose());

      final playlist = SavedPlaylist(
        id: 'pl1',
        name: 'Test',
        songIds: ['1', '2'],
      );

      expect(controller.searchPlaylist(playlist, 'beat').map((s) => s.id), [
        '1',
      ]);
      expect(controller.searchPlaylist(playlist, 'abb').map((s) => s.id), [
        '1',
      ]);
      expect(controller.searchPlaylist(playlist, 'hall').map((s) => s.id), [
        '2',
      ]);
    });

    test('returns empty when no match', () {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [
          Song(
            id: '1',
            name: 'Song',
            primaryArtists: 'A',
            album: 'X',
            filePath: '',
          ),
        ],
      );
      addTearDown(() => controller.playerManager.dispose());

      final playlist = SavedPlaylist(id: 'pl1', name: 'Test', songIds: ['1']);

      expect(controller.searchPlaylist(playlist, 'zzz'), isEmpty);
    });
  });

  group('MainController callbacks', () {
    setUp(() {});

    test('onLibraryChanged callback is nullable', () {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      controller.onLibraryChanged = null;
      expect(controller.onLibraryChanged, isNull);
    });

    test('onCurrentPlayingChanged setter accepts null', () {
      final controller = MainController(
        stateService: StateService(),
        client: mockClient(),
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      // Should not throw
      controller.onCurrentPlayingChanged = null;
    });
  });
}
