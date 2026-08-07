import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dpad/dpad.dart';
import '../controllers/main_controller.dart';
import '../services/library_export_service.dart';

/// The visual phase of the dialog while it loads the detected restore file,
/// imports it, or shows the result.
enum _RestorePhase { loading, ready, busy, success, error }

/// Pre-restore confirmation dialog. Detects the backup JSON in the Restore
/// folder, shows its path and how many songs and playlists it contains, and lets
/// the user copy the path before importing. On completion it stays open and
/// shows the result inline (counts + Done on success, or an error with Retry)
/// rather than a transient SnackBar.
class RestoreDialog extends StatefulWidget {
  final MainController controller;

  const RestoreDialog({super.key, required this.controller});

  @override
  State<RestoreDialog> createState() => _RestoreDialogState();
}

class _RestoreDialogState extends State<RestoreDialog> {
  _RestorePhase _phase = _RestorePhase.loading;
  String _restorePath = '';
  int _songCount = 0;
  int _playlistCount = 0;
  Map<String, dynamic>? _previewData;
  String? _errorMessage;
  bool _canRetry = false;
  int _restoredSongs = 0;
  int _restoredPlaylists = 0;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  /// Detect the restore file and read its counts before showing options.
  Future<void> _loadPreview() async {
    try {
      final preview = await LibraryExportService.prepareRestore();
      if (!mounted) return;
      setState(() {
        _restorePath = preview.file.path;
        _songCount = preview.songCount;
        _playlistCount = preview.playlistCount;
        _previewData = preview.data;
        _phase = _RestorePhase.ready;
      });
    } on FormatException catch (e) {
      if (!mounted) return;
      // No file, or the file is malformed — resolve the Restore folder path
      // now so the error screen can show it in a copyable path field. The
      // user needs to know where to drop a backup, and the path should be
      // copyable rather than buried in the error text.
      final folderPath = await LibraryExportService.restoreDirectoryPath();
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _restorePath = folderPath;
        _canRetry = false;
        _phase = _RestorePhase.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not read the restore file.';
        _canRetry = false;
        _phase = _RestorePhase.error;
      });
    }
  }

  Future<void> _copyPath(String path) async {
    if (path.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: path));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Path copied')));
  }

  Future<void> _performRestore() async {
    if (_phase == _RestorePhase.busy || _previewData == null) return;
    setState(() => _phase = _RestorePhase.busy);
    try {
      final result = await LibraryExportService.importData(
        widget.controller,
        _previewData!,
      );
      if (!mounted) return;
      setState(() {
        _restoredSongs = result.songs;
        _restoredPlaylists = result.playlists;
        _phase = _RestorePhase.success;
      });
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _canRetry = true;
        _phase = _RestorePhase.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Restore failed. Please try again.';
        _canRetry = true;
        _phase = _RestorePhase.error;
      });
    }
  }

  /// Bordered field grouping a path with its copy button, reused across all
  /// phases so the action reads as one aligned control.
  Widget _pathField(String path, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SelectableText(
              path,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy, size: 20),
            tooltip: 'Copy path',
            onPressed: () => _copyPath(path),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Restore Library'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_phase == _RestorePhase.loading) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator()),
              ),
            ] else if (_phase == _RestorePhase.ready ||
                _phase == _RestorePhase.busy) ...[
              Text(
                '$_songCount ${_songCount == 1 ? 'song' : 'songs'} and '
                '$_playlistCount ${_playlistCount == 1 ? 'playlist' : 'playlists'} '
                'will be restored.',
              ),
              const SizedBox(height: 16),
              _pathField(_restorePath, theme),
            ] else if (_phase == _RestorePhase.success) ...[
              Row(
                children: [
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Library restored',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_restorePath.isNotEmpty) _pathField(_restorePath, theme),
              Text(
                'Restored $_restoredSongs ${_restoredSongs == 1 ? 'song' : 'songs'} '
                'and $_restoredPlaylists ${_restoredPlaylists == 1 ? 'playlist' : 'playlists'}.',
              ),
            ] else if (_phase == _RestorePhase.error) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_errorMessage ?? 'Restore failed')),
                ],
              ),
              const SizedBox(height: 16),
              // Show the path on the next line in a copyable field. When no
              // file was found this is the Restore folder path; when import
              // failed it is the detected backup file path.
              if (_restorePath.isNotEmpty) _pathField(_restorePath, theme),
            ],
          ],
        ),
      ),
      actions: _buildActions(),
    );
  }

  List<Widget> _buildActions() {
    switch (_phase) {
      case _RestorePhase.loading:
        return [
          DpadFocusable(
            debugLabel: 'Restore Cancel',
            onSelect: () => Navigator.of(context).pop(),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
        ];
      case _RestorePhase.ready:
        return [
          DpadFocusable(
            debugLabel: 'Restore Cancel',
            onSelect: () => Navigator.of(context).pop(),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          DpadFocusable(
            debugLabel: 'Restore Confirm',
            onSelect: _performRestore,
            child: FilledButton(
              onPressed: _performRestore,
              child: const Text('Restore'),
            ),
          ),
        ];
      case _RestorePhase.busy:
        return [
          DpadFocusable(
            debugLabel: 'Restore Cancel',
            onSelect: () => Navigator.of(context).pop(),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          FilledButton(
            onPressed: null,
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ];
      case _RestorePhase.success:
        return [
          DpadFocusable(
            debugLabel: 'Restore Done',
            onSelect: () => Navigator.of(context).pop(),
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ),
        ];
      case _RestorePhase.error:
        return [
          DpadFocusable(
            debugLabel: 'Restore Close',
            onSelect: () => Navigator.of(context).pop(),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
          if (_canRetry)
            DpadFocusable(
              debugLabel: 'Restore Retry',
              onSelect: _performRestore,
              child: FilledButton(
                onPressed: _performRestore,
                child: const Text('Retry'),
              ),
            ),
        ];
    }
  }
}
