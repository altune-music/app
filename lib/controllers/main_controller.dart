import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jiosaavn/jiosaavn.dart' hide Playlist;
import 'package:just_audio/just_audio.dart';

import '../controllers/api_search_controller.dart';
import '../controllers/library_controller.dart';
import '../controllers/playlist_controller.dart';
import '../interfaces/theme_color.dart';
import '../models/song.dart';
import '../models/saved_playlist.dart';
import '../services/log_service.dart';
import '../services/player_manager.dart';
import '../services/player_ui_router.dart';
import '../services/queue_manager.dart';
import '../services/state_service.dart';
import '../services/storage_service.dart';
import '../utils/string_utils.dart';

/// Central coordinator. Owns [JioSaavnClient], [PlayerManager], and orchestrates
/// playback, search, library, and playlist concerns through delegated controllers.
///
/// This is a facade: all public methods remain unchanged so UI and tests
/// don't need to change. Internally, logic is split into:
/// - [SearchController] — API search and streaming URL resolution
/// - [LibraryController] — local songs, Library, Recent Songs, download
/// - [PlaylistController] — user playlist CRUD
class MainController {
  final JioSaavnClient client;
  final PlayerManager _playerManager;
  final List<Song> localSongs;
  late final List<SavedPlaylist> playlists;
  late final ApiSearchController _searchController;
  late final LibraryController _libraryController;
  late final PlaylistController _playlistController;
  final StorageService _storageService;
  SongResponse? _lastStreamedSong;
  Function()? onLibraryChanged;
  Function()? _onCurrentPlayingChanged;

  LoopMode get loopMode => _playerManager.audioPlayer.loopMode;
  PlayerManager get playerManager => _playerManager;
  AudioPlayer get audioPlayer => _playerManager.audioPlayer;
  QueueManager get queueManager => _playerManager.queueManager;
  SongResponse? get lastStreamedSong => _lastStreamedSong;
  Song? get currentPlaying => _playerManager.currentPlaying;
  final StateService stateService;

  MainController({
    required this.client,
    required PlayerManager playerManager,
    required this.localSongs,
    List<SavedPlaylist>? playlists,
    required this.stateService,
    StorageService? storageService,
    ApiSearchController? searchController,
    LibraryController? libraryController,
    PlaylistController? playlistController,
  }) : _playerManager = playerManager,
       _storageService = storageService ?? StorageService(),
       _searchController =
           searchController ?? ApiSearchController(client: client) {
    this.playlists = List<SavedPlaylist>.from(playlists ?? []);
    _libraryController =
        libraryController ??
        LibraryController(
          localSongs: localSongs,
          playlists: this.playlists,
          client: client,
          storageService: storageService ?? StorageService(),
          stateService: stateService,
        );
    _playlistController =
        playlistController ??
        PlaylistController(
          playlists: this.playlists,
          stateService: stateService,
        );
    // MainController is the single persistence owner: queue/settings mutations
    // route through this callback so the whole app state lands in one JSON file
    // instead of a drift-prone second source.
    _playerManager.queueManager.onPersist = () {
      saveState();
    };
    _setupPlayerManagerCallbacks();
    // Wire persist callbacks after construction so sub-controllers can call back.
    _libraryController.onPersist = () => saveState();
    _playlistController.onPersist = () => saveState();
  }

  void _setupPlayerManagerCallbacks() {
    _playerManager.onSongChanged = (info) {
      if (info != null) {
        _libraryController.addToRecentSongs(
          info.id,
          info.title,
          info.artist,
          info.imageUrl,
          info.album,
          info.year,
        );
        _onCurrentPlayingChanged?.call();
      }
    };
    _playerManager.onNext = skipToNext;
    _playerManager.onPrevious = skipToPrevious;
    _playerManager.onComplete = skipToNext;
    _playerManager.onPlayRequested = (info) async {
      final song = localSongs.where((s) => s.id == info.id).firstOrNull;
      if (song != null) {
        await playSong(song);
      } else {
        final playingInfo = Song(
          id: info.id,
          name: cleanString(info.title),
          primaryArtists: cleanString(info.artist),
          album: info.album,
          year: info.year,
          imageUrl: info.imageUrl,
          localArtworkPath: info.localArtworkPath,
          url: info.url,
        );
        _playerManager.updateCurrentPlaying(playingInfo);
        await _playStreamingSong(info.id, playingInfo);
      }
    };
  }

  /// System playlists.
  SavedPlaylist get libraryPlaylist => _libraryController.libraryPlaylist;
  SavedPlaylist get recentSongsPlaylist =>
      _libraryController.recentSongsPlaylist;

  /// Unified lookup across user + system playlists.
  SavedPlaylist? getPlaylistById(String id) =>
      _libraryController.getPlaylistById(id);

  set onCurrentPlayingChanged(Function()? callback) {
    _onCurrentPlayingChanged = callback;
  }

  // Back-compat aliases: all persistence now flows through saveState(). Kept so
  // existing call sites don't need to change; they describe intent, not the store.
  Future<void> saveSongs() => saveState();
  Future<void> savePlaylists() => saveState();
  Future<void> saveSavedSongs() => saveState();
  Future<void> saveLastPlayedSong() => saveState();

  String? bitrateFromLinks(List<DownloadLink>? links) =>
      _searchController.bitrateFromLinks(links);

  Future<Directory> getStorageDir() async {
    return await _storageService.getStorageDir();
  }

  final Map<String, dynamic> _uiSettings = {};

  int? get librarySortMode => _uiSettings['librarySortMode'] as int?;
  Future<void> setLibrarySortMode(int index) async {
    _uiSettings['librarySortMode'] = index;
    await saveState();
  }

  int? get playlistSortMode => _uiSettings['playlistSortMode'] as int?;
  Future<void> setPlaylistSortMode(int index) async {
    _uiSettings['playlistSortMode'] = index;
    await saveState();
  }

  /// The user's chosen theme accent color, persisted in app state.
  ///
  /// Falls back to the brand default (green) when unset or out of range so
  /// an unknown stored index never crashes theme building.
  ThemeColor get themeColor {
    final index = _uiSettings['themeColor'];
    if (index is int && index >= 0 && index < ThemeColor.values.length) {
      return ThemeColor.values[index];
    }
    return ThemeColor.green;
  }

  /// Callback fired after the theme color changes so the app shell can rebuild
  /// with the new color scheme.
  Function()? onThemeChanged;

  Future<void> setThemeColor(ThemeColor color) async {
    _uiSettings['themeColor'] = color.index;
    await saveState();
    onThemeChanged?.call();
  }

  /// Persist the full app state (songs pool, playlists, queue, current song).
  Future<void> saveState() async {
    await stateService.saveState(
      songs: localSongs,
      playlists: playlists,
      queueManager: _playerManager.queueManager,
      currentPlaying: _playerManager.currentPlaying,
      uiSettings: _uiSettings,
    );
  }

  /// Restore the full app state.
  Future<void> loadState() async {
    try {
      await stateService.loadState(
        songs: localSongs,
        playlists: playlists,
        queueManager: _playerManager.queueManager,
        updateCurrentPlaying: (song) {
          _playerManager.updateCurrentPlaying(song);
          _onCurrentPlayingChanged?.call();
        },
        onCurrentPlayingChanged: () => _onCurrentPlayingChanged?.call(),
        uiSettings: _uiSettings,
      );
      _libraryController.ensureSystemPlaylists();
      onLibraryChanged?.call();
      // Refresh the app shell theme after restoring uiSettings, because the
      // screen-level onLibraryChanged callback (which the app shell doesn't
      // own) won't rebuild the MaterialApp where the seed color lives.
      onThemeChanged?.call();

      // Restore the AudioPlayer playlist so the play button works after
      // restart.  We set the sources but do NOT call play(), so playback
      // stays paused and the mini player shows the play icon.
      final queue = _playerManager.queueManager.queue;
      final currentIndex = _playerManager.queueManager.currentIndex;
      if (queue.isNotEmpty && currentIndex >= 0) {
        await _playerManager.setPlaylist(queue, initialIndex: currentIndex);
      }

      _playerManager.notify();
    } catch (e) {
      LogService().error('Error in loadState', error: e);
    }
  }

  // Back-compat alias: state loading now flows through loadState() only.
  Future<void> loadPlaylists() => loadState();

  // --- Playback ---

  Future<void> playSong(Song song, {List<Song>? songs}) async {
    try {
      final queue = songs ?? localSongs;
      _playerManager.setQueue(queue, songId: song.id);
      await _playCurrentInQueue();
      await saveLastPlayedSong();
    } catch (e) {
      LogService().error('Error in playSong', error: e);
      rethrow;
    }
  }

  Future<void> _playCurrentInQueue() async {
    final song = _playerManager.queueManager.currentSong;
    if (song == null) return;
    await _playSongFromQueue(song);
  }

  Future<void> playAllFromAlbum(List<Song> albumSongs, {String? songId}) async {
    _playerManager.setQueue(albumSongs, songId: songId);
    await _playCurrentInQueue();
  }

  void toggleQueueShuffle() {
    _playerManager.toggleShuffle();
    _playerManager.setShuffleModeEnabled(_playerManager.isShuffled);
  }

  void cycleQueueRepeat() {
    _playerManager.cycleRepeatMode();
  }

  void playNext(Song song) {
    _playerManager.queueManager.playNext(song);
  }

  void clearQueue() {
    _playerManager.clearQueue();
  }

  void addToQueue(Song song) {
    _playerManager.queueManager.addToQueueEnd(song);
  }

  Future<void> playAtIndex(int index) async {
    if (index < 0 || index >= _playerManager.queueManager.queue.length) return;
    _playerManager.queueManager.setCurrentIndex(index);
    await _playCurrentInQueue();
    await saveLastPlayedSong();
  }

  Future<void> skipToNext() async {
    final nextSong = _playerManager.queueManager.getNextSong();
    if (nextSong == null) return;
    await _playSongFromQueue(nextSong);
  }

  Future<void> skipToPrevious() async {
    final prevSong = _playerManager.queueManager.getPreviousSong();
    if (prevSong == null) return;
    await _playSongFromQueue(prevSong);
  }

  Future<void> _playSongFromQueue(Song song) async {
    try {
      final queue = _playerManager.queueManager.queue;
      final currentIndex = _playerManager.queueManager.currentIndex;
      final resolved = await _resolveStreamingUrls(queue);

      final hasLocalArtwork =
          song.localArtworkPath != null && song.localArtworkPath!.isNotEmpty;
      final playingInfo = Song(
        id: song.id,
        name: cleanString(song.title),
        primaryArtists: cleanString(song.artist),
        album: song.album,
        year: song.year,
        imageUrl: hasLocalArtwork ? '' : song.imageUrl,
        localArtworkPath: hasLocalArtwork ? song.localArtworkPath : null,
      );
      _playerManager.updateCurrentPlaying(playingInfo);

      await _playerManager.setPlaylist(resolved, initialIndex: currentIndex);
      await _playerManager.play();
      await saveSavedSongs();
    } catch (e) {
      LogService().error('Error in _playSongFromQueue', error: e);
      if (isMissingAudioBackend(e)) {
        _notifyPlaybackBackendMissing();
      }
      rethrow;
    }
  }

  // Resolve streaming URLs for songs that don't already have one, so the
  // ConcatenatingAudioSource playlist can be built with playable sources.
  Future<List<Song>> _resolveStreamingUrls(List<Song> songs) async {
    final needsResolution = songs
        .where((s) => !s.isOffline && (s.url == null || s.url!.isEmpty))
        .toList();
    if (needsResolution.isEmpty) return songs;

    final ids = needsResolution.map((s) => s.id).toList();
    try {
      final details = await client.songs.detailsById(ids);
      final urlMap = <String, String>{};
      for (final detail in details) {
        final url = _searchController.getBestAudioUrl(detail.downloadUrl)?.link;
        if (url != null && url.isNotEmpty) {
          urlMap[detail.id] = url;
        }
      }

      return songs.map((s) {
        if (!s.isOffline &&
            (s.url == null || s.url!.isEmpty) &&
            urlMap.containsKey(s.id)) {
          return s.copyWith(url: urlMap[s.id]);
        }
        return s;
      }).toList();
    } catch (e) {
      LogService().error('Error resolving streaming URLs', error: e);
      return songs;
    }
  }

  Future<void> _playStreamingSong(String songId, Song playingInfo) async {
    try {
      final queue = _playerManager.queueManager.queue;
      final currentIndex = _playerManager.queueManager.currentIndex;
      final resolved = await _resolveStreamingUrls(queue);

      await _playerManager.setPlaylist(resolved, initialIndex: currentIndex);
      await _playerManager.play();
      await saveSavedSongs();
    } catch (e) {
      LogService().error('Error in _playStreamingSong', error: e);
      if (isMissingAudioBackend(e)) {
        _notifyPlaybackBackendMissing();
      }
      rethrow;
    }
  }

  @visibleForTesting
  static bool isMissingAudioBackend(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('mpv') ||
        text.contains('shared librar') ||
        text.contains('cannot open');
  }

  void _notifyPlaybackBackendMissing() {
    final context = PlayerUIRouter().navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Playback isn\'t working because the audio library is missing. '
          'Install it using your distribution\'s package manager.',
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  // --- Streaming (facade to SearchController + playback orchestration) ---

  Future<void> streamSong(SongResponse song) async {
    try {
      final url = await _searchController.resolveStreamUrl(song);
      if (url == null || url.isEmpty) {
        throw Exception('No stream URL available');
      }
      _lastStreamedSong = song;
      await _playerManager.playFromSongs([
        _searchController.songResponseToSong(song, streamUrl: url),
      ]);
      await saveLastPlayedSong();
    } catch (e) {
      LogService().error('Error in streamSong', error: e);
      rethrow;
    }
  }

  Future<void> streamSongAndQueueNext(SongResponse song) async {
    final saved = _searchController.songResponseToSong(song);
    _playerManager.queueManager.playNext(saved);
    if (!_playerManager.isPlaying && _playerManager.currentPlaying == null) {
      await playSong(saved);
    }
  }

  Future<void> streamSongAndQueueAlbum(
    SongResponse song,
    List<SongResponse> albumSongs,
  ) async {
    _lastStreamedSong = song;
    final queue = albumSongs
        .map<Song>((s) => _searchController.songResponseToSong(s))
        .toList();
    _playerManager.setQueue(queue, songId: song.id);
    await _playCurrentInQueue();
    await saveLastPlayedSong();
  }

  Future<void> streamSongAndAddToQueue(SongResponse song) async {
    _playerManager.queueManager.addToQueueEnd(
      _searchController.songResponseToSong(song),
    );
  }

  void addStreamingSongToQueue(SongResponse song) {
    _playerManager.queueManager.addToQueueEnd(
      _searchController.songResponseToSong(song),
    );
  }

  // --- Search (facade to SearchController) ---

  Future<List<SongResponse>> searchSongs(String query) =>
      _searchController.searchSongs(query);

  Future<List<AlbumResponse>> searchAlbums(String query) =>
      _searchController.searchAlbums(query);

  Future<AlbumResponse> getAlbumDetails(
    String albumId, {
    AlbumResponse? fallback,
  }) => _searchController.getAlbumDetails(albumId, fallback: fallback);

  // --- Library (facade to LibraryController) ---

  Future<void> saveSong(SongResponse song) => _libraryController.saveSong(song);

  bool isSongInLibrary(String songId) =>
      _libraryController.isSongInLibrary(songId);

  Future<void> toggleSongInLibrary(SongResponse song) =>
      _libraryController.toggleSongInLibrary(song);

  Future<void> toggleLocalSongInLibrary(Song song) =>
      _libraryController.toggleLocalSongInLibrary(song);

  Future<void> toggleCurrentInLibrary() async {
    final info = _playerManager.currentPlaying;
    if (info == null) return;
    final lib = _libraryController.libraryPlaylist;
    final inLib = lib.songIds.contains(info.id);
    if (inLib) {
      _libraryController.updatePlaylistSongs(
        lib.id,
        lib.songIds.where((id) => id != info.id).toList(),
      );
      _libraryController.removeOrphan(info.id);

      final wasPlaying = _playerManager.isPlaying;
      final queueIndex = _playerManager.queueManager.getIndexById(info.id);
      if (queueIndex >= 0) {
        if (wasPlaying && _playerManager.queueManager.length > 1) {
          final nextSong = _playerManager.queueManager.getNextSong();
          if (nextSong != null) {
            await _playSongFromQueue(nextSong);
          } else {
            await _playerManager.audioPlayer.stop();
            _playerManager.reset();
          }
        } else {
          await _playerManager.audioPlayer.stop();
          _playerManager.reset();
        }
        _playerManager.queueManager.removeAt(queueIndex);
      }
    } else {
      if (!localSongs.any((s) => s.id == info.id)) {
        localSongs.add(
          Song(
            id: info.id,
            name: info.title,
            primaryArtists: info.artist,
            album: info.album,
            year: info.year,
            filePath: '',
            imageUrl: info.imageUrl,
          ),
        );
        await saveSongs();
      }
      // ponytail: fire-and-forget download; backgroundSaveById handles its own errors
      _libraryController.backgroundSaveById(info.id);
      final newIds = [...lib.songIds, info.id];
      _libraryController.updatePlaylistSongs(lib.id, newIds);
    }
    onLibraryChanged?.call();
    _playerManager.notify();
  }

  Future<void> removeFromLibrary(Song song) async {
    await _libraryController.removeFromLibrary(song);
    onLibraryChanged?.call();
  }

  /// Restore songs for offline playback with rate-limited sequential
  /// downloads. Skips songs already available locally.
  Future<void> restoreSongs(List<String> songIds) =>
      _libraryController.restoreSongs(songIds);

  // --- Playlist (facade to PlaylistController) ---

  Future<void> createPlaylist(String name) async {
    await _playlistController.createPlaylist(name);
    onLibraryChanged?.call();
  }

  Future<void> addToPlaylist(Song song, SavedPlaylist playlist) async {
    await _playlistController.addToPlaylist(song, playlist);
    onLibraryChanged?.call();
  }

  Future<void> addStreamingSongToPlaylist(
    SongResponse song,
    SavedPlaylist playlist,
  ) async {
    if (playlist.isSystem) return;
    final currentPlaylist = playlists
        .where((p) => p.id == playlist.id)
        .firstOrNull;
    if (currentPlaylist == null) return;
    if (currentPlaylist.songIds.contains(song.id)) return;

    final alreadySaved = localSongs.any((d) => d.id == song.id);
    if (!alreadySaved) {
      await saveSong(song);
    }
    await _playlistController.addToPlaylist(
      localSongs.firstWhere((d) => d.id == song.id),
      playlist,
    );
    onLibraryChanged?.call();
  }

  Future<void> removeFromPlaylist(Song song, SavedPlaylist playlist) async {
    await _playlistController.removeFromPlaylist(song, playlist);
    onLibraryChanged?.call();
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _playlistController.deletePlaylist(playlistId);
    onLibraryChanged?.call();
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    await _playlistController.renamePlaylist(playlistId, newName);
    onLibraryChanged?.call();
  }

  List<Song> searchPlaylist(SavedPlaylist playlist, String query) {
    return _playlistController.searchPlaylist(playlist, query, localSongs);
  }

  void reorderQueue(int oldIndex, int newIndex) {
    _playerManager.queueManager.reorderQueue(oldIndex, newIndex);
  }
}
