import 'package:flutter_test/flutter_test.dart';
import "package:altune/models/song.dart";
import 'package:altune/models/saved_playlist.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Library songs filter', () {
    late List<Song> songs;

    setUp(() {
      songs = [
        Song(
          id: '1',
          name: 'Song A',
          primaryArtists: 'Artist One',
          album: 'Album X',
          filePath: '/path/1.mp3',
        ),
        Song(
          id: '2',
          name: 'Song B',
          primaryArtists: 'Artist Two',
          album: 'Album Y',
          filePath: '/path/2.mp3',
        ),
        Song(
          id: '3',
          name: 'Other Track',
          primaryArtists: 'Another Artist',
          album: 'Another Album',
          filePath: '/path/3.mp3',
        ),
        Song(
          id: '4',
          name: 'Hello World',
          primaryArtists: 'Greeter',
          album: 'Greetings',
          filePath: '/path/4.mp3',
        ),
      ];
    });

    test('filter by name returns matching songs', () {
      final query = 'song';
      final result = songs
          .where((s) => (s.name ?? '').toLowerCase().contains(query))
          .toList();

      expect(result.length, 2);
      expect(result.map((s) => s.id), containsAll(['1', '2']));
    });

    test('filter by artist returns matching songs', () {
      final query = 'artist';
      final result = songs
          .where((s) => (s.primaryArtists ?? '').toLowerCase().contains(query))
          .toList();

      expect(result.length, 3);
      expect(result.map((s) => s.id), containsAll(['1', '2', '3']));
    });

    test('filter by album returns matching songs', () {
      final query = 'album x';
      final result = songs
          .where((s) => (s.album ?? '').toLowerCase().contains(query))
          .toList();

      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('filter matches across name, artist, and album', () {
      final query = 'other';
      final result = songs
          .where(
            (s) =>
                (s.name ?? '').toLowerCase().contains(query) ||
                (s.primaryArtists ?? '').toLowerCase().contains(query) ||
                (s.album ?? '').toLowerCase().contains(query),
          )
          .toList();

      expect(result.length, 1);
      expect(result.first.id, '3');
    });

    test('filter is case-insensitive', () {
      final resultLower = songs
          .where(
            (s) => (s.name ?? '').toLowerCase().contains('hello'.toLowerCase()),
          )
          .toList();
      expect(resultLower.length, 1);
      expect(resultLower.first.id, '4');

      final resultUpper = songs
          .where(
            (s) => (s.name ?? '').toLowerCase().contains('HELLO'.toLowerCase()),
          )
          .toList();
      expect(resultUpper.length, 1);
      expect(resultUpper.first.id, '4');
    });

    test('empty query returns all songs', () {
      final query = '';
      final result = songs
          .where(
            (s) =>
                query.isEmpty ||
                (s.name ?? '').toLowerCase().contains(query) ||
                (s.primaryArtists ?? '').toLowerCase().contains(query) ||
                (s.album ?? '').toLowerCase().contains(query),
          )
          .toList();

      expect(result.length, 4);
    });

    test('filter returns empty list when no match', () {
      final query = 'zzzzz';
      final result = songs
          .where(
            (s) =>
                (s.name ?? '').toLowerCase().contains(query) ||
                (s.primaryArtists ?? '').toLowerCase().contains(query) ||
                (s.album ?? '').toLowerCase().contains(query),
          )
          .toList();

      expect(result, isEmpty);
    });

    test('filter handles null name gracefully', () {
      final songsWithNull = [
        Song(id: 'n1', name: null, filePath: '/p1.mp3'),
        Song(id: 'n2', name: 'Valid', filePath: '/p2.mp3'),
      ];

      final query = 'valid';
      final result = songsWithNull
          .where(
            (s) =>
                (s.name ?? '').toLowerCase().contains(query) ||
                (s.primaryArtists ?? '').toLowerCase().contains(query) ||
                (s.album ?? '').toLowerCase().contains(query),
          )
          .toList();

      expect(result.length, 1);
      expect(result.first.id, 'n2');
    });

    test('filter handles null artist gracefully', () {
      final songsWithNull = [
        Song(id: 'n1', name: 'Test', primaryArtists: null, filePath: '/p1.mp3'),
      ];

      final query = 'test';
      final result = songsWithNull
          .where(
            (s) =>
                (s.name ?? '').toLowerCase().contains(query) ||
                (s.primaryArtists ?? '').toLowerCase().contains(query) ||
                (s.album ?? '').toLowerCase().contains(query),
          )
          .toList();

      expect(result.length, 1);
      expect(result.first.id, 'n1');
    });

    test('filter handles null album gracefully', () {
      final songsWithNull = [
        Song(
          id: 'n1',
          name: 'Test',
          primaryArtists: null,
          album: null,
          filePath: '/p1.mp3',
        ),
      ];

      final query = 'test';
      final result = songsWithNull
          .where(
            (s) =>
                (s.name ?? '').toLowerCase().contains(query) ||
                (s.primaryArtists ?? '').toLowerCase().contains(query) ||
                (s.album ?? '').toLowerCase().contains(query),
          )
          .toList();

      expect(result.length, 1);
    });
  });

  group('Library playlists filter', () {
    late List<SavedPlaylist> playlists;

    setUp(() {
      playlists = [
        SavedPlaylist(id: '1', name: 'Favorites'),
        SavedPlaylist(id: '2', name: 'Workout Mix'),
        SavedPlaylist(id: '3', name: 'Chill Vibes'),
      ];
    });

    test('filter by name returns matching playlists', () {
      final query = 'fav';
      final result = playlists
          .where((p) => p.name.toLowerCase().contains(query))
          .toList();

      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('filter is case-insensitive for playlists', () {
      final query = 'FAVORITES';
      final result = playlists
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();

      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('empty query returns all playlists', () {
      final query = '';
      final result = playlists
          .where((p) => query.isEmpty || p.name.toLowerCase().contains(query))
          .toList();

      expect(result.length, 3);
    });

    test('filter returns empty list when no playlist matches', () {
      final query = 'zzzzz';
      final result = playlists
          .where((p) => p.name.toLowerCase().contains(query))
          .toList();

      expect(result, isEmpty);
    });

    test('filter matches partial words in playlist name', () {
      final query = 'work';
      final result = playlists
          .where((p) => p.name.toLowerCase().contains(query))
          .toList();

      expect(result.length, 1);
      expect(result.first.id, '2');
    });
  });

  group('Library combined filter and sort', () {
    test('filtered songs can be sorted by name', () {
      final songs = [
        Song(id: '3', name: 'Zebra Song', filePath: '/p3.mp3'),
        Song(id: '1', name: 'Apple Song', filePath: '/p1.mp3'),
        Song(id: '2', name: 'Mango Song', filePath: '/p2.mp3'),
      ];

      const query = 'song';
      var filtered = songs
          .where((s) => (s.name ?? '').toLowerCase().contains(query))
          .toList();
      filtered.sort(
        (a, b) => (a.name ?? '').toLowerCase().compareTo(
          (b.name ?? '').toLowerCase(),
        ),
      );

      expect(filtered.map((s) => s.id), ['1', '2', '3']);
    });
  });
}
