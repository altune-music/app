import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/log_service.dart';

/// Owns storage directory resolution and settings file I/O.
///
/// Extracted from MainController so path logic is testable and reusable
/// without touching playback or playlist state.
class StorageService {
  String? _cachedStoragePath;
  bool _storagePathLoaded = false;

  Future<File> _file(String name) async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$name');
  }

  /// Resolve the app's storage directory for downloaded songs and artwork.
  Future<Directory> getStorageDir() async {
    String? customPath = await _getCustomStoragePath();
    Directory? storageDir;

    if (customPath != null && customPath.isNotEmpty) {
      storageDir = Directory(customPath);
    } else if (Platform.isAndroid) {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        storageDir = Directory('${externalDir.path}/altune');
      }
    } else {
      storageDir = await getDownloadsDirectory();
      if (storageDir != null) {
        storageDir = Directory('${storageDir.path}/altune');
      }
    }
    if (storageDir == null) {
      storageDir = await getApplicationDocumentsDirectory();
      storageDir = Directory('${storageDir.path}/altune');
    }
    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }
    return storageDir;
  }

  Future<String?> _getCustomStoragePath() async {
    if (_storagePathLoaded) return _cachedStoragePath;
    try {
      final file = await _file('settings.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final jsonMap = json.decode(content) as Map<String, dynamic>;
        _cachedStoragePath = jsonMap['storagePath'] as String?;
      }
    } catch (e) {
      LogService().error('Error in _getCustomStoragePath', error: e);
    }
    _storagePathLoaded = true;
    return _cachedStoragePath;
  }
}
