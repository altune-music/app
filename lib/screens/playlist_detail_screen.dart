import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
import '../controllers/main_controller.dart';
import "../models/song.dart";
import '../models/saved_playlist.dart';
import '../widgets/song_actions_modal.dart';
import '../widgets/app_back_button.dart';
import '../widgets/song_list_item.dart';

import '../models/song_list_item_data.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final MainController controller;
  final SavedPlaylist playlist;
  const PlaylistDetailScreen({
    super.key,
    required this.controller,
    required this.playlist,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

enum _SortMode { nameAsc, nameDesc, dateAdded }

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  Function()? _previousOnLibraryChanged;

  @override
  void initState() {
    super.initState();
    _previousOnLibraryChanged = widget.controller.onLibraryChanged;
    widget.controller.onLibraryChanged = () {
      if (mounted) setState(() {});
    };
  }

  _SortMode get _sortMode {
    final saved = widget.controller.playlistSortMode;
    if (saved != null && saved >= 0 && saved < _SortMode.values.length) {
      return _SortMode.values[saved];
    }
    return _SortMode.nameAsc;
  }

  Future<void> _saveSortMode(_SortMode mode) async {
    await widget.controller.setPlaylistSortMode(mode.index);
  }

  @override
  void dispose() {
    widget.controller.onLibraryChanged = _previousOnLibraryChanged;
    super.dispose();
  }

  List<Song> _getSongs() {
    final playlist =
        widget.controller.playlists
            .where((p) => p.id == widget.playlist.id)
            .firstOrNull ??
        widget.playlist;
    final songs = playlist.songIds
        .map((id) => widget.controller.localSongs.where((s) => s.id == id))
        .expand((s) => s)
        .toList();
    // ponytail: system playlists (Recent Songs) are already ordered by recency
    // in playlist.songIds, so skip user-chosen sort modes.
    if (playlist.isSystem) return songs;
    switch (_sortMode) {
      case _SortMode.nameAsc:
        songs.sort(
          (a, b) => (a.name ?? '').toLowerCase().compareTo(
            (b.name ?? '').toLowerCase(),
          ),
        );
      case _SortMode.nameDesc:
        songs.sort(
          (a, b) => (b.name ?? '').toLowerCase().compareTo(
            (a.name ?? '').toLowerCase(),
          ),
        );
      case _SortMode.dateAdded:
        songs.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    }
    return songs;
  }

  void _playSong(Song song) {
    // Use all songs, not just saved ones — _playSongFromQueue
    // handles both offline (filePath) and streaming (no filePath) paths.
    final songs = _getSongs();
    if (songs.isEmpty) return;
    widget.controller.playAllFromAlbum(songs, songId: song.id);
  }

  @override
  Widget build(BuildContext context) {
    final songs = _getSongs();
    final playlist = widget.playlist;

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(
          // maybePop (not pop) so the layout's PopScope can route back on
          // large screens, where this screen lives in an IndexedStack rather
          // than a pushed route. A direct pop would remove the root route and
          // leave a blank screen. On mobile the pushed route still pops.
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(playlist.name),
        actions: [
          if (!playlist.isSystem)
            DpadFocusable(
              debugLabel: 'PlaylistDetail Sort',
              onSelect: () {
                final RenderBox button =
                    context.findRenderObject()! as RenderBox;
                final RenderBox overlay =
                    Navigator.of(context).overlay!.context.findRenderObject()!
                        as RenderBox;
                showMenu<_SortMode>(
                  context: context,
                  position: RelativeRect.fromRect(
                    Rect.fromPoints(
                      button.localToGlobal(Offset.zero, ancestor: overlay),
                      button.localToGlobal(
                        button.size.bottomRight(Offset.zero),
                        ancestor: overlay,
                      ),
                    ),
                    Offset.zero & overlay.size,
                  ),
                  items: [
                    PopupMenuItem(
                      value: _SortMode.nameAsc,
                      child: Text(
                        'Name (A-Z)',
                        style: TextStyle(
                          color: _sortMode == _SortMode.nameAsc
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: _SortMode.nameDesc,
                      child: Text(
                        'Name (Z-A)',
                        style: TextStyle(
                          color: _sortMode == _SortMode.nameDesc
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: _SortMode.dateAdded,
                      child: Text(
                        'Date Added',
                        style: TextStyle(
                          color: _sortMode == _SortMode.dateAdded
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                  ],
                ).then((mode) async {
                  if (mode != null) {
                    await _saveSortMode(mode);
                    if (mounted) setState(() {});
                  }
                });
              },
              child: PopupMenuButton<_SortMode>(
                icon: Icon(
                  Icons.sort,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Sort',
                onSelected: (mode) async {
                  await _saveSortMode(mode);
                  if (mounted) setState(() {});
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _SortMode.nameAsc,
                    child: Text(
                      'Name (A-Z)',
                      style: TextStyle(
                        color: _sortMode == _SortMode.nameAsc
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: _SortMode.nameDesc,
                    child: Text(
                      'Name (Z-A)',
                      style: TextStyle(
                        color: _sortMode == _SortMode.nameDesc
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: _SortMode.dateAdded,
                    child: Text(
                      'Date Added',
                      style: TextStyle(
                        color: _sortMode == _SortMode.dateAdded
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: songs.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return SongListItem(
                    song: SongListItemData.fromSong(song),
                    onTap: () => _playSong(song),
                    onMenuTap: () => _showSongActions(context, song),
                  );
                },
              ),
      ),
    );
  }

  void _showSongActions(BuildContext context, Song song) {
    // ponytail: no remove-from-playlist for auto-managed system playlists (Recent Songs)
    final canRemove = !widget.playlist.isSystem;
    showModalBottomSheet(
      context: context,
      builder: (context) => SongActionsModal(
        song: song,
        controller: widget.controller,
        onPlay: () => _playSong(song),
        onPlayNext: () => widget.controller.playNext(song),
        onAddToQueue: () => widget.controller.addToQueue(song),
        onToggleLibrary: () => widget.controller.toggleLocalSongInLibrary(song),
        onRemoveFromPlaylist: canRemove
            ? () async {
                await widget.controller.removeFromPlaylist(
                  song,
                  widget.playlist,
                );
              }
            : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'This playlist is empty',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
