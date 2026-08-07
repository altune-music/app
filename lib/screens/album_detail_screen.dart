import 'package:flutter/material.dart';
import 'package:jiosaavn/jiosaavn.dart';
import '../controllers/main_controller.dart';
import '../../utils/image_quality_helper.dart';
import '../../utils/app_constants.dart';
import '../../utils/song_action_sheet.dart';
import '../utils/string_utils.dart';
import '../widgets/song_list_item.dart';
import '../widgets/tablet_sidebar.dart';
import '../models/song_list_item_data.dart';
import '../widgets/app_back_button.dart';
import '../widgets/player_kebab_menu.dart';
import 'player_screen.dart';

class AlbumDetailScreen extends StatefulWidget {
  final MainController controller;
  final AlbumResponse album;
  final ValueChanged<int>? onNavigationChanged;
  final bool showSidebar;
  final bool showScaffold;

  const AlbumDetailScreen({
    super.key,
    required this.controller,
    required this.album,
    this.onNavigationChanged,
    this.showSidebar = true,
    this.showScaffold = true,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  late Future<AlbumResponse> _albumDetailsFuture;

  @override
  void initState() {
    super.initState();
    _albumDetailsFuture = widget.controller.getAlbumDetails(
      widget.album.id,
      fallback: widget.album,
    );
  }

  void _showSongActions(
    BuildContext context,
    SongResponse song,
    List<SongResponse> albumSongs,
  ) {
    showSongActionSheet(
      context,
      song,
      widget.controller,
      onToggleLibrary: () => widget.controller.toggleSongInLibrary(song),
    );
  }

  Future<void> _playSong(SongResponse song) async {
    await widget.controller.streamSong(song);
  }

  Future<void> _playAlbum(
    SongResponse song,
    List<SongResponse> albumSongs,
  ) async {
    await widget.controller.streamSongAndQueueAlbum(song, albumSongs);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= AppConstants.tabletMinWidthDp;
    final imageSize = isTablet ? 180.0 : 120.0;

    if (isTablet && widget.showSidebar) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabletSidebar(
              selectedIndex: 1,
              onItemSelected: (index) {
                widget.onNavigationChanged?.call(index);
              },
              playerManager: widget.controller.playerManager,
              onPlayPause: () {
                if (widget.controller.playerManager.isPlaying) {
                  widget.controller.playerManager.pause();
                } else {
                  widget.controller.playerManager.playCurrent();
                }
              },
              onOpenPlayer: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlayerScreen(
                      playerManager: widget.controller.playerManager,
                      onOpenQueue: () {},
                      onSkipPrevious: () => widget.controller.skipToPrevious(),
                      onSkipNext: () => widget.controller.skipToNext(),
                      onKebabTap: () {
                        final info =
                            widget.controller.playerManager.currentPlaying;
                        if (info == null) return;
                        showModalBottomSheet(
                          context: context,
                          builder: (ctx) => PlayerKebabMenu(
                            playerManager: widget.controller.playerManager,
                            controller: widget.controller,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              onToggleLibrary: () => widget.controller.toggleCurrentInLibrary(),
              isSongInLibrary: (id) => widget.controller.isSongInLibrary(id),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: SafeArea(child: _buildAlbumDetails(imageSize))),
          ],
        ),
      );
    }

    if (!widget.showScaffold) {
      return _buildAlbumDetails(imageSize);
    }

    return Scaffold(body: SafeArea(child: _buildAlbumDetails(imageSize)));
  }

  Widget _buildAlbumDetails(double imageSize) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= AppConstants.tabletMinWidthDp;
    final largeImageSize = isTablet ? 300.0 : 200.0;

    return FutureBuilder<AlbumResponse>(
      future: _albumDetailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Failed to load album details.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final album = snapshot.data!;
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: false,
              leading: AppBackButton(
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: largeImageSize,
                        height: largeImageSize,
                        child: album.image?.isNotEmpty == true
                            ? Image.network(
                                ImageQualityHelper.getLargeImageUrl(
                                  album.image,
                                )!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                child: const Icon(Icons.album, size: 48),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      cleanString(album.name),
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      buildAlbumSubtitle(album.year, album.primaryArtistsId),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    if (album.explicitContent == '1')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'EXPLICIT',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: album.songs.isEmpty
                            ? null
                            : () => _playAlbum(album.songs.first, album.songs),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play Album'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (album.songs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Song details unavailable for this album.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = album.songs[index];
                  return SongListItem(
                    song: SongListItemData(
                      id: song.id,
                      name: cleanString(song.name),
                      primaryArtists: cleanString(song.primaryArtists),
                      imageUrl:
                          ImageQualityHelper.getSmallImageUrl(song.image) ?? '',
                    ),
                    onTap: () => _playSong(song),
                    onMenuTap: () =>
                        _showSongActions(context, song, album.songs),
                  );
                }, childCount: album.songs.length),
              ),
            if (!isTablet)
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 60,
                ),
              ),
          ],
        );
      },
    );
  }
}
