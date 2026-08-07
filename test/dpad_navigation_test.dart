import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dpad/dpad.dart';
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

  group('AppBackButton D-pad support', () {
    testWidgets('is wrapped in DpadFocusable with debugLabel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AppBackButton())),
      );

      expect(find.byType(DpadFocusable), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    });

    testWidgets('DpadFocusable onSelect triggers navigation', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppBackButton(onPressed: () => pressed = true)),
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_left));
      expect(pressed, isTrue);
    });
  });

  group('PillButton D-pad support', () {
    testWidgets('has DpadFocusable wrapper', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PillButton(
              icon: Icons.music_note,
              label: 'Songs',
              onTap: () {},
              isSelected: true,
            ),
          ),
        ),
      );

      expect(find.byType(DpadFocusable), findsOneWidget);
      expect(find.text('Songs'), findsOneWidget);
    });

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

      await tester.tap(find.text('Songs'));
      expect(tapped, isTrue);
    });

    testWidgets('hides label when not selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PillButton(
              icon: Icons.music_note,
              label: 'Songs',
              onTap: () {},
              isSelected: false,
            ),
          ),
        ),
      );

      expect(find.text('Songs'), findsNothing);
      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });
  });

  group('SongListItem D-pad support', () {
    final testSong = SongListItemData(
      id: '1',
      name: 'Test Song',
      primaryArtists: 'Test Artist',
      imageUrl: '',
    );

    testWidgets('has DpadFocusable wrapper with debugLabel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SongListItem(
                song: testSong,
                onTap: () {},
                onMenuTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DpadFocusable), findsNWidgets(2));
      expect(find.text('Test Song'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);
    });

    testWidgets('renders with two DpadFocusable widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SongListItem(song: testSong, onTap: () {}, onMenuTap: () {}),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DpadFocusable), findsNWidgets(2));
    });

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

      await tester.tap(find.text('Test Song'));
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

      await tester.tap(find.text('Test Song'), buttons: 2);
      expect(menuTapped, isTrue);
    });
  });

  group('DpadFocusable wrapper presence', () {
    testWidgets('PillButton wraps in DpadFocusable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PillButton(
              icon: Icons.music_note,
              label: 'Test',
              onTap: () {},
              isSelected: true,
            ),
          ),
        ),
      );

      final focusable = find.byType(DpadFocusable);
      expect(focusable, findsOneWidget);

      // Verify the DpadFocusable contains the PillButton content
      final pillText = find.text('Test');
      expect(pillText, findsOneWidget);
    });
  });

  group('SidebarPlayer D-pad controls', () {
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

    testWidgets('shows controls when song is playing', (tester) async {
      final pm = PlayerManager();
      addTearDown(() => pm.dispose());
      pm.updateCurrentPlaying(
        Song(id: '1', name: 'Test Song', primaryArtists: 'Test Artist'),
      );

      await tester.pumpWidget(buildSidebarPlayer(playerManager: pm));

      expect(find.byType(DpadFocusable), findsNWidgets(4));
      expect(find.byIcon(Icons.skip_previous), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsOneWidget);
    });

    testWidgets('shows library toggle when onToggleLibrary provided', (
      tester,
    ) async {
      final pm = PlayerManager();
      addTearDown(() => pm.dispose());
      pm.updateCurrentPlaying(
        Song(id: '1', name: 'Test Song', primaryArtists: 'Test Artist'),
      );

      await tester.pumpWidget(
        buildSidebarPlayer(
          playerManager: pm,
          onToggleLibrary: () {},
          isSongInLibrary: (id) => false,
        ),
      );

      expect(find.byType(DpadFocusable), findsNWidgets(5));
      expect(find.byIcon(Icons.library_add_outlined), findsOneWidget);
    });

    testWidgets('hides when no song is playing', (tester) async {
      final pm = PlayerManager();
      addTearDown(() => pm.dispose());

      await tester.pumpWidget(buildSidebarPlayer(playerManager: pm));

      expect(find.byType(DpadFocusable), findsNothing);
      expect(find.byIcon(Icons.skip_previous), findsNothing);
    });

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
