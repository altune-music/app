import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:altune/models/song.dart';
import 'package:altune/models/saved_playlist.dart';
import 'package:altune/services/log_service.dart';
import 'package:altune/services/queue_manager.dart';
import 'package:altune/interfaces/queue_repeat_mode.dart';

/// Owns reading/writing `altune_state.json`.
///
/// Schema:
/// - `songs`: full metadata pool. every persisted song lives here.
/// - `playlists`: definitions with `songIds` referencing `songs` by id.
///   Library and Recent Songs are system playlists (`isSystem: true`).
///   user playlists are additional references into the same `songs` pool.
/// - `queue`: ordered list of song ids + transient queue-only songs + settings
/// - `currentSongId`: id of the currently playing song (resolved from `songs`)
/// - `uiSettings`: app preferences
////// Owns reading/writing `altune_state.json`. `MainController` delegates
/// save/load here so state serialization is isolated from app logic.
class StateService {
  Future<File> _stateFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/altune_state.json');
  }

  Future<void> _atomicWrite(File file, String content) async {
    await file.parent.create(recursive: true);
    // Write to a sibling temp file then rename into place. Persist callbacks
    // fire saveState() unawaited, so two writes can overlap; a plain
    // writeAsString leaves a window where a concurrent reader sees a
    // truncated/missing state file (CI-only flake in library persistence
    // tests). Rename is atomic on POSIX, so readers always see either the old
    // or the complete new file.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(content);
    await tmp.rename(file.path);
  }

  Future<void> saveState({
    required List<Song> songs,
    required List<SavedPlaylist> playlists,
    required QueueManager queueManager,
    required Song? currentPlaying,
    required Map<String, dynamic> uiSettings,
  }) async {
    try {
      final libraryIds = <String>{for (final s in songs) s.id};
      final transientSongs = queueManager.queue
          .where((s) => !libraryIds.contains(s.id))
          .toList();

      final data = <String, dynamic>{
        'v': 1,
        'songs': songs.map((s) => s.toJson()).toList(),
        'playlists': playlists.map((p) => p.toJson()).toList(),
        'queue': {
          'ids': queueManager.queue.map((s) => s.id).toList(),
          'transient': transientSongs.map((s) => s.toJson()).toList(),
          'index': queueManager.currentIndex,
          'shuffle': queueManager.shuffle,
          'repeat': queueManager.repeatMode.index,
        },
        'currentSongId': currentPlaying?.id,
        'uiSettings': uiSettings,
      };
      await _atomicWrite(await _stateFile(), json.encode(data));
    } on MissingPluginException {
      // Expected in test environments where path_provider is unavailable.
    } catch (e) {
      LogService().error('Error saving state', error: e);
    }
  }

  Future<void> loadState({
    required List<Song> songs,
    required List<SavedPlaylist> playlists,
    required QueueManager queueManager,
    required void Function(Song) updateCurrentPlaying,
    required void Function()? onCurrentPlayingChanged,
    required Map<String, dynamic> uiSettings,
  }) async {
    try {
      final stateFile = await _stateFile();
      if (!await stateFile.exists()) return;
      final content = await stateFile.readAsString();
      if (content.isEmpty) return;
      final data = json.decode(content) as Map<String, dynamic>;
      _applyState(
        data,
        songs,
        playlists,
        queueManager,
        updateCurrentPlaying,
        onCurrentPlayingChanged,
        uiSettings,
      );
    } on MissingPluginException {
      // Expected in test environments where path_provider is unavailable.
    } catch (e) {
      LogService().error('Error loading state', error: e);
    }
  }

  void _applyState(
    Map<String, dynamic> data,
    List<Song> songs,
    List<SavedPlaylist> playlists,
    QueueManager queueManager,
    void Function(Song) updateCurrentPlaying,
    void Function()? onCurrentPlayingChanged,
    Map<String, dynamic> uiSettings,
  ) {
    songs.clear();
    songs.addAll(
      (data['songs'] as List? ?? []).map(
        (e) => Song.fromJson(e as Map<String, dynamic>),
      ),
    );
    playlists.clear();
    playlists.addAll(
      (data['playlists'] as List? ?? []).map(
        (e) => SavedPlaylist.fromJson(e as Map<String, dynamic>),
      ),
    );
    // System playlists are ensured by MainController after load.

    final librarySongMap = <String, Song>{for (final s in songs) s.id: s};

    final allSongsMap = <String, Song>{...librarySongMap};
    final q = data['queue'] as Map<String, dynamic>?;
    if (q != null) {
      final transientList = (q['transient'] as List? ?? []);
      for (final e in transientList) {
        final s = Song.fromJson(e as Map<String, dynamic>);
        allSongsMap[s.id] = s;
      }
    }

    if (q != null) {
      List<Song> restoredSongs;
      if (q['ids'] != null) {
        restoredSongs = (q['ids'] as List? ?? [])
            .cast<String>()
            .map((id) => allSongsMap[id])
            .where((s) => s != null)
            .cast<Song>()
            .toList();
      } else if (q['songs'] != null) {
        restoredSongs = (q['songs'] as List? ?? [])
            .map((e) => Song.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        restoredSongs = [];
      }

      final repeat =
          QueueRepeatMode.values[(q['repeat'] as int? ?? 0).clamp(
            0,
            QueueRepeatMode.values.length - 1,
          )];
      queueManager.restoreState(
        queue: restoredSongs,
        index: q['index'] as int? ?? -1,
        shuffle: q['shuffle'] as bool? ?? false,
        repeat: repeat,
      );
    }

    final currentSongId = data['currentSongId'] as String?;
    if (currentSongId != null) {
      final song = allSongsMap[currentSongId];
      if (song != null) {
        updateCurrentPlaying(song);
        onCurrentPlayingChanged?.call();
      }
    } else if (data['currentPlaying'] != null) {
      final cp = data['currentPlaying'] as Map<String, dynamic>?;
      if (cp != null) {
        final song = Song.fromJson(cp);
        final resolved = allSongsMap[song.id] ?? song;
        updateCurrentPlaying(resolved);
        onCurrentPlayingChanged?.call();
      }
    }

    uiSettings.clear();
    uiSettings.addAll(
      (data['uiSettings'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }
}
