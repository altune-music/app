import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dpad/dpad.dart';
import 'package:jiosaavn/jiosaavn.dart';
import '../../controllers/main_controller.dart';
import '../../models/song.dart';
import '../../models/saved_playlist.dart';
import '../../services/player_manager.dart';
import '../../services/player_ui_router.dart';
import '../../utils/app_constants.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/player_kebab_menu.dart';
import 'album_detail_screen.dart';
import 'library_screen.dart';
import 'player_screen.dart';
import 'playlist_detail_screen.dart';
import 'queue_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import '../widgets/tablet_sidebar.dart';

enum _Screen { library, search, albumDetail, playlistDetail, settings }

class LibraryHomeScreen extends StatefulWidget {
  final MainController controller;
  final PlayerManager playerManager;
  final Function(Song) onPlaySaved;
  final Function(SongResponse) onStreamSong;
  final Function(SongResponse) onAddToLibrary;
  final Function(Song) onRemoveFromLibrary;
  final Function(AlbumResponse)? onAlbumSelected;

  const LibraryHomeScreen({
    super.key,
    required this.controller,
    required this.playerManager,
    required this.onPlaySaved,
    required this.onStreamSong,
    required this.onAddToLibrary,
    required this.onRemoveFromLibrary,
    this.onAlbumSelected,
  });

  @override
  State<LibraryHomeScreen> createState() => _LibraryHomeScreenState();
}

class _LibraryHomeScreenState extends State<LibraryHomeScreen> {
  _Screen _screen = _Screen.library;
  AlbumResponse? _selectedAlbum;
  SavedPlaylist? _selectedPlaylist;

  @override
  void initState() {
    super.initState();
    widget.playerManager.addListener(_onPlayerManagerChanged);
    widget.controller.onLibraryChanged = () {
      if (mounted) setState(() {});
    };
    widget.controller.onCurrentPlayingChanged = () {
      if (mounted) setState(() {});
    };
    widget.controller.loadState();
  }

  @override
  void dispose() {
    widget.playerManager.removeListener(_onPlayerManagerChanged);
    widget.controller.onLibraryChanged = null;
    widget.controller.onCurrentPlayingChanged = null;
    super.dispose();
  }

  void _onPlayerManagerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= AppConstants.tabletMinWidthDp;
        return _buildLayout(isTablet: isTablet);
      },
    );
  }

  Widget _buildLayout({required bool isTablet}) {
    return Scaffold(
      appBar: !isTablet && _screen == _Screen.library
          ? AppBar(
              title: Row(
                children: [
                  SvgPicture.asset(
                    'assets/app_icon_logo.svg',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppConstants.appName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _screen = _Screen.search;
                    });
                  },
                  icon: const Icon(Icons.search),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _screen = _Screen.settings;
                    });
                  },
                  icon: const Icon(Icons.settings),
                ),
              ],
            )
          : null,
      body: isTablet
          ? PopScope(
              canPop: _screen == _Screen.library,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop) {
                  setState(() {
                    if (_screen == _Screen.albumDetail) {
                      _selectedAlbum = null;
                      _screen = _Screen.search;
                    } else if (_screen == _Screen.playlistDetail) {
                      _selectedPlaylist = null;
                      _screen = _Screen.library;
                    } else if (_screen == _Screen.search ||
                        _screen == _Screen.settings) {
                      _screen = _Screen.library;
                    }
                  });
                }
              },
              child: SafeArea(
                top: true,
                bottom: true,
                child: _buildTabletBody(),
              ),
            )
          : SafeArea(top: false, bottom: true, child: _buildMobileBody()),
    );
  }

  Widget _buildMobileBody() {
    final albumDetailWidget = _selectedAlbum != null
        ? AlbumDetailScreen(
            key: ValueKey(_selectedAlbum!.id),
            controller: widget.controller,
            album: _selectedAlbum!,
            showSidebar: false,
            showScaffold: false,
          )
        : const SizedBox.shrink();

    return PopScope(
      canPop: _screen == _Screen.library,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() {
            if (_screen == _Screen.search) {
              _screen = _Screen.library;
            } else if (_screen == _Screen.albumDetail) {
              _selectedAlbum = null;
              _screen = _Screen.search;
            } else if (_screen == _Screen.settings) {
              _screen = _Screen.library;
            }
          });
        }
      },
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _screen.index,
              children: [
                LibraryScreen(
                  controller: widget.controller,
                  onPlaySaved: widget.onPlaySaved,
                  onRemoveFromLibrary: widget.onRemoveFromLibrary,
                ),
                SearchScreen(
                  key: const ValueKey('search'),
                  controller: widget.controller,
                  onAddToLibrary: widget.onAddToLibrary,
                  onPlay: widget.onStreamSong,
                  showBackButton: false,
                  showScaffold: false,
                  onAlbumSelected: (album) {
                    setState(() {
                      _selectedAlbum = album;
                      _screen = _Screen.albumDetail;
                    });
                  },
                ),
                albumDetailWidget,
                const SizedBox.shrink(),
                SettingsScreen(
                  showBackButton: false,
                  showScaffold: false,
                  controller: widget.controller,
                ),
              ],
            ),
          ),
          _buildMiniPlayer(context),
        ],
      ),
    );
  }

  Widget _buildTabletBody() {
    final albumDetailWidget = _selectedAlbum != null
        ? AlbumDetailScreen(
            key: ValueKey(_selectedAlbum!.id),
            controller: widget.controller,
            album: _selectedAlbum!,
            showSidebar: false,
            showScaffold: false,
          )
        : const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DpadRegion(
          verticalEdge: DpadEdgeBehavior.stop,
          child: TabletSidebar(
            selectedIndex: _screen == _Screen.search
                ? 1
                : _screen == _Screen.settings
                ? 2
                : 0,
            onItemSelected: (index) {
              setState(() {
                switch (index) {
                  case 0:
                    _screen = _Screen.library;
                    break;
                  case 1:
                    _screen = _Screen.search;
                    break;
                  case 2:
                    _screen = _Screen.settings;
                    break;
                }
              });
            },
            playerManager: widget.playerManager,
            onPlayPause: () {
              if (widget.controller.playerManager.isPlaying) {
                widget.controller.playerManager.pause();
              } else {
                widget.controller.playerManager.playCurrent();
              }
            },
            onSkipPrevious: () => widget.controller.skipToPrevious(),
            onSkipNext: () => widget.controller.skipToNext(),
            onOpenPlayer: () {
              PlayerUIRouter().openFullPlayer(
                PlayerScreen(
                  playerManager: widget.playerManager,
                  onOpenQueue: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QueueScreen(
                          queueManager: widget.controller.queueManager,
                          playerManager: widget.controller.playerManager,
                          onPlayAtIndex: (index) =>
                              widget.controller.playAtIndex(index),
                        ),
                      ),
                    );
                  },
                  onSkipPrevious: () => widget.controller.skipToPrevious(),
                  onSkipNext: () => widget.controller.skipToNext(),
                  onKebabTap: () => showModalBottomSheet(
                    context: context,
                    builder: (ctx) => PlayerKebabMenu(
                      playerManager: widget.playerManager,
                      controller: widget.controller,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        DpadRegion(
          child: Expanded(
            child: IndexedStack(
              index: _screen.index,
              children: [
                LibraryScreen(
                  controller: widget.controller,
                  onPlaySaved: widget.onPlaySaved,
                  onRemoveFromLibrary: widget.onRemoveFromLibrary,
                  onPlaylistSelected: (playlist) {
                    setState(() {
                      _selectedPlaylist = playlist;
                      _screen = _Screen.playlistDetail;
                    });
                  },
                ),
                SearchScreen(
                  key: const ValueKey('search'),
                  controller: widget.controller,
                  onAddToLibrary: widget.onAddToLibrary,
                  onPlay: widget.onStreamSong,
                  showBackButton: false,
                  showScaffold: false,
                  onAlbumSelected: (album) {
                    setState(() {
                      _selectedAlbum = album;
                      _screen = _Screen.albumDetail;
                    });
                  },
                ),
                albumDetailWidget,
                _selectedPlaylist != null
                    ? PlaylistDetailScreen(
                        key: ValueKey('playlist_${_selectedPlaylist!.id}'),
                        controller: widget.controller,
                        playlist: _selectedPlaylist!,
                      )
                    : const SizedBox.shrink(),
                SettingsScreen(
                  showBackButton: false,
                  showScaffold: false,
                  controller: widget.controller,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniPlayer(BuildContext context) {
    return MiniPlayer(
      playerManager: widget.playerManager,
      onPlayPause: () {
        if (widget.playerManager.isPlaying) {
          widget.playerManager.pause();
        } else {
          widget.playerManager.playCurrent();
        }
      },
      onSkipNext: () => widget.controller.skipToNext(),
      onTap: () {
        PlayerUIRouter().openFullPlayer(
          PlayerScreen(
            playerManager: widget.playerManager,
            onOpenQueue: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QueueScreen(
                    queueManager: widget.controller.queueManager,
                    playerManager: widget.controller.playerManager,
                    onPlayAtIndex: (index) =>
                        widget.controller.playAtIndex(index),
                  ),
                ),
              );
            },
            onSkipPrevious: () => widget.controller.skipToPrevious(),
            onSkipNext: () => widget.controller.skipToNext(),
            onKebabTap: () => showModalBottomSheet(
              context: context,
              builder: (ctx) => PlayerKebabMenu(
                playerManager: widget.playerManager,
                controller: widget.controller,
              ),
            ),
          ),
        );
      },
    );
  }
}
