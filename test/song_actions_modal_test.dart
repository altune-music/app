import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:altune/widgets/song_actions_modal.dart';
import 'package:altune/models/song.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SongActionsModal', () {
    Future<void> showModal(WidgetTester tester, SongActionsModal modal) {
      return tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(context: context, builder: (_) => modal);
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );
    }

    Future<void> openModal(WidgetTester tester) async {
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('shows bitrate when song.bitrate provided', (tester) async {
      await showModal(
        tester,
        SongActionsModal(
          song: Song(
            id: '1',
            name: 'Test Song',
            primaryArtists: 'Test Artist',
            bitrate: '320kbps',
          ),
          onPlay: () {},
        ),
      );
      await openModal(tester);

      expect(find.text('Test Artist'), findsOneWidget);
      expect(find.text('320kbps'), findsOneWidget);
    });

    testWidgets('shows year when song.year provided', (tester) async {
      await showModal(
        tester,
        SongActionsModal(
          song: Song(
            id: '1',
            name: 'Test Song',
            primaryArtists: 'Test Artist',
            album: 'Test Album',
            year: '2023',
          ),
          onPlay: () {},
        ),
      );
      await openModal(tester);

      expect(find.text('Test Artist'), findsOneWidget);
      expect(find.text('Test Album'), findsOneWidget);
      expect(find.text('2023'), findsOneWidget);
    });

    testWidgets('does not show year when null', (tester) async {
      await showModal(
        tester,
        SongActionsModal(
          song: Song(
            id: '1',
            name: 'Test Song',
            primaryArtists: 'Test Artist',
            album: 'Test Album',
          ),
          onPlay: () {},
        ),
      );
      await openModal(tester);

      expect(find.text('Test Artist'), findsOneWidget);
      expect(find.text('Test Album'), findsOneWidget);
      expect(find.text('2023'), findsNothing);
    });

    testWidgets('shows Play always', (tester) async {
      await showModal(
        tester,
        SongActionsModal(
          song: Song(id: '1', name: 'Test Song', primaryArtists: 'Test Artist'),
          onPlay: () {},
        ),
      );
      await openModal(tester);

      expect(find.text('Test Song'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('shows Play Next when callback provided', (tester) async {
      await showModal(
        tester,
        SongActionsModal(
          song: Song(id: '1', name: 'Test Song', primaryArtists: 'Test Artist'),
          onPlay: () {},
          onPlayNext: () {},
        ),
      );
      await openModal(tester);

      expect(find.text('Play Next'), findsOneWidget);
      expect(find.byIcon(Icons.queue_music), findsOneWidget);
    });

    testWidgets('does not show Play Next when callback omitted', (
      tester,
    ) async {
      await showModal(
        tester,
        SongActionsModal(
          song: Song(id: '1', name: 'Test Song', primaryArtists: 'Test Artist'),
          onPlay: () {},
        ),
      );
      await openModal(tester);

      expect(find.text('Play Next'), findsNothing);
    });

    testWidgets('shows Add to Queue when callback provided', (tester) async {
      await showModal(
        tester,
        SongActionsModal(
          song: Song(id: '1', name: 'Test Song', primaryArtists: 'Test Artist'),
          onPlay: () {},
          onAddToQueue: () {},
        ),
      );
      await openModal(tester);

      expect(find.text('Add to Queue'), findsOneWidget);
      expect(find.byIcon(Icons.queue_play_next), findsOneWidget);
    });

    testWidgets(
      'shows Add to Playlist when callback provided without Remove from Playlist',
      (tester) async {
        await showModal(
          tester,
          SongActionsModal(
            song: Song(
              id: '1',
              name: 'Test Song',
              primaryArtists: 'Test Artist',
            ),
            onPlay: () {},
            onAddToPlaylist: () {},
          ),
        );
        await openModal(tester);

        expect(find.text('Add to Playlist'), findsOneWidget);
        expect(find.byIcon(Icons.playlist_add), findsOneWidget);
      },
    );

    testWidgets('shows Remove from Playlist when callback provided', (
      tester,
    ) async {
      await showModal(
        tester,
        SongActionsModal(
          song: Song(id: '1', name: 'Test Song', primaryArtists: 'Test Artist'),
          onPlay: () {},
          onRemoveFromPlaylist: () {},
        ),
      );
      await openModal(tester);

      expect(find.text('Remove from Playlist'), findsOneWidget);
      expect(find.byIcon(Icons.playlist_remove), findsOneWidget);
    });

    testWidgets(
      'does not show Add to Playlist when Remove from Playlist is provided',
      (tester) async {
        await showModal(
          tester,
          SongActionsModal(
            song: Song(
              id: '1',
              name: 'Test Song',
              primaryArtists: 'Test Artist',
            ),
            onPlay: () {},
            onAddToPlaylist: () {},
            onRemoveFromPlaylist: () {},
          ),
        );
        await openModal(tester);

        expect(find.text('Add to Playlist'), findsNothing);
        expect(find.text('Remove from Playlist'), findsOneWidget);
      },
    );

    testWidgets(
      'shows Add to Library when not in library and onToggleLibrary provided',
      (tester) async {
        await showModal(
          tester,
          SongActionsModal(
            song: Song(
              id: '1',
              name: 'Test Song',
              primaryArtists: 'Test Artist',
            ),
            isInLibrary: false,
            onPlay: () {},
            onToggleLibrary: () {},
          ),
        );
        await openModal(tester);

        expect(find.text('Add to Library'), findsOneWidget);
        expect(find.byIcon(Icons.library_add_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'shows Remove from Library when in library and onRemoveFromLibrary provided',
      (tester) async {
        await showModal(
          tester,
          SongActionsModal(
            song: Song(
              id: '1',
              name: 'Test Song',
              primaryArtists: 'Test Artist',
            ),
            isInLibrary: true,
            onPlay: () {},
            onRemoveFromLibrary: () {},
          ),
        );
        await openModal(tester);

        expect(find.text('Remove from Library'), findsOneWidget);
        expect(find.byIcon(Icons.library_add_check), findsOneWidget);
      },
    );

    testWidgets(
      'shows Remove from Library when in library and onToggleLibrary provided',
      (tester) async {
        await showModal(
          tester,
          SongActionsModal(
            song: Song(
              id: '1',
              name: 'Test Song',
              primaryArtists: 'Test Artist',
            ),
            isInLibrary: true,
            onPlay: () {},
            onToggleLibrary: () {},
          ),
        );
        await openModal(tester);

        expect(find.text('Remove from Library'), findsOneWidget);
        expect(find.byIcon(Icons.library_add_check), findsOneWidget);
      },
    );

    testWidgets('does not show library action when no callback provided', (
      tester,
    ) async {
      await showModal(
        tester,
        SongActionsModal(
          song: Song(id: '1', name: 'Test Song', primaryArtists: 'Test Artist'),
          onPlay: () {},
        ),
      );
      await openModal(tester);

      expect(find.text('Add to Library'), findsNothing);
      expect(find.text('Remove from Library'), findsNothing);
    });

    testWidgets('calls onPlay callback when Play is tapped', (tester) async {
      bool played = false;
      await showModal(
        tester,
        SongActionsModal(
          song: Song(id: '1', name: 'Test Song', primaryArtists: 'Test Artist'),
          onPlay: () => played = true,
        ),
      );
      await openModal(tester);

      await tester.tap(find.text('Play'));
      expect(played, isTrue);
    });

    testWidgets('calls onPlayNext when Play Next is tapped', (tester) async {
      bool called = false;
      await showModal(
        tester,
        SongActionsModal(
          song: Song(id: '1', name: 'Test Song', primaryArtists: 'Test Artist'),
          onPlay: () {},
          onPlayNext: () => called = true,
        ),
      );
      await openModal(tester);

      await tester.tap(find.text('Play Next'));
      expect(called, isTrue);
    });

    testWidgets('calls onAddToQueue when Add to Queue is tapped', (
      tester,
    ) async {
      bool called = false;
      await showModal(
        tester,
        SongActionsModal(
          song: Song(id: '1', name: 'Test Song', primaryArtists: 'Test Artist'),
          onPlay: () {},
          onAddToQueue: () => called = true,
        ),
      );
      await openModal(tester);

      await tester.tap(find.text('Add to Queue'));
      expect(called, isTrue);
    });

    testWidgets('calls onToggleLibrary when Add to Library is tapped', (
      tester,
    ) async {
      bool called = false;
      await showModal(
        tester,
        SongActionsModal(
          song: Song(id: '1', name: 'Test Song', primaryArtists: 'Test Artist'),
          isInLibrary: false,
          onPlay: () {},
          onToggleLibrary: () => called = true,
        ),
      );
      await openModal(tester);

      await tester.tap(find.text('Add to Library'));
      expect(called, isTrue);
    });
  });
}
