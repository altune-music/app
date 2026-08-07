import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/song.dart';
import '../interfaces/queue_repeat_mode.dart';
import '../services/log_service.dart';
import 'queue_manager.dart';

/// Owns [AudioPlayer], exposes unified playback state to all player widgets.
/// All players (mini, sidebar, full) read from the same [PlayerManager] instance.
class PlayerManager extends ChangeNotifier {
  final AudioPlayer _audioPlayer;
  final QueueManager _queueManager;

  Song? _currentPlaying;
  Song? _lastPlayedSong;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = false;
  bool _isPlaying = false;
  Timer? _sleepTimer;
  DateTime? _sleepTimerEnd;

  bool _isSettingPlaylist = false;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<SequenceState>? _sequenceStateSubscription;

  void Function(Song?)? _onSongChanged;
  void Function()? _onNext;
  void Function()? _onPrevious;
  void Function()? _onComplete;
  Future<void> Function(Song)? _onPlayRequested;

  PlayerManager({AudioPlayer? audioPlayer, QueueManager? queueManager})
    : _audioPlayer = audioPlayer ?? AudioPlayer(),
      _queueManager = queueManager ?? QueueManager() {
    _initListeners();
    // QueueManager no longer loads its own state; MainController.restoreState
    // repopulates the queue from the single state file on startup.
  }

  void _initListeners() {
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      _onPlayerStateChanged(state);
      _handlePlaybackState(state);
      // NOTE: we intentionally do NOT derive _isPlaying from state.playing here.
      // The just_audio_media_kit backend never sets `playing` in its stream, so
      // it would always be null/unchanged. _isPlaying is tracked explicitly in
      // play()/pause() and reset to false in _handlePlaybackState on completion.
    });
    _positionSubscription = _audioPlayer.positionStream.listen((pos) {
      _position = pos;
    });
    _durationSubscription = _audioPlayer.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
    });
    // Sync currentPlaying when the system notification / audio service
    // advances the source (e.g. lock-screen skip-next, if present).
    _sequenceStateSubscription = _audioPlayer.sequenceStateStream.listen((
      SequenceState? state,
    ) {
      if (_isSettingPlaylist) return;
      final mediaItem = state?.currentSource?.tag as MediaItem?;
      if (mediaItem != null) {
        final song = _queueManager.queue.firstWhere(
          (s) => s.id == mediaItem.id,
          orElse: () => _currentPlaying ?? Song(id: '', name: ''),
        );
        if (song.id.isNotEmpty && _currentPlaying?.id != song.id) {
          updateCurrentPlaying(song);
        }
      }
    });
  }

  void _onPlayerStateChanged(PlayerState state) {
    final wasLoading = _isLoading;
    _isLoading = state.processingState == ProcessingState.loading;
    // Sync playing state from the backend in both directions. The ExoPlayer
    // backend (Android) reports playing correctly, so external pauses from the
    // system notification / headset / Android Auto are reflected here. The
    // media_kit backend (Linux) leaves `playing` null, so these branches never
    // match there and play()/pause() remain the source of truth.
    if (state.playing == true && !_isPlaying) {
      _isPlaying = true;
      notifyListeners();
    } else if (state.playing == false && _isPlaying) {
      _isPlaying = false;
      notifyListeners();
    }
    if (wasLoading && !_isLoading) {
      notifyListeners();
    }
  }

  void _handlePlaybackState(PlayerState state) {
    if (state.processingState == ProcessingState.completed) {
      // The stream may or may not report playing=false on completion depending
      // on the backend, so force it here to keep the UI consistent.
      if (_isPlaying) {
        _isPlaying = false;
        notifyListeners();
      }
      // Cancel sleep timer when queue ends naturally (no next song)
      if (!_queueManager.hasNextSong) cancelSleepTimer();
      _onComplete?.call();
    }
  }

  AudioPlayer get audioPlayer => _audioPlayer;
  QueueManager get queueManager => _queueManager;

  Song? get currentPlaying => _currentPlaying;
  Song? get lastPlayedSong => _lastPlayedSong;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isLoading => _isLoading;
  int get queueIndex => _queueManager.currentIndex;
  bool get isShuffled => _queueManager.shuffle;
  QueueRepeatMode get repeatMode => _queueManager.repeatMode;
  LoopMode get loopMode => _audioPlayer.loopMode;

  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration> get durationStream =>
      _audioPlayer.durationStream.where((d) => d != null).cast<Duration>();
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<LoopMode> get loopModeStream => _audioPlayer.loopModeStream;

  set onSongChanged(void Function(Song?)? callback) {
    _onSongChanged = callback;
  }

  set onNext(void Function()? callback) {
    _onNext = callback;
  }

  set onPrevious(void Function()? callback) {
    _onPrevious = callback;
  }

  set onComplete(void Function()? callback) {
    _onComplete = callback;
  }

  set onPlayRequested(Future<void> Function(Song)? callback) {
    _onPlayRequested = callback;
  }

  void updateCurrentPlaying(Song? info) {
    _currentPlaying = info;
    _lastPlayedSong = info;
    _onSongChanged?.call(info);
    notifyListeners();
  }

  void setQueue(List<Song> songs, {String? songId}) {
    final index = songId != null ? songs.indexWhere((s) => s.id == songId) : 0;
    final initialIndex = index < 0 ? 0 : index;
    _queueManager.setQueue(songs, initialIndex: initialIndex);
    if (songs.isNotEmpty && initialIndex < songs.length) {
      _currentPlaying = songs[initialIndex];
    } else {
      _currentPlaying = null;
    }
    notifyListeners();
  }

  void clearQueue() {
    _queueManager.clearQueue();
    notifyListeners();
  }

  Future<void> playFromSongs(List<Song> songs, {String? songId}) async {
    setQueue(songs, songId: songId);
    final info = _currentPlaying;
    if (info != null && _onPlayRequested != null) {
      await _onPlayRequested!(info);
    }
  }

  void addToQueue(Song song) {
    _queueManager.addToQueueEnd(song);
    notifyListeners();
  }

  void next() {
    _queueManager.getNextSong();
    final nextSong = _queueManager.currentSong;
    if (nextSong != null) {
      _currentPlaying = nextSong;
      _onNext?.call();
    }
    notifyListeners();
  }

  void previous() {
    _queueManager.getPreviousSong();
    final prevSong = _queueManager.currentSong;
    if (prevSong != null) {
      _currentPlaying = prevSong;
      _onPrevious?.call();
    }
    notifyListeners();
  }

  void toggleShuffle() {
    _queueManager.toggleShuffle();
    notifyListeners();
  }

  void cycleRepeatMode() {
    _queueManager.cycleRepeatMode();
    notifyListeners();
  }

  // Build a single-source AudioPlayer playlist from the current song.
  // The full queue stays in queueManager; only the playable current song is
  // loaded into the AudioPlayer so there is no index mismatch.
  Future<void> setPlaylist(
    List<Song> songs, {
    required int initialIndex,
  }) async {
    if (songs.isEmpty || initialIndex < 0 || initialIndex >= songs.length) {
      return;
    }

    final song = songs[initialIndex];
    if (!song.isOffline && (song.url == null || song.url!.isEmpty)) {
      return;
    }

    final mediaItem = await _buildMediaItem(song);
    final cacheDir = Directory('${Directory.systemTemp.path}/altune_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    final AudioSource source;
    if (song.isOffline) {
      source = AudioSource.file(song.filePath!, tag: mediaItem);
    } else {
      final cacheFile = File('${cacheDir.path}/${song.id}');
      source =
          // ignore: experimental_member_use
          LockCachingAudioSource(
            Uri.parse(song.url!),
            tag: mediaItem,
            cacheFile: cacheFile,
          );
    }

    _isSettingPlaylist = true;
    try {
      await _audioPlayer.setAudioSource(source);
    } finally {
      _isSettingPlaylist = false;
    }
  }

  Future<MediaItem> _buildMediaItem(Song song) async {
    final hasLocalArtwork =
        song.localArtworkPath != null && song.localArtworkPath!.isNotEmpty;
    Uri? artUri;
    if (hasLocalArtwork) {
      artUri = await _localArtworkContentUri(song.localArtworkPath!);
    } else if (song.imageUrl.isNotEmpty) {
      artUri = Uri.parse(song.imageUrl);
    }
    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album ?? '',
      artUri: artUri,
    );
  }

  Future<Uri> _localArtworkContentUri(String path) async {
    if (kIsWeb || !Platform.isAndroid) return Uri.file(path);
    try {
      final result = await const MethodChannel(
        'altune/file_provider',
      ).invokeMethod<String>('getContentUri', {'path': path});
      if (result != null) return Uri.parse(result);
    } catch (e) {
      LogService().error(
        'Failed to get content URI for notification artwork',
        error: e,
      );
    }
    return Uri.file(path);
  }

  Future<void> play() async {
    if (_audioPlayer.playing) return;
    if (_audioPlayer.currentIndex == null) return;
    await _audioPlayer.play();
    // Explicit tracking as a fallback for media_kit (Linux) where the stream
    // leaves `playing` null. On Android/ExoPlayer the stream handles this.
    _isPlaying = true;
    notifyListeners();
  }

  // Like play(), but if the AudioPlayer has no sources yet (e.g. after app
  // restart when URLs haven't been resolved), triggers the playback setup
  // flow through the existing callback instead of silently returning.
  Future<void> playCurrent() async {
    if (_audioPlayer.playing) return;
    if (_audioPlayer.currentIndex == null) {
      if (_currentPlaying != null && _onPlayRequested != null) {
        await _onPlayRequested!(_currentPlaying!);
      }
      return;
    }
    await _audioPlayer.play();
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    // Explicit tracking as a fallback for media_kit (Linux). On Android the
    // stream also sets this when the notification/headset triggers a pause.
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> seek(Duration position) => _audioPlayer.seek(position);
  void setLoopMode(LoopMode mode) => _audioPlayer.setLoopMode(mode);
  void setShuffleModeEnabled(bool enabled) =>
      _audioPlayer.setShuffleModeEnabled(enabled);

  // ponytail: sleep timer via stdlib Timer, pauses on expiry
  bool get hasSleepTimer => _sleepTimer != null;
  DateTime? get sleepTimerEnd => _sleepTimerEnd;
  Duration? get sleepTimerRemaining =>
      _sleepTimerEnd?.difference(DateTime.now());

  void startSleepTimer(Duration duration) {
    cancelSleepTimer();
    _sleepTimerEnd = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () {
      _audioPlayer.pause();
      _sleepTimer = null;
      _sleepTimerEnd = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerEnd = null;
    notifyListeners();
  }

  void notify() => notifyListeners();

  void reset() {
    _currentPlaying = null;
    _lastPlayedSong = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _isLoading = false;
    cancelSleepTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _sequenceStateSubscription?.cancel();
    _audioPlayer.dispose();
    _queueManager.dispose();
    super.dispose();
  }
}
