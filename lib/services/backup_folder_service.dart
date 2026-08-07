import 'dart:io';

import 'package:flutter/services.dart';

/// Provides user-selected backup folder operations on supported platforms.
class BackupFolderService {
  static const _channel = MethodChannel('altune/backup_folder');

  static bool get isAndroid => Platform.isAndroid;

  /// Open a folder picker and return the chosen folder URI, or null.
  static Future<String?> chooseBackupDirectory() async {
    if (!isAndroid) return null;
    try {
      return await _channel.invokeMethod<String?>('pickBackupFolder');
    } on PlatformException {
      return null;
    }
  }

  /// List JSON backup files in the chosen folder.
  static Future<List<Map<String, dynamic>>> listBackups(
    String folderUri,
  ) async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'listBackupFiles',
        {'folderUri': folderUri},
      );
      return result?.cast<Map<String, dynamic>>() ?? const [];
    } on PlatformException {
      return const [];
    }
  }

  /// Read a backup file by URI.
  static Future<String> readBackupFile(String uri) async {
    try {
      return await _channel.invokeMethod<String>('readBackupFile', {
            'uri': uri,
          }) ??
          '';
    } on PlatformException catch (e) {
      throw FormatException('Failed to read backup: ${e.message}');
    }
  }

  /// Write a backup payload into the chosen folder.
  static Future<void> writeBackupFile(
    String folderUri,
    String fileName,
    String contents,
  ) async {
    try {
      final ok = await _channel.invokeMethod<bool>('writeBackupFile', {
        'folderUri': folderUri,
        'fileName': fileName,
        'contents': contents,
      });
      if (ok != true) {
        throw FormatException('Write failed');
      }
    } on PlatformException catch (e) {
      throw FormatException('Failed to write backup: ${e.message}');
    }
  }

  /// Delete a backup file by URI.
  static Future<void> deleteBackupFile(String uri) async {
    try {
      final ok = await _channel.invokeMethod<bool>('deleteBackupFile', {
        'uri': uri,
      });
      if (ok != true) {
        throw FormatException('Delete failed');
      }
    } on PlatformException catch (e) {
      throw FormatException('Failed to delete backup: ${e.message}');
    }
  }
}
