import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
import 'package:jiosaavn/jiosaavn.dart';
import '../controllers/main_controller.dart';
import '../widgets/search_song_list_item.dart';
import '../widgets/song_actions_modal.dart';
import '../widgets/pill_button.dart';
import '../widgets/app_back_button.dart';
import '../widgets/album_list_item.dart';

import '../../utils/playlist_picker_helper.dart';
import '../../utils/debouncer.dart';

class SearchScreen extends StatefulWidget {
  final MainController controller;
  final Function(SongResponse) onAddToLibrary;
  final Function(SongResponse) onPlay;
  final VoidCallback? onSearchRequested;
  final Function(AlbumResponse)? onAlbumSelected;
  final bool showBackButton;
  final bool showScaffold;
  final VoidCallback? onBack;

  const SearchScreen({
    super.key,
    required this.controller,
    required this.onAddToLibrary,
    required this.onPlay,
    this.onSearchRequested,
    this.onAlbumSelected,
    this.showBackButton = false,
    this.showScaffold = true,
    this.onBack,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    _searchFocusNode.onKeyEvent = (node, event) {
      // ponytail: let all key events propagate for back gesture to work
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
  }

  void _switchTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchField = TextField(
      focusNode: _searchFocusNode,
      controller: _searchController,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: _selectedTabIndex == 0 ? 'Search songs' : 'Search albums',
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearSearch,
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(100),
        contentPadding: const EdgeInsets.only(
          left: 12,
          right: 12,
          top: 16,
          bottom: 16,
        ),
      ),
    );

    final tabsRow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          PillButton(
            icon: Icons.music_note,
            label: 'Songs',
            onTap: () => _switchTab(0),
            isSelected: _selectedTabIndex == 0,
          ),
          const SizedBox(width: 8),
          PillButton(
            icon: Icons.album,
            label: 'Albums',
            onTap: () => _switchTab(1),
            isSelected: _selectedTabIndex == 1,
          ),
        ],
      ),
    );

    final bodyContent = _selectedTabIndex == 0
        ? _SongsTab(
            controller: widget.controller,
            onAddToLibrary: widget.onAddToLibrary,
            onPlay: widget.onPlay,
            onSearchRequested: widget.onSearchRequested,
            searchQuery: _searchController.text,
          )
        : _AlbumsTab(
            controller: widget.controller,
            searchQuery: _searchController.text,
            onAlbumSelected: widget.onAlbumSelected,
          );

    if (!widget.showScaffold) {
      return Column(
        children: [
          Container(
            height: kToolbarHeight + MediaQuery.of(context).padding.top,
            color: Theme.of(context).colorScheme.surface,
            padding: EdgeInsets.fromLTRB(
              4,
              MediaQuery.of(context).padding.top,
              4,
              0,
            ),
            child: Row(
              children: [
                if (widget.showBackButton)
                  AppBackButton(onPressed: widget.onBack),
                Expanded(child: searchField),
              ],
            ),
          ),
          DpadRegion(child: tabsRow),
          Expanded(
            child: DpadRegion(
              horizontalEdge: DpadEdgeBehavior.stop,
              child: bodyContent,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: widget.showBackButton
            ? AppBackButton(onPressed: widget.onBack)
            : null,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: searchField,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            DpadRegion(child: tabsRow),
            Expanded(
              child: DpadRegion(
                horizontalEdge: DpadEdgeBehavior.stop,
                child: bodyContent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongsTab extends StatefulWidget {
  final MainController controller;
  final Function(SongResponse) onAddToLibrary;
  final Function(SongResponse) onPlay;
  final VoidCallback? onSearchRequested;
  final String searchQuery;

  const _SongsTab({
    required this.controller,
    required this.onAddToLibrary,
    required this.onPlay,
    this.onSearchRequested,
    required this.searchQuery,
  });

  @override
  State<_SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<_SongsTab> {
  List<SongResponse> _searchResults = [];
  bool _isLoading = false;
  bool _showResults = false;
  final Debouncer _debouncer = Debouncer();
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void didUpdateWidget(covariant _SongsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _performSearch();
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (widget.searchQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }
    final generation = ++_searchGeneration;
    setState(() {
      _isLoading = true;
      _showResults = true;
    });
    _debouncer(() async {
      if (generation != _searchGeneration) return;
      try {
        final results = await widget.controller.searchSongs(widget.searchQuery);
        if (generation != _searchGeneration) return;
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      } catch (e) {
        if (generation != _searchGeneration) return;
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
        }
      }
    });
  }

  void _showSongOptions(SongResponse song, BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SongActionsModal(
        songResponse: song,
        controller: widget.controller,
        onPlay: () => widget.controller.streamSong(song),
        onPlayNext: () => widget.controller.streamSongAndQueueNext(song),
        onAddToQueue: () => widget.controller.streamSongAndAddToQueue(song),
        onToggleLibrary: () => widget.onAddToLibrary(song),
        onAddToPlaylist: () =>
            showPlaylistPicker(context, song, widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _showResults
        ? _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 80),
                      const SizedBox(height: 16),
                      Text(
                        'No results found',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final song = _searchResults[index];
                    return SearchSongListItem(
                      song: song,
                      onTap: () {
                        widget.onPlay(song);
                      },
                      onKebabTap: () => _showSongOptions(song, context),
                    );
                  },
                )
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_note_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Search songs',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
  }
}

class _AlbumsTab extends StatefulWidget {
  final MainController controller;
  final String searchQuery;
  final Function(AlbumResponse)? onAlbumSelected;

  const _AlbumsTab({
    required this.controller,
    required this.searchQuery,
    this.onAlbumSelected,
  });

  @override
  State<_AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<_AlbumsTab> {
  List<AlbumResponse> _searchResults = [];
  bool _isLoading = false;
  bool _showResults = false;
  final Debouncer _debouncer = Debouncer();
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void didUpdateWidget(covariant _AlbumsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _performSearch();
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (widget.searchQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }
    final generation = ++_searchGeneration;
    setState(() {
      _isLoading = true;
      _showResults = true;
    });
    _debouncer(() async {
      if (generation != _searchGeneration) return;
      try {
        final results = await widget.controller.searchAlbums(
          widget.searchQuery,
        );
        if (generation != _searchGeneration) return;
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      } catch (e) {
        if (generation != _searchGeneration) return;
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _showResults
        ? _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 80),
                      const SizedBox(height: 16),
                      Text(
                        'No results found',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final album = _searchResults[index];
                    return AlbumListItem(
                      album: album,
                      onTap: () {
                        widget.onAlbumSelected?.call(album);
                      },
                    );
                  },
                )
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.album_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Search albums',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
  }
}
