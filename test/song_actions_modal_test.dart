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
