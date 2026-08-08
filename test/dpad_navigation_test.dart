import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:altune/widgets/app_back_button.dart';
import 'package:altune/widgets/pill_button.dart';
import 'package:altune/widgets/song_list_item.dart';
import 'package:altune/widgets/sidebar_player.dart';
import 'package:altune/widgets/artwork_image.dart';
import 'package:altune/services/player_manager.dart';
import 'package:altune/models/song_list_item_data.dart';
import 'package:altune/models/song.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppBackButton', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppBackButton(onPressed: () => pressed = true)),
        ),
      );

      await tester.tap(find.byType(AppBackButton));
      expect(pressed, isTrue);
    });
  });

  group('PillButton', () {
    testWidgets('calls onTap when pressed', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PillButton(
              icon: Icons.music_note,
              label: 'Songs',
              onTap: () => tapped = true,
              isSelected: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PillButton));
      expect(tapped, isTrue);
    });
  });

  group('SongListItem', () {
    final testSong = SongListItemData(
      id: '1',
      name: 'Test Song',
      primaryArtists: 'Test Artist',
      imageUrl: '',
    );

    testWidgets('calls onTap when pressed', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SongListItem(
                song: testSong,
                onTap: () => tapped = true,
                onMenuTap: () {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SongListItem));
      expect(tapped, isTrue);
    });

    testWidgets('calls onMenuTap when menu pressed', (tester) async {
      bool menuTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SongListItem(
                song: testSong,
                onTap: () {},
                onMenuTap: () => menuTapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      expect(menuTapped, isTrue);
    });

    testWidgets('calls onMenuTap on right click', (tester) async {
      bool menuTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SongListItem(
                song: testSong,
                onTap: () {},
                onMenuTap: () => menuTapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SongListItem), buttons: 2);
      expect(menuTapped, isTrue);
    });
  });

  group('SidebarPlayer', () {
    Widget buildSidebarPlayer({
      required PlayerManager playerManager,
      VoidCallback? onPlayPause,
      VoidCallback? onSkipPrevious,
      VoidCallback? onSkipNext,
      VoidCallback? onTap,
      VoidCallback? onToggleLibrary,
      bool Function(String)? isSongInLibrary,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SidebarPlayer(
            playerManager: playerManager,
            onPlayPause: onPlayPause ?? () {},
            onSkipPrevious: onSkipPrevious ?? () {},
            onSkipNext: onSkipNext ?? () {},
            onTap: onTap ?? () {},
            onToggleLibrary: onToggleLibrary,
            isSongInLibrary: isSongInLibrary,
          ),
        ),
      );
    }

    testWidgets('play pause callback fires', (tester) async {
      final pm = PlayerManager();
      addTearDown(() => pm.dispose());
      pm.updateCurrentPlaying(
        Song(id: '1', name: 'Test Song', primaryArtists: 'Test Artist'),
      );
      bool toggled = false;

      await tester.pumpWidget(
        buildSidebarPlayer(
          playerManager: pm,
          onPlayPause: () => toggled = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.play_circle_filled));
      expect(toggled, isTrue);
    });

    testWidgets('skip previous callback fires', (tester) async {
      final pm = PlayerManager();
      addTearDown(() => pm.dispose());
      pm.updateCurrentPlaying(
        Song(id: '1', name: 'Test Song', primaryArtists: 'Test Artist'),
      );
      bool skipped = false;

      await tester.pumpWidget(
        buildSidebarPlayer(
          playerManager: pm,
          onSkipPrevious: () => skipped = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.skip_previous));
      expect(skipped, isTrue);
    });

    testWidgets('skip next callback fires', (tester) async {
      final pm = PlayerManager();
      addTearDown(() => pm.dispose());
      pm.updateCurrentPlaying(
        Song(id: '1', name: 'Test Song', primaryArtists: 'Test Artist'),
      );
      bool skipped = false;

      await tester.pumpWidget(
        buildSidebarPlayer(playerManager: pm, onSkipNext: () => skipped = true),
      );

      await tester.tap(find.byIcon(Icons.skip_next));
      expect(skipped, isTrue);
    });

    testWidgets('open player callback fires on artwork', (tester) async {
      final pm = PlayerManager();
      addTearDown(() => pm.dispose());
      pm.updateCurrentPlaying(
        Song(id: '1', name: 'Test Song', primaryArtists: 'Test Artist'),
      );
      bool opened = false;

      await tester.pumpWidget(
        buildSidebarPlayer(playerManager: pm, onTap: () => opened = true),
      );

      await tester.tap(find.byType(ArtworkImage));
      expect(opened, isTrue);
    });
  });
}
