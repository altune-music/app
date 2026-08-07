import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_update.dart';
import '../utils/app_constants.dart';
import 'log_service.dart';

/// Checks for app updates by querying the GitHub Releases API.
///
/// Compares the current installed version against the latest release tag.
/// Returns an [AppUpdate] when a newer version is available, or `null`
/// when the app is up to date or the check fails.
///
/// An optional [client] can be injected for testing to avoid real
/// network calls. When null, a default [http.Client] is used.
///
/// An optional [testVersion] can be provided to override the version
/// reported by [PackageInfo.fromPlatform] during testing.
class UpdateService {
  UpdateService({this.client, this.testVersion});

  static const String _apiBase = 'https://api.github.com';

  /// Optional HTTP client override for testing.
  final http.Client? client;

  /// Optional version override for testing.
  final String? testVersion;

  /// Fetches the latest release from GitHub and checks if it is newer
  /// than the currently installed version.
  ///
  /// Returns [AppUpdate] when a newer release exists, `null` when the
  /// app is up to date, and throws on network or parse errors.
  Future<AppUpdate?> checkForUpdates() async {
    try {
      final currentVersion = await _getCurrentVersion();
      final latestRelease = await _fetchLatestRelease();

      if (_isNewerVersion(latestRelease.versionWithoutPrefix, currentVersion)) {
        LogService().debug(
          'Update available: ${latestRelease.versionWithoutPrefix} '
          '(current: $currentVersion)',
          tag: 'UpdateService',
        );
        return latestRelease;
      }

      LogService().debug(
        'App is up to date (current: $currentVersion)',
        tag: 'UpdateService',
      );
      return null;
    } on Exception catch (e) {
      LogService().error('Update check failed', error: e, tag: 'UpdateService');
      rethrow;
    }
  }

  /// Opens the release page in the system browser.
  ///
  /// Swallows launch failures (unsupported platform, missing handler) so a
  /// cosmetic link never crashes the app.
  Future<void> openReleasePage(AppUpdate update) async {
    final uri = Uri.parse(update.htmlUrl);
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception catch (e) {
      LogService().debug('launchUrl failed: $e', tag: 'UpdateService');
    }
    if (!launched) {
      LogService().error(
        'Could not open release page: ${update.htmlUrl}',
        tag: 'UpdateService',
      );
    }
  }

  /// Retrieves the current app version string from package info.
  Future<String> _getCurrentVersion() async {
    if (testVersion != null) return testVersion!;
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// Fetches the latest release metadata from the GitHub API.
  Future<AppUpdate> _fetchLatestRelease() async {
    // Derive the owner/repo API path from the canonical repository URL so the
    // repo identity lives in AppConstants, not as a duplicate magic string.
    final segments = Uri.parse(
      AppConstants.appGitHubRepositoryUrl,
    ).pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) {
      throw Exception(
        'Invalid repository URL: '
        '${AppConstants.appGitHubRepositoryUrl}',
      );
    }
    final owner = segments[segments.length - 2];
    final repo = segments.last;

    final url = Uri.parse('$_apiBase/repos/$owner/$repo/releases/latest');
    final response = await _httpClient().get(
      url,
      headers: {'Accept': 'application/vnd.github+json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'GitHub API returned ${response.statusCode}: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return AppUpdate(
      version: json['tag_name'] as String,
      name: json['name'] as String,
      body: json['body'] as String? ?? '',
      htmlUrl: json['html_url'] as String,
    );
  }

  http.Client _httpClient() => client ?? http.Client();

  /// Returns `true` when [candidate] is a semantically newer version
  /// than [current].
  ///
  /// Compares major.minor.patch segments numerically. A candidate with
  /// more segments or a higher number in the first differing segment is
  /// considered newer. Pre-release suffixes are ignored for comparison.
  bool _isNewerVersion(String candidate, String current) {
    final candidateParts = _parseVersion(candidate);
    final currentParts = _parseVersion(current);

    for (var i = 0; i < candidateParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (candidateParts[i] > currentParts[i]) return true;
      if (candidateParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  /// Splits a version string into numeric segments, ignoring any
  /// non-numeric suffix (e.g. "-beta", "+build").
  List<int> _parseVersion(String version) {
    var stripped = version.split('-').first.split('+').first;
    if (stripped.startsWith('v')) {
      stripped = stripped.substring(1);
    }
    return stripped.split('.').map((s) {
      try {
        return int.parse(s);
      } on FormatException {
        return 0;
      }
    }).toList();
  }
}
