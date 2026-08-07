import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:altune/widgets/playlist_picker_content.dart';
import 'package:altune/models/saved_playlist.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PlaylistPickerContent shows only selectable playlists', (
    tester,
  ) async {
    final playlists = [
      SavedPlaylist(id: '1', name: 'Playlist A', songIds: []),
      SavedPlaylist(id: '2', name: 'Playlist B', songIds: []),
    ];

    var selectedPlaylist = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaylistPickerContent(
            playlists: playlists,
            onSelectPlaylist: (p) => selectedPlaylist = p.name,
          ),
        ),
      ),
    );

    // Should not have a create-new-playlist tile
    expect(find.text('Create new playlist'), findsNothing);

    // Should show the two playlists
    expect(find.text('Playlist A'), findsOneWidget);
    expect(find.text('Playlist B'), findsOneWidget);

    // Tapping a playlist calls onSelectPlaylist
    await tester.tap(find.text('Playlist B'));
    await tester.pumpAndSettle();
    expect(selectedPlaylist, 'Playlist B');
  });

  testWidgets('PlaylistPickerContent filters out system playlists', (
    tester,
  ) async {
    final playlists = [
      SavedPlaylist(id: 'lib', name: 'Library', songIds: [], isSystem: true),
      SavedPlaylist(id: '1', name: 'My Playlist', songIds: []),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaylistPickerContent(
            playlists: playlists,
            onSelectPlaylist: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Library'), findsNothing);
    expect(find.text('My Playlist'), findsOneWidget);
  });
}
