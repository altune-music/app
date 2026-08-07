import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
import '../widgets/song_actions_modal.dart';
import "../models/song.dart";
import '../models/saved_playlist.dart';
import '../models/song_list_item_data.dart';
import '../widgets/song_list_item.dart';
import '../widgets/pill_button.dart';
import '../controllers/main_controller.dart';
import '../widgets/dpad_icon_button.dart';
import '../widgets/playlist_picker_content.dart';
import 'playlist_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  final MainController controller;
  final Function(Song) onPlaySaved;
  final Function(Song)? onLongPress;
  final Function(Song)? onRemoveFromLibrary;
  final Function(SavedPlaylist)? onPlaylistSelected;

  const LibraryScreen({
    super.key,
    required this.controller,
    required this.onPlaySaved,
    this.onLongPress,
    this.onRemoveFromLibrary,
    this.onPlaylistSelected,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

enum _SortMode { nameAsc, nameDesc, dateAdded }

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedTabIndex = 0;
  final TextEditingController _filterController = TextEditingController();
  final FocusNode _filterFocusNode = FocusNode();
  bool _showFilterField = false;

  @override
  void initState() {
    super.initState();
    widget.controller.onLibraryChanged = () {
      if (mounted) setState(() {});
    };
    _filterController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  _SortMode get _sortMode {
    final saved = widget.controller.librarySortMode;
    if (saved != null && saved >= 0 && saved < _SortMode.values.length) {
      return _SortMode.values[saved];
    }
    return _SortMode.nameAsc;
  }

  Future<void> _saveSortMode(_SortMode mode) async {
    await widget.controller.setLibrarySortMode(mode.index);
  }

  @override
  void dispose() {
    widget.controller.onLibraryChanged = null;
    _filterFocusNode.dispose();
    _filterController.dispose();
    super.dispose();
  }

  void _clearFilter() {
    _filterController.clear();
  }

  void _toggleFilterField() {
    setState(() {
      _showFilterField = !_showFilterField;
      if (!_showFilterField) {
        _filterController.clear();
      }
    });
  }

  void _selectPlaylist(SavedPlaylist playlist) {
    if (widget.onPlaylistSelected != null) {
      // Used on tablet — parent layout shows playlist in content panel
      widget.onPlaylistSelected!(playlist);
    } else {
      // Mobile: push full-screen route
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlaylistDetailScreen(
            controller: widget.controller,
            playlist: playlist,
          ),
        ),
      );
    }
  }

  List<PopupMenuEntry<_SortMode>> _buildSortMenuItems() {
    return [
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
    ];
  }

  Widget _buildSortButton() {
    return DpadFocusable(
      debugLabel: 'Library Sort',
      onSelect: _showSortDialog,
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
        itemBuilder: (_) => _buildSortMenuItems(),
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort by'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DpadFocusable(
              debugLabel: 'Sort Name A-Z',
              onSelect: () async {
                Navigator.pop(context);
                await _saveSortMode(_SortMode.nameAsc);
                if (mounted) setState(() {});
              },
              child: ListTile(
                title: Text(
                  'Name (A-Z)',
                  style: TextStyle(
                    color: _sortMode == _SortMode.nameAsc
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _saveSortMode(_SortMode.nameAsc);
                  if (mounted) setState(() {});
                },
              ),
            ),
            DpadFocusable(
              debugLabel: 'Sort Name Z-A',
              onSelect: () async {
                Navigator.pop(context);
                await _saveSortMode(_SortMode.nameDesc);
                if (mounted) setState(() {});
              },
              child: ListTile(
                title: Text(
                  'Name (Z-A)',
                  style: TextStyle(
                    color: _sortMode == _SortMode.nameDesc
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _saveSortMode(_SortMode.nameDesc);
                  if (mounted) setState(() {});
                },
              ),
            ),
            DpadFocusable(
              debugLabel: 'Sort Date Added',
              onSelect: () async {
                Navigator.pop(context);
                await _saveSortMode(_SortMode.dateAdded);
                if (mounted) setState(() {});
              },
              child: ListTile(
                title: Text(
                  'Date Added',
                  style: TextStyle(
                    color: _sortMode == _SortMode.dateAdded
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _saveSortMode(_SortMode.dateAdded);
                  if (mounted) setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPlaylist() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Playlist name'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          DpadFocusable(
            debugLabel: 'Dialog Cancel',
            onSelect: () => Navigator.of(context).pop(),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          DpadFocusable(
            debugLabel: 'Dialog Create',
            onSelect: () => Navigator.of(context).pop(nameController.text),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(nameController.text),
              child: const Text('Create'),
            ),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await widget.controller.createPlaylist(result.trim());
    }
  }

  Future<void> _deletePlaylist(SavedPlaylist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Delete "${playlist.name}"?'),
        actions: [
          DpadFocusable(
            debugLabel: 'Dialog Cancel',
            onSelect: () => Navigator.of(context).pop(false),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ),
          DpadFocusable(
            debugLabel: 'Dialog Delete',
            onSelect: () => Navigator.of(context).pop(true),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.controller.deletePlaylist(playlist.id);
    }
  }

  Future<void> _renamePlaylist(SavedPlaylist playlist) async {
    final nameController = TextEditingController(text: playlist.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Playlist name'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          DpadFocusable(
            debugLabel: 'Dialog Cancel',
            onSelect: () => Navigator.of(context).pop(),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          DpadFocusable(
            debugLabel: 'Dialog Rename',
            onSelect: () => Navigator.of(context).pop(nameController.text),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(nameController.text),
              child: const Text('Rename'),
            ),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await widget.controller.renamePlaylist(playlist.id, result.trim());
      if (mounted) setState(() {});
    }
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    double iconSize = 80,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              PillButton(
                icon: Icons.music_note,
                label: 'Songs',
                onTap: () => setState(() {
                  _selectedTabIndex = 0;
                }),
                isSelected: _selectedTabIndex == 0,
              ),
              const SizedBox(width: 8),
              PillButton(
                icon: Icons.queue_music,
                label: 'Playlists',
                onTap: () => setState(() {
                  _selectedTabIndex = 1;
                }),
                isSelected: _selectedTabIndex == 1,
              ),
              const Spacer(),
              if (_selectedTabIndex == 0)
                DpadIconButton(
                  debugLabel: 'Library Filter',
                  onPressed: _toggleFilterField,
                  icon: const Icon(Icons.filter_list),
                  isSelected:
                      _showFilterField || _filterController.text.isNotEmpty,
                  tooltip: 'Filter',
                ),
              if (_selectedTabIndex == 1)
                DpadIconButton(
                  debugLabel: 'Library AddPlaylist',
                  onPressed: _createPlaylist,
                  icon: const Icon(Icons.add),
                ),
              _buildSortButton(),
            ],
          ),
        ),
        if (_showFilterField && _selectedTabIndex == 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              focusNode: _filterFocusNode,
              controller: _filterController,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Filter songs...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                suffixIcon: _filterController.text.isEmpty
                    ? Icon(
                        Icons.search,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    : IconButton(
                        icon: Icon(Icons.clear, size: 20),
                        onPressed: _clearFilter,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withAlpha(100),
              ),
            ),
          ),
        Expanded(
          child: _selectedTabIndex == 0
              ? _buildSongsTab()
              : _buildPlaylistsTab(),
        ),
      ],
    );
  }

  Widget _buildSongsTab() {
    final query = _filterController.text.toLowerCase().trim();
    final lib = widget.controller.libraryPlaylist;
    // Resolve Library playlist song IDs to Song entries
    var songs = lib.songIds
        .map((id) => widget.controller.localSongs.where((s) => s.id == id))
        .expand((s) => s)
        .toList();
    if (query.isNotEmpty) {
      songs = songs
          .where(
            (s) =>
                (s.name?.toLowerCase().contains(query) == true) ||
                (s.primaryArtists?.toLowerCase().contains(query) == true) ||
                (s.album?.toLowerCase().contains(query) == true),
          )
          .toList();
    }
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
    if (songs.isEmpty && query.isNotEmpty) {
      return _emptyState(
        icon: Icons.search_off,
        title: 'No matching songs',
        subtitle: 'Try a different search term',
        iconSize: 64,
      );
    }
    if (songs.isEmpty) {
      return _emptyState(
        icon: Icons.library_music,
        title: 'Your library is empty',
      );
    }
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final song = songs[index];
              return LibrarySongListItem(
                song: song,
                controller: widget.controller,
                onPlay: (s) => widget.controller.playSong(s, songs: songs),
                onPlayNext: (song) => widget.controller.playNext(song),
                onAddToQueue: (song) => widget.controller.addToQueue(song),
                onAddToPlaylist: (song, playlist) =>
                    widget.controller.addToPlaylist(song, playlist),
                onCreatePlaylist: (name) async {
                  await widget.controller.createPlaylist(name);
                  final playlist = widget.controller.playlists.last;
                  await widget.controller.addToPlaylist(song, playlist);
                },
                playlists: widget.controller.playlists
                    .where((p) => !p.isSystem)
                    .toList(),
                onRemoveFromLibrary: widget.onRemoveFromLibrary,
              );
            }, childCount: songs.length),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistsTab() {
    // Show user playlists + Recent Songs
    final playlists = <SavedPlaylist>[
      widget.controller.recentSongsPlaylist,
      ...widget.controller.playlists.where((p) => !p.isSystem),
    ];
    switch (_sortMode) {
      case _SortMode.nameAsc:
      case _SortMode.dateAdded:
        playlists.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case _SortMode.nameDesc:
        playlists.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
    }
    return Column(
      children: [
        Expanded(
          child: playlists.isEmpty
              ? _emptyState(
                  icon: Icons.queue_music,
                  title: 'No playlists yet',
                  subtitle: 'Tap + to create one',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return _PlaylistListItem(
                      playlist: playlist,
                      onTap: () => _selectPlaylist(playlist),
                      onDelete: playlist.isSystem
                          ? null
                          : () => _deletePlaylist(playlist),
                      onRename: playlist.isSystem
                          ? null
                          : () => _renamePlaylist(playlist),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class LibrarySongListItem extends StatelessWidget {
  final Song song;
  final bool isInLibrary;
  final Function(Song) onPlay;
  final Function(Song)? onLongPress;
  final Function(Song)? onRemoveFromLibrary;
  final Function(Song)? onPlayNext;
  final Function(Song)? onAddToQueue;
  final Function(Song, SavedPlaylist)? onAddToPlaylist;
  final Function(String name)? onCreatePlaylist;
  final List<SavedPlaylist> playlists;
  final MainController controller;
  const LibrarySongListItem({
    super.key,
    required this.song,
    this.isInLibrary = true,
    required this.onPlay,
    this.onLongPress,
    this.onRemoveFromLibrary,
    this.onPlayNext,
    this.onAddToQueue,
    this.onAddToPlaylist,
    this.onCreatePlaylist,
    this.playlists = const [],
    required this.controller,
  });

  void _showSongActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SongActionsModal(
        song: song,
        controller: controller,
        onPlay: () => onPlay(song),
        onPlayNext: onPlayNext != null ? () => onPlayNext!(song) : null,
        onAddToQueue: onAddToQueue != null ? () => onAddToQueue!(song) : null,
        onAddToPlaylist: onAddToPlaylist != null && playlists.isNotEmpty
            ? () => _showPlaylistPicker(context)
            : null,
        onRemoveFromLibrary: () => onRemoveFromLibrary?.call(song),
      ),
    );
  }

  void _showPlaylistPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PlaylistPickerContent(
        playlists: playlists,
        onSelectPlaylist: (playlist) {
          Navigator.pop(context);
          onAddToPlaylist?.call(song, playlist);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SongListItem(
      song: SongListItemData.fromSong(song),
      onTap: () => onPlay(song),
      onMenuTap: () => _showSongActions(context),
    );
  }
}

class _PlaylistListItem extends StatelessWidget {
  final SavedPlaylist playlist;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;
  const _PlaylistListItem({
    required this.playlist,
    required this.onTap,
    this.onDelete,
    this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = playlist.id == 'recent_songs'
        ? Icons.history
        : Icons.queue_music;

    return DpadFocusable(
      debugLabel: 'Playlist ${playlist.name}',
      onSelect: onTap,
      child: const SizedBox(),
      builder: (context, state, child) {
        return InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: state.focused ? colorScheme.secondaryContainer : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Container(
                        color: colorScheme.secondaryContainer,
                        child: Icon(icon, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${playlist.songIds.length} songs',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null || onRename != null)
                    DpadIconButton(
                      debugLabel: 'Playlist Menu ${playlist.name}',
                      onPressed: () => _showMenu(context),
                      icon: const Icon(Icons.more_vert),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onRename != null)
              DpadFocusable(
                debugLabel: 'PlaylistMenu Rename',
                onSelect: () {
                  Navigator.pop(context);
                  onRename!();
                },
                child: ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Rename'),
                  onTap: () {
                    Navigator.pop(context);
                    onRename!();
                  },
                ),
              ),
            if (onDelete != null)
              DpadFocusable(
                debugLabel: 'PlaylistMenu Delete',
                onSelect: () {
                  Navigator.pop(context);
                  onDelete!();
                },
                child: ListTile(
                  leading: const Icon(Icons.playlist_remove),
                  title: const Text('Delete Playlist'),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete!();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
