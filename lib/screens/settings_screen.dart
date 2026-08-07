import '../controllers/main_controller.dart';
import '../interfaces/theme_color.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
import 'package:altune/widgets/dpad_icon_button.dart';
import 'package:altune/widgets/backup_dialog.dart';
import 'package:altune/widgets/restore_dialog.dart';
import 'package:altune/services/battery_optimization_service.dart';
import 'package:altune/services/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_update.dart';
import '../utils/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  final bool showBackButton;
  final bool showScaffold;
  final VoidCallback? onBack;
  final MainController controller;

  /// Optional override for the update check, used to inject a fake in widget
  /// tests so the screen never makes a real network call. Defaults to
  /// [UpdateService.checkForUpdates].
  final Future<AppUpdate?> Function()? updateCheck;

  const SettingsScreen({
    super.key,
    this.showBackButton = true,
    this.showScaffold = true,
    this.onBack,
    required this.controller,
    this.updateCheck,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  bool _isCheckingUpdate = false;
  AppUpdate? _latestUpdate;
  bool _updateCheckDone = false;
  bool _updateCheckFailed = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    if (!mounted) return;
    setState(() {
      _isCheckingUpdate = true;
    });
    try {
      final checkForUpdates =
          widget.updateCheck ?? () => UpdateService().checkForUpdates();
      final update = await checkForUpdates();
      if (!mounted) return;
      setState(() {
        _latestUpdate = update;
        _isCheckingUpdate = false;
        _updateCheckDone = true;
        _updateCheckFailed = false;
      });
    } on Exception catch (_) {
      if (!mounted) return;
      // Show nothing on failure so a silent network blip never claims the app
      // is up to date or nags the user with an error.
      setState(() {
        _isCheckingUpdate = false;
        _updateCheckFailed = true;
      });
    }
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = '${info.version} (${info.buildNumber})');
    } on Exception catch (_) {
      if (!mounted) return;
      setState(() => _version = 'Loading…');
    }
  }

  Future<void> _openRepository() async {
    final uri = Uri.parse(AppConstants.appGitHubRepositoryUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open repository link')),
      );
    }
  }

  Future<void> _openLicenseFile() async {
    final uri = Uri.parse(
      '${AppConstants.appGitHubRepositoryUrl}/blob/main/LICENSE',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open license file')),
      );
    }
  }

  Future<void> _openReleasePage() async {
    if (_latestUpdate == null) return;
    await UpdateService().openReleasePage(_latestUpdate!);
  }

  /// Renders the installed version as a tile, with the update status inline
  /// beside it. Tapping the tile opens a popup showing update status.
  Widget _buildVersionTile() {
    final theme = Theme.of(context);
    final updateAvailable = _latestUpdate != null;
    final statusText = _updateStatusText();
    return DpadFocusable(
      debugLabel: 'Version',
      onSelect: _showVersionDialog,
      child: GestureDetector(
        onTap: _showVersionDialog,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                updateAvailable ? Icons.system_update : Icons.info_outline,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Version $_version', style: theme.textTheme.bodyLarge),
                    if (statusText.isNotEmpty)
                      Text(
                        statusText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: updateAvailable
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (updateAvailable)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The short update-status line shown under the version in the tile.
  String _updateStatusText() {
    if (_isCheckingUpdate) return 'Checking for updates…';
    if (_latestUpdate != null) {
      return 'Update available: v${_latestUpdate!.versionWithoutPrefix}';
    }
    if (_updateCheckDone && !_updateCheckFailed) return 'You are up to date';
    // Check failed or still pending — show no status line so a silent network
    // blip never claims the app is up to date.
    return '';
  }

  /// Shows a dialog with the current update status.
  /// No dialog is shown if the update check is still in progress or has failed.
  void _showVersionDialog() {
    // Don't show any popup if check is in progress or has failed.
    if (_isCheckingUpdate || _updateCheckFailed) return;
    final hasUpdate = _latestUpdate != null;
    final updateVersion = hasUpdate ? _latestUpdate!.versionWithoutPrefix : '';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Version $_version'),
        content: Text(
          hasUpdate
              ? 'Update available: v$updateVersion'
              : 'You are up to date',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (hasUpdate)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (_latestUpdate != null) _openReleasePage();
              },
              child: Text('Update'),
            ),
        ],
      ),
    );
  }

  /// The Appearance "Theme color" tile shows the current accent as a swatch
  /// and opens a bottom sheet of presets. Persisted via the controller.
  Widget _buildThemeColorTile() {
    final theme = Theme.of(context);
    final current = widget.controller.themeColor;
    return DpadFocusable(
      debugLabel: 'Theme Color',
      onSelect: _openThemeColorSheet,
      child: GestureDetector(
        onTap: _openThemeColorSheet,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 10, backgroundColor: current.seedColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text('Theme color', style: theme.textTheme.bodyLarge),
              ),
              Text(
                current.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens a bottom sheet listing the preset theme colors. Each option is a
  /// D-pad focusable row so TV users can select with the remote; the current
  /// selection is marked so the change is obvious.
  Future<void> _openThemeColorSheet() async {
    final current = widget.controller.themeColor;
    final selected = await showModalBottomSheet<ThemeColor>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Theme color',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              for (final color in ThemeColor.values)
                DpadFocusable(
                  debugLabel: 'Theme Color ${color.label}',
                  onSelect: () => Navigator.of(sheetContext).pop(color),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 10,
                      backgroundColor: color.seedColor,
                    ),
                    title: Text(color.label),
                    trailing: color == current ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.of(sheetContext).pop(color),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) {
      await widget.controller.setThemeColor(selected);
    }
  }

  Future<void> _handleBackup() async {
    // The dialog confirms the result inline (showing the written file path), so
    // there is no transient SnackBar to miss.
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => BackupDialog(controller: widget.controller),
    );
  }

  Future<void> _handleRestore() async {
    // The dialog previews the detected restore file (path + counts, copyable)
    // and confirms the result inline instead of a SnackBar.
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => RestoreDialog(controller: widget.controller),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String debugLabel,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onSelect,
  }) {
    final theme = Theme.of(context);
    return DpadFocusable(
      debugLabel: debugLabel,
      onSelect: onSelect,
      child: GestureDetector(
        // DpadFocusable only fires onSelect via D-pad keys; add a tap handler
        // so the tile also works with touch/click.
        onTap: onSelect,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: subtitle == null
                    ? Text(title, style: theme.textTheme.bodyLarge)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: theme.textTheme.bodyLarge),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[
      Text(
        'Settings',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 24),
      _buildSectionHeader('Library'),
      _buildActionTile(
        context: context,
        debugLabel: 'Backup Library',
        icon: Icons.save,
        title: 'Backup',
        subtitle: 'Back up your library and playlists to a file',
        onSelect: _handleBackup,
      ),
      const SizedBox(height: 8),
      _buildActionTile(
        context: context,
        debugLabel: 'Restore Library',
        icon: Icons.upload_file,
        title: 'Restore',
        subtitle: 'Restore your library and playlists from a backup file',
        onSelect: _handleRestore,
      ),
      _buildSectionHeader('Appearance'),
      const SizedBox(height: 8),
      _buildThemeColorTile(),
      if (Platform.isAndroid) ...[
        _buildSectionHeader('Playback'),
        const SizedBox(height: 8),
        _BatteryOptimizationTile(),
      ],
      _buildSectionHeader('About'),
      const SizedBox(height: 8),
      _buildVersionTile(),
      const SizedBox(height: 8),
      _buildActionTile(
        context: context,
        debugLabel: 'License',
        icon: Icons.gavel,
        title: 'GPL-3.0',
        onSelect: _openLicenseFile,
      ),
      const SizedBox(height: 8),
      _buildActionTile(
        context: context,
        debugLabel: 'View on Github',
        icon: Icons.code,
        title: 'View on Github',
        onSelect: _openRepository,
      ),
      const SizedBox(height: 8),
      Text(
        '© ${DateTime.now().year} altune · Built with Flutter · Not affiliated with any music streaming service.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ];

    final body = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );

    if (widget.showScaffold) {
      return Scaffold(
        appBar: widget.showBackButton
            ? AppBar(
                leading: DpadIconButton(
                  debugLabel: 'Settings Back',
                  onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.chevron_left),
                ),
                title: const Text('Settings'),
              )
            : null,
        body: body,
      );
    }

    return body;
  }
}

class _BatteryOptimizationTile extends StatefulWidget {
  @override
  State<_BatteryOptimizationTile> createState() =>
      _BatteryOptimizationTileState();
}

class _BatteryOptimizationTileState extends State<_BatteryOptimizationTile>
    with WidgetsBindingObserver {
  static final _channel = BatteryOptimizationService();
  bool? _isExempted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    final exempted = await _channel.isExempted();
    if (mounted) setState(() => _isExempted = exempted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DpadFocusable(
      debugLabel: 'Battery Optimization',
      onSelect: () {
        _channel.openSettings();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.battery_std, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Disable Battery Optimization',
                    style: theme.textTheme.bodyLarge,
                  ),
                  Text(
                    _buildStatusText(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  String _buildStatusText() {
    if (_isExempted == null) return 'Checking…';
    return _isExempted!
        ? 'Battery optimization is disabled'
        : 'Prevent playback from stopping in background';
  }
}
