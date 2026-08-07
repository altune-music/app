import '../../models/saved_playlist.dart';
import '../../models/song.dart';
import '../../services/state_service.dart';

/// Owns user playlist CRUD operations.
///
/// Extracted from MainController so playlist management is testable
/// without pulling in playback, search, or storage concerns.
class PlaylistController {
  final List<SavedPlaylist> playlists;
  final StateService stateService;
  Future<void> Function() onPersist = () async {};

  PlaylistController({required this.playlists, required this.stateService});

  Future<void> createPlaylist(String name) async {
    final playlist = SavedPlaylist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );
    playlists.add(playlist);
    await saveState();
  }

  Future<void> addToPlaylist(Song song, SavedPlaylist playlist) async {
    if (playlist.isSystem) return;
    final currentPlaylist = playlists
        .where((p) => p.id == playlist.id)
        .firstOrNull;
    if (currentPlaylist == null) return;
    if (currentPlaylist.songIds.contains(song.id)) return;

    _updatePlaylistSongs(playlist.id, [...currentPlaylist.songIds, song.id]);
  }

  Future<void> removeFromPlaylist(Song song, SavedPlaylist playlist) async {
    if (playlist.isSystem) return;
    final currentPlaylist = playlists
        .where((p) => p.id == playlist.id)
        .firstOrNull;
    if (currentPlaylist == null) return;
    final updatedSongIds = currentPlaylist.songIds
        .where((id) => id != song.id)
        .toList();
    if (updatedSongIds.length == currentPlaylist.songIds.length) return;
    _updatePlaylistSongs(playlist.id, updatedSongIds);
  }

  Future<void> deletePlaylist(String playlistId) async {
    final playlist = playlists.where((p) => p.id == playlistId).firstOrNull;
    if (playlist == null || playlist.isSystem) return;
    playlists.removeWhere((p) => p.id == playlistId);
    await saveState();
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1 || playlists[index].isSystem) return;
    final old = playlists[index];
    playlists[index] = SavedPlaylist(
      id: old.id,
      name: newName,
      songIds: old.songIds,
      coverImageUrl: old.coverImageUrl,
      isSystem: old.isSystem,
    );
    await saveState();
  }

  List<Song> searchPlaylist(
    SavedPlaylist playlist,
    String query,
    List<Song> localSongs,
  ) {
    final lowerQuery = query.toLowerCase();
    final songIds = playlist.songIds;
    return localSongs
        .where(
          (song) =>
              songIds.contains(song.id) &&
              (song.name?.toLowerCase().contains(lowerQuery) == true ||
                  song.primaryArtists?.toLowerCase().contains(lowerQuery) ==
                      true ||
                  song.album?.toLowerCase().contains(lowerQuery) == true),
        )
        .toList();
  }

  void _updatePlaylistSongs(String playlistId, List<String> newIds) {
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

  Future<void> saveState() async => onPersist.call();
}
