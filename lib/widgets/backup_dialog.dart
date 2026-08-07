import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dpad/dpad.dart';
import '../controllers/main_controller.dart';
import '../services/library_export_service.dart';

/// The visual phase of the dialog: picking options, exporting, or the
/// resulting success/error confirmation.
enum _BackupPhase { initial, busy, success, error }

/// Pre-backup confirmation dialog. Shows the destination folder, how many songs
/// and playlists the backup will contain, and lets the user copy the path
/// before committing to the export. On completion it stays open and shows the
/// result inline (with the written file path) rather than a transient SnackBar,
/// so the outcome and its location are never missed.
class BackupDialog extends StatefulWidget {
  final MainController controller;

  const BackupDialog({super.key, required this.controller});

  @override
  State<BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends State<BackupDialog> {
  late final int _songCount;
  late final int _playlistCount;
  String _backupPath = '';
  bool _pathLoading = true;
  _BackupPhase _phase = _BackupPhase.initial;
  String? _resultPath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Counts are synchronous; the path is resolved async so the dialog paints
    // immediately instead of waiting on the filesystem.
    final summary = LibraryExportService.backupSummary(widget.controller);
    _songCount = summary.songCount;
    _playlistCount = summary.playlistCount;
    _loadPath();
  }

  Future<void> _loadPath() async {
    final path = await LibraryExportService.backupDirectoryPath();
    if (!mounted) return;
    setState(() {
      _backupPath = path;
      _pathLoading = false;
    });
  }

  Future<void> _copyPath(String path) async {
    if (path.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: path));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Backup path copied')));
  }

  Future<void> _performBackup() async {
    if (_phase == _BackupPhase.busy) return;
    setState(() => _phase = _BackupPhase.busy);
    try {
      final file = await LibraryExportService.exportLibrary(widget.controller);
      if (!mounted) return;
      // Stay open and confirm inline so the user sees the written path (and can
      // copy it) instead of a SnackBar that disappears.
      setState(() {
        _resultPath = file.path;
        _phase = _BackupPhase.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Backup failed. Please try again.';
        _phase = _BackupPhase.error;
      });
    }
  }

  /// Bordered field grouping a path with its copy button, reused for both the
  /// destination folder and the resulting backup file so the action reads as one
  /// aligned control.
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
      title: const Text('Backup Library'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_phase == _BackupPhase.initial ||
                _phase == _BackupPhase.busy) ...[
              Text(
                '$_songCount ${_songCount == 1 ? 'song' : 'songs'} and '
                '$_playlistCount ${_playlistCount == 1 ? 'playlist' : 'playlists'} '
                'will be backed up.',
              ),
              const SizedBox(height: 16),
              _pathLoading
                  ? const Text('Loading backup folder…')
                  : _pathField(_backupPath, theme),
            ] else if (_phase == _BackupPhase.success) ...[
              Row(
                children: [
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Library backed up',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_resultPath != null) _pathField(_resultPath!, theme),
            ] else if (_phase == _BackupPhase.error) ...[
              Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_errorMessage ?? 'Backup failed')),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: _buildActions(),
    );
  }

  List<Widget> _buildActions() {
    switch (_phase) {
      case _BackupPhase.initial:
        return [
          DpadFocusable(
            debugLabel: 'Backup Cancel',
            onSelect: () => Navigator.of(context).pop(),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          DpadFocusable(
            debugLabel: 'Backup Confirm',
            onSelect: _performBackup,
            child: FilledButton(
              onPressed: _performBackup,
              child: const Text('Backup'),
            ),
          ),
        ];
      case _BackupPhase.busy:
        return [
          DpadFocusable(
            debugLabel: 'Backup Cancel',
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
      case _BackupPhase.success:
        return [
          DpadFocusable(
            debugLabel: 'Backup Done',
            onSelect: () => Navigator.of(context).pop(),
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ),
        ];
      case _BackupPhase.error:
        return [
          DpadFocusable(
            debugLabel: 'Backup Cancel',
            onSelect: () => Navigator.of(context).pop(),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          DpadFocusable(
            debugLabel: 'Backup Retry',
            onSelect: _performBackup,
            child: FilledButton(
              onPressed: _performBackup,
              child: const Text('Retry'),
            ),
          ),
        ];
    }
  }
}
