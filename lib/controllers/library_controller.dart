import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:jiosaavn/jiosaavn.dart';
import '../../models/song.dart';
import '../../models/saved_playlist.dart';
import '../../services/log_service.dart';
import '../../services/state_service.dart';
import '../../services/storage_service.dart';
import '../../utils/image_quality_helper.dart';
import '../../utils/string_utils.dart';

const _recentSongsPlaylistId = 'recent_songs';
const _recentSongsCap = 50;

/// Owns the local song pool, Library toggling, download, and Recent Songs.
///
/// Extracted from MainController so offline/library logic is testable
/// without pulling in playback or search concerns.
class LibraryController {
  final List<Song> localSongs;
  final List<SavedPlaylist> playlists;
  final JioSaavnClient client;
  final StorageService storageService;
  final StateService stateService;
  Future<void> Function() onPersist = () async {};

  LibraryController({
    required this.localSongs,
    required this.playlists,
    required this.client,
    required this.storageService,
    required this.stateService,
  });

  // ponytail: Library and Recent Songs are system playlists (isSystem: true).
  // They reference songs from the same `localSongs` pool — no separate storage.
  void ensureSystemPlaylists() {
    final hasLibrary = playlists.any((p) => p.id == 'library');
    final hasRecent = playlists.any((p) => p.id == _recentSongsPlaylistId);
    if (!hasLibrary) {
      _createSystemPlaylist('library', 'Library');
    }
    if (!hasRecent) {
      _createSystemPlaylist(_recentSongsPlaylistId, 'Recent Songs');
    }
  }

  SavedPlaylist get libraryPlaylist => playlists.firstWhere(
    (p) => p.id == 'library',
    orElse: () => _createSystemPlaylist('library', 'Library'),
  );

  SavedPlaylist get recentSongsPlaylist => playlists.firstWhere(
    (p) => p.id == _recentSongsPlaylistId,
    orElse: () => _createSystemPlaylist(_recentSongsPlaylistId, 'Recent Songs'),
  );

  SavedPlaylist? getPlaylistById(String id) {
    try {
      return playlists.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  SavedPlaylist _createSystemPlaylist(String id, String name) {
    final p = SavedPlaylist(id: id, name: name, isSystem: true);
    playlists.add(p);
    return p;
  }

  Future<void> saveSong(SongResponse song) async {
    final alreadyInLibrary = localSongs.any((d) => d.id == song.id);
    if (alreadyInLibrary) return;

    localSongs.add(
      Song(
        id: song.id,
        name: cleanString(song.name),
        primaryArtists: cleanString(song.primaryArtists),
        album: song.album.name,
        filePath: '',
        imageUrl: ImageQualityHelper.getHighestQualityLink(song.image) ?? '',
      ),
    );
    await saveState();
    // ponytail: fire-and-forget download; backgroundSaveById handles its own errors
    backgroundSaveById(song.id);
  }

  bool isSongInLibrary(String songId) {
    return libraryPlaylist.songIds.contains(songId);
  }

  Future<void> toggleSongInLibrary(SongResponse song) async {
    final lib = libraryPlaylist;
    final inLib = lib.songIds.contains(song.id);
    if (inLib) {
      final newIds = lib.songIds.where((id) => id != song.id).toList();
      updatePlaylistSongs(lib.id, newIds);
      removeOrphan(song.id);
    } else {
      await saveSong(song);
      final newIds = [...lib.songIds, song.id];
      updatePlaylistSongs(lib.id, newIds);
    }
  }

  Future<void> toggleLocalSongInLibrary(Song song) async {
    final lib = libraryPlaylist;
    final inLib = lib.songIds.contains(song.id);
    if (inLib) {
      final newIds = lib.songIds.where((id) => id != song.id).toList();
      updatePlaylistSongs(lib.id, newIds);
      removeOrphan(song.id);
    } else {
      if (!localSongs.any((d) => d.id == song.id)) {
        localSongs.add(song);
      }
      final newIds = [...lib.songIds, song.id];
      updatePlaylistSongs(lib.id, newIds);
    }
  }

  Future<void> removeFromLibrary(Song song) async {
    final lib = libraryPlaylist;
    final newIds = lib.songIds.where((id) => id != song.id).toList();
    updatePlaylistSongs(lib.id, newIds);

    final inOther = playlists.any(
      (p) => p.id != lib.id && p.songIds.contains(song.id),
    );
    if (!inOther) {
      try {
        if (song.filePath != null) {
          final file = File(song.filePath!);
          if (await file.exists()) await file.delete();
        }
        if (song.localArtworkPath != null &&
            song.localArtworkPath!.isNotEmpty) {
          final artworkFile = File(song.localArtworkPath!);
          if (await artworkFile.exists()) await artworkFile.delete();
        }
      } catch (e) {
        LogService().error(
          'Error in removeFromLibrary (file delete)',
          error: e,
        );
      }
    }
    removeOrphan(song.id);
  }

  void addToRecentSongs(
    String id,
    String title,
    String artist,
    String? imageUrl,
    String? album,
    String? year,
  ) {
    ensureSystemPlaylists();
    final recent = playlists.firstWhere((p) => p.id == _recentSongsPlaylistId);

    final hasDl = localSongs.any((d) => d.id == id);
    if (!hasDl) {
      localSongs.add(
        Song(
          id: id,
          name: cleanString(title),
          primaryArtists: cleanString(artist),
          album: album,
          year: year,
          filePath: '',
          imageUrl: imageUrl ?? '',
        ),
      );
    }

    final existing = recent.songIds.indexOf(id);
    final updatedIds = [...recent.songIds];
    if (existing >= 0) {
      updatedIds.removeAt(existing);
    }
    updatedIds.insert(0, id);

    while (updatedIds.length > _recentSongsCap) {
      final removedId = updatedIds.removeLast();
      removeOrphan(removedId);
    }

    updatePlaylistSongs(recent.id, updatedIds);
    saveState();
  }

  void removeOrphan(String songId) {
    final inAnyPlaylist = playlists.any((p) => p.songIds.contains(songId));
    if (!inAnyPlaylist) {
      localSongs.removeWhere((d) => d.id == songId);
      saveState();
    }
  }

  void updatePlaylistSongs(String playlistId, List<String> newIds) {
    final idx = playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;
    final old = playlists[idx];
    playlists[idx] = SavedPlaylist(
      id: old.id,
      name: old.name,
      songIds: newIds,
      coverImageUrl: old.coverImageUrl,
      isSystem: old.isSystem,
    );
    saveState();
  }

  /// Downloads songs for offline playback sequentially with a delay
  /// between each to avoid API rate limits.
  ///
  /// Skips songs that already have a local file path (already offline).
  Future<void> restoreSongs(List<String> songIds, {int delayMs = 300}) async {
    for (final id in songIds) {
      final existing = localSongs.where((s) => s.id == id).firstOrNull;
      if (existing != null && existing.isOffline) continue;
      await backgroundSaveById(id);
      await Future.delayed(Duration(milliseconds: delayMs));
    }
  }

  Future<void> backgroundSaveById(String songId) async {
    try {
      final details = await client.songs.detailsById([songId]);
      if (details.isEmpty) return;
      final s = details.first;
      final downloadUrl = ImageQualityHelper.getHighestQualityLink(
        s.downloadUrl,
      );
      if (downloadUrl == null || downloadUrl.isEmpty) return;
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) return;
      final dir = await storageService.getStorageDir();
      final filePath = '${dir.path}/${s.id}.mp3';
      await File(filePath).writeAsBytes(response.bodyBytes);
      String? localArtworkPath;
      final bestImageUrl = ImageQualityHelper.getHighestQualityLink(s.image);
      if (bestImageUrl != null && bestImageUrl.isNotEmpty) {
        final artworkResponse = await http.get(Uri.parse(bestImageUrl));
        if (artworkResponse.statusCode == 200) {
          localArtworkPath = '${dir.path}/$songId.jpg';
          await File(localArtworkPath).writeAsBytes(artworkResponse.bodyBytes);
        }
      }
      final index = localSongs.indexWhere((d) => d.id == songId);
      if (index == -1) return;
      final existingDate = localSongs[index].dateAdded;
      localSongs[index] = Song(
        id: s.id,
        name: cleanString(s.name),
        primaryArtists: cleanString(s.primaryArtists),
        album: s.album.name,
        year: s.year,
        filePath: filePath,
        imageUrl: bestImageUrl ?? '',
        localArtworkPath: localArtworkPath,
        bitrate: ImageQualityHelper.getHighestQualityDownloadLink(
          s.downloadUrl,
        )?.quality,
        dateAdded: existingDate,
      );
      await saveState();
    } catch (e) {
      LogService().error('Error in background save for $songId', error: e);
    }
  }

  Future<void> saveState() async => onPersist.call();
}
