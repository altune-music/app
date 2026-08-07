import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../controllers/main_controller.dart';
import '../models/saved_playlist.dart';
import '../models/song.dart';

/// A preview of a restore file shown to the user before importing, so they can
/// confirm the app picked the expected file at the fixed restore location.
typedef RestorePreview = ({
  File file,
  Map<String, dynamic> data,
  int songCount,
  int playlistCount,
});

/// Count of songs and playlists a backup will contain, for the pre-backup
/// confirmation dialog.
typedef BackupSummary = ({int songCount, int playlistCount});

/// Generates, saves, and imports library backups.
///
/// A backup contains only minimal song metadata and user-playlist definitions.
/// It does not include audio files, artwork, or transient/played-only songs.
class LibraryExportService {
  /// The two collections that make up a backup: the songs to persist (those in
  /// the Library or referenced by a user playlist) and the user playlists
  /// themselves. Extracted so [buildBackupPayload] and [backupSummary] select
  /// the same entries — the pre-backup count can never drift from the file.
  static ({List<Song> songs, List<SavedPlaylist> playlists}) _collectBackupData(
    MainController controller,
  ) {
    final librarySongs = controller.localSongs
        .where((s) => controller.libraryPlaylist.songIds.contains(s.id))
        .toList();
    final userPlaylists = controller.playlists
        .where((p) => !p.isSystem)
        .toList();

    final persistentIds = <String>{
      for (final s in librarySongs) s.id,
      for (final p in userPlaylists) ...p.songIds,
    };

    final songs = controller.localSongs
        .where((s) => persistentIds.contains(s.id))
        .toList();

    return (songs: songs, playlists: userPlaylists);
  }

  /// Build the backup JSON payload from [controller] state.
  static String buildBackupPayload(MainController controller) {
    final data = _collectBackupData(controller);
    final songsJson = data.songs.map((s) {
      return {
        'id': s.id,
        'name': s.name,
        'primaryArtists': s.primaryArtists,
        'album': s.album,
      };
    }).toList();

    final playlistsJson = data.playlists
        .map((p) => {'id': p.id, 'name': p.name, 'songIds': p.songIds})
        .toList();

    return json.encode({'songs': songsJson, 'playlists': playlistsJson});
  }

  /// Count of songs and playlists a backup will contain, for the pre-backup
  /// confirmation dialog. Uses [_collectBackupData] so the numbers match the
  /// written file exactly.
  static BackupSummary backupSummary(MainController controller) {
    final data = _collectBackupData(controller);
    return (songCount: data.songs.length, playlistCount: data.playlists.length);
  }

  /// Export the library from [controller] to a backup file.
  ///
  /// The file is always written to the Backups folder, so the path shown in
  /// the backup dialog is exactly where it lands — no native save dialog.
  static Future<File> exportLibrary(MainController controller) async {
    final payload = buildBackupPayload(controller);
    return saveBackupFile(payload);
  }

  /// Folder the app reads restore files from. The user copies any backup JSON
  /// here; no file picker is shown, so the file that gets used is explicit.
  static const String restoreFolderName = 'Restore';

  /// Full path of the restore folder the app expects inside app support.
  static Future<String> restoreDirectoryPath() async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/$restoreFolderName';
  }

  /// Locate the restore file to use: the most recently modified JSON in the
  /// restore folder, or null when the folder has no JSON files.
  static Future<File?> findRestoreFile() async {
    final folder = Directory(await restoreDirectoryPath());
    if (!await folder.exists()) return null;
    final files = await folder
        .list()
        .where((e) => e is File && e.path.toLowerCase().endsWith('.json'))
        .cast<File>()
        .toList();
    if (files.isEmpty) return null;
    files.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );
    return files.first;
  }

  /// Read and parse the restore file at the fixed location, returning a preview
  /// the UI shows before importing.
  ///
  /// Throws [FormatException] when no backup JSON is present or the chosen
  /// file is malformed. The dialog resolves and displays the Restore folder
  /// path alongside the message, so this method does not need to embed the
  /// path in its exception text.
  static Future<RestorePreview> prepareRestore() async {
    final file = await findRestoreFile();
    if (file == null) {
      throw FormatException(
        'No restore file found. Copy a backup JSON to the Restore folder.',
      );
    }
    final data = await _parseBackupFile(file);
    final songCount = (data['songs'] as List).length;
    final playlistCount = (data['playlists'] as List).length;
    return (
      file: file,
      data: data,
      songCount: songCount,
      playlistCount: playlistCount,
    );
  }

  /// Save the backup payload to a timestamped file inside the Backups folder.
  ///
  /// Backups always land in a fixed location so the path shown in the UI is
  /// where the file actually gets written; there is no native save dialog.
  static Future<File> saveBackupFile(String payload) async {
    final backupsDir = Directory(await backupDirectoryPath());
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }
    final timestamp = DateTime.now().toIso8601String().replaceAll(
      RegExp(r'[^0-9]'),
      '_',
    );
    final file = File('${backupsDir.path}/altune_backup_$timestamp.json');
    await file.writeAsString(payload);
    return file;
  }

  /// Resolve the directory used for backups.
  static Future<String> backupDirectoryPath() async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/Backups';
  }

  /// Parse [file] as a backup JSON, validating its top-level shape.
  ///
  /// Throws [FormatException] when the file is not a valid backup.
  static Future<Map<String, dynamic>> _parseBackupFile(File file) async {
    final content = await file.readAsString();
    final data = json.decode(content) as Map<String, dynamic>;
    if (data['songs'] is! List || data['playlists'] is! List) {
      throw FormatException('Invalid backup format');
    }
    return data;
  }

  /// Merge backup [data] into [controller] state.
  static Future<({int songs, int playlists})> importData(
    MainController controller,
    Map<String, dynamic> data,
  ) async {
    final songsJson = (data['songs'] as List).cast<Map<String, dynamic>>();
    final playlistsJson = (data['playlists'] as List)
        .cast<Map<String, dynamic>>();

    final existingIds = controller.localSongs.map((s) => s.id).toSet();
    final restoredSongIds = <String>[];
    int addedSongs = 0;
    for (final json in songsJson) {
      final id = json['id'] as String?;
      if (id == null || id.isEmpty || existingIds.contains(id)) continue;
      controller.localSongs.add(
        Song(
          id: id,
          name: json['name'] as String?,
          primaryArtists: json['primaryArtists'] as String?,
          album: json['album'] as String?,
          filePath: '',
          imageUrl: '',
          dateAdded: DateTime.now(),
        ),
      );
      existingIds.add(id);
      restoredSongIds.add(id);
      addedSongs++;
    }

    final existingPlaylistIds = controller.playlists.map((p) => p.id).toSet();
    int addedPlaylists = 0;
    for (final json in playlistsJson) {
      final id = json['id'] as String?;
      if (id == null || id.isEmpty || existingPlaylistIds.contains(id)) {
        continue;
      }
      controller.playlists.add(
        SavedPlaylist(
          id: id,
          name: json['name'] as String? ?? 'Imported Playlist',
          songIds: (json['songIds'] as List?)?.cast<String>() ?? [],
        ),
      );
      existingPlaylistIds.add(id);
      addedPlaylists++;
    }

    if (addedSongs > 0 || addedPlaylists > 0) {
      await controller.saveState();
      controller.onLibraryChanged?.call();
    }

    if (restoredSongIds.isNotEmpty) {
      controller.restoreSongs(restoredSongIds);
    }

    return (songs: addedSongs, playlists: addedPlaylists);
  }
}
